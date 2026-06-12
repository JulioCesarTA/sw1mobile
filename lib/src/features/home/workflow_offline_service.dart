import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_config.dart';

class WorkflowOfflineService {
  static const _cacheKey = 'cache_wf_model_v1';
  static const _modelPath = '/workflow-ai/static/models/workflow_matcher/model.json';

  static final WorkflowOfflineService _instance = WorkflowOfflineService._();
  factory WorkflowOfflineService() => _instance;
  WorkflowOfflineService._();

  List<_WfEntry> _workflows = [];
  bool get isReady => _workflows.isNotEmpty;

  /// Call when online — downloads fresh model.json and caches it.
  Future<void> sync(String accessToken) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$_modelPath');
      final res = await http
          .get(uri, headers: {'Authorization': 'Bearer $accessToken'})
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, res.body);
        _parse(res.body);
      }
    } catch (_) {
      await _loadCache();
    }
  }

  /// Call before using [analyze] — loads from cache if not already loaded.
  Future<void> ensureLoaded() async {
    if (isReady) return;
    await _loadCache();
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw != null) _parse(raw);
  }

  void _parse(String json) {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final wfList = data['workflows'] as List? ?? [];
      _workflows = wfList
          .whereType<Map<String, dynamic>>()
          .map(_WfEntry.fromJson)
          .toList();
    } catch (_) {
      _workflows = [];
    }
  }

  /// Runs offline TF-style inference:
  ///   score = 0.35 * textSimilarity + 0.65 * fieldCoverage
  /// Same formula as the Python backend.
  List<Map<String, dynamic>> analyze(String userText, List<String> docTexts) {
    if (!isReady) return [];

    final allCheckTexts = [...docTexts, if (userText.trim().isNotEmpty) userText];
    final normalizedQuery = _normalize('$userText ${docTexts.join(' ')}');

    final results = <Map<String, dynamic>>[];

    for (final wf in _workflows) {
      final cos = _jaccard(normalizedQuery, wf.text);

      final presentReq =
          wf.required.where((f) => _fieldCovered(f, allCheckTexts)).toList();
      final missingReq =
          wf.required.where((f) => !presentReq.contains(f)).toList();
      final presentOpt =
          wf.optional.where((f) => _fieldCovered(f, allCheckTexts)).toList();

      final docsComplete = missingReq.isEmpty && wf.required.isNotEmpty;
      final docScore = wf.required.isEmpty
          ? 0.0
          : presentReq.length / wf.required.length;

      var total = wf.required.isEmpty
          ? max(0.0, cos)
          : 0.35 * max(0.0, cos) + 0.65 * docScore;
      if (docsComplete) total = 1.0;

      results.add({
        'workflowId': wf.id,
        'workflowName': wf.name,
        'workflowDescription': wf.description,
        'score': double.parse((total * 100).toStringAsFixed(1)),
        'cosSim': double.parse((max(0.0, cos) * 100).toStringAsFixed(1)),
        'confidence': total >= 0.70
            ? 'Alta'
            : total >= 0.40
                ? 'Media'
                : 'Baja',
        'requiredDocs': wf.required,
        'optionalDocs': wf.optional,
        'presentRequired': presentReq,
        'missingRequired': missingReq,
        'presentOptional': presentOpt,
        'docsComplete': docsComplete,
      });
    }

    results.sort((a, b) =>
        (b['score'] as double).compareTo(a['score'] as double));
    return results.take(3).toList();
  }

  // ── Text helpers ────────────────────────────────────────────────────────────

  String _normalize(String text) {
    var t = text.toLowerCase();
    const map = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ñ': 'n'};
    for (final e in map.entries) t = t.replaceAll(e.key, e.value);
    t = t.replaceAll('_', ' ');
    t = t.replaceAll(RegExp(r'[^\w\s]'), ' ');
    return t;
  }

  Set<String> _words(String normalized) =>
      normalized.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();

  /// Jaccard similarity — replaces TF cosine (same 35% weight in final score).
  double _jaccard(String queryNorm, String wfNorm) {
    final q = _words(queryNorm);
    final w = _words(wfNorm);
    if (q.isEmpty || w.isEmpty) return 0.0;
    final inter = q.intersection(w).length;
    final union = q.union(w).length;
    return inter / union;
  }

  bool _fieldCovered(String field, List<String> texts) {
    final fieldNorm = _normalize(field);
    final fieldWords =
        fieldNorm.split(RegExp(r'\s+')).where((w) => w.length > 3).toList();

    if (fieldWords.isEmpty) {
      return texts.any((t) => _normalize(t).contains(fieldNorm));
    }

    final needed = max(1, fieldWords.length ~/ 2);

    for (final text in texts) {
      if (text.trim().isEmpty) continue;
      final normText = _normalize(text);
      final docWords =
          normText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      int matched = 0;
      for (final fw in fieldWords) {
        if (normText.contains(fw) || _fuzzyMatch(fw, docWords)) {
          matched++;
        }
      }
      if (matched >= needed) return true;
    }
    return false;
  }

  bool _fuzzyMatch(String fw, List<String> docWords) {
    if (fw.length <= 3) return docWords.contains(fw);
    for (final dw in docWords) {
      if ((fw.length - dw.length).abs() > 3) continue;
      if (_editRatio(fw, dw) >= 0.82) return true;
    }
    return false;
  }

  /// Levenshtein-based similarity ratio (mirrors Python SequenceMatcher).
  double _editRatio(String a, String b) {
    final m = a.length, n = b.length;
    if (m == 0 || n == 0) return 0.0;
    var row = List<int>.generate(n + 1, (i) => i);
    for (int i = 1; i <= m; i++) {
      var prev = i;
      for (int j = 1; j <= n; j++) {
        final val = a[i - 1] == b[j - 1]
            ? row[j - 1]
            : min(min(row[j] + 1, prev + 1), row[j - 1] + 1);
        row[j - 1] = prev;
        prev = val;
      }
      row[n] = prev;
    }
    return 1.0 - row[n] / max(m, n);
  }
}

class _WfEntry {
  const _WfEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.text,
    required this.required,
    required this.optional,
  });

  final String id;
  final String name;
  final String description;
  final String text;
  final List<String> required;
  final List<String> optional;

  factory _WfEntry.fromJson(Map<String, dynamic> j) => _WfEntry(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        text: j['text']?.toString() ?? '',
        required:
            (j['required'] as List? ?? []).map((e) => e.toString()).toList(),
        optional:
            (j['optional'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}
