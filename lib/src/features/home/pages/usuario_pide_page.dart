import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/api_config.dart';
import '../../../core/models.dart';

class UsuarioPidePage extends StatefulWidget {
  const UsuarioPidePage({super.key, required this.session});
  final UserSession session;

  @override
  State<UsuarioPidePage> createState() => _UsuarioPidePageState();
}

class _UsuarioPidePageState extends State<UsuarioPidePage> {
  final _textController = TextEditingController();
  final List<PlatformFile> _files = [];

  bool _loading = false;
  String _error = '';
  List<_AnalyzedDoc> _analyzedDocs = [];
  List<_WorkflowMatch> _matches = [];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        if (!_files.any((e) => e.name == f.name)) {
          _files.add(f);
        }
      }
    });
  }

  void _removeFile(int i) => setState(() => _files.removeAt(i));

  Future<void> _analyze() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _files.isEmpty) return;

    setState(() {
      _loading = true;
      _error = '';
      _analyzedDocs = [];
      _matches = [];
    });

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/workflow-ai/match-with-docs');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer ${widget.session.accessToken}'
        ..fields['text'] = text;

      for (final f in _files) {
        if (f.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'files',
            f.bytes!,
            filename: f.name,
          ));
        }
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        final msg = _extractError(body, streamed.statusCode);
        setState(() { _error = msg; _loading = false; });
        return;
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      setState(() {
        _analyzedDocs = ((json['documents'] as List?) ?? [])
            .cast<Map<String, dynamic>>()
            .map(_AnalyzedDoc.fromJson)
            .toList();
        _matches = ((json['matches'] as List?) ?? [])
            .cast<Map<String, dynamic>>()
            .map(_WorkflowMatch.fromJson)
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar al servidor. Verifica tu conexión.';
        _loading = false;
      });
    }
  }

  String _extractError(String body, int code) {
    try {
      final j = jsonDecode(body);
      if (j is Map) return j['detail']?.toString() ?? j['message']?.toString() ?? 'Error $code';
    } catch (_) {}
    return 'Error $code';
  }

  void _iniciarTramite(_WorkflowMatch m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Workflow seleccionado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.workflowName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            if (m.workflowDescription.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(m.workflowDescription, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Text('Compatibilidad: ${m.score.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            if (m.missingRequired.isNotEmpty) ...[
              const Text('Campos faltantes:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              ...m.missingRequired.map((f) => Row(
                    children: [
                      const Icon(Icons.cancel, color: Colors.red, size: 14),
                      const SizedBox(width: 4),
                      Text(f, style: const TextStyle(fontSize: 13)),
                    ],
                  )),
            ],
            if (m.docsComplete)
              const Row(
                children: [
                  Icon(Icons.verified, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text('Tienes todos los campos', style: TextStyle(color: Colors.green, fontSize: 13)),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildDescriptionCard(),
            const SizedBox(height: 16),
            _buildFilesCard(),
            const SizedBox(height: 16),
            _buildAnalyzeButton(),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildError(),
            ],
            if (_loading) ...[
              const SizedBox(height: 24),
              _buildLoading(),
            ],
            if (!_loading && _analyzedDocs.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildAnalyzedDocs(),
            ],
            if (!_loading && _matches.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildMatches(),
            ],
            if (!_loading && _matches.isEmpty && _analyzedDocs.isEmpty && _error.isEmpty)
              _buildEmptyState(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Usuario Pide',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        SizedBox(height: 4),
        Text(
          'Describí tu problema y sube tus documentos. TensorFlow analizará el contenido y recomendará los workflows más adecuados.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mic, color: Color(0xFF6366F1), size: 18),
              SizedBox(width: 6),
              Text('Describí tu problema',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ej: Necesito reconectar el servicio de agua, tengo la factura y mi DNI',
              hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.upload_file, color: Color(0xFF10B981), size: 18),
              SizedBox(width: 6),
              Text('Sube tus documentos',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Formatos aceptados: PDF, Word (.docx), TXT',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickFiles,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5,
                    style: BorderStyle.solid),
              ),
              child: const Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 36, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 8),
                  Text('Toca para seleccionar archivos',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                  Text('.pdf · .docx · .txt',
                      style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
                ],
              ),
            ),
          ),
          if (_files.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._files.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file, color: Color(0xFF6366F1), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.value.name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis),
                              Text('${((e.value.size) / 1024).toStringAsFixed(0)} KB',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _removeFile(e.key),
                          child: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    final canAnalyze = !_loading &&
        (_textController.text.trim().isNotEmpty || _files.isNotEmpty);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canAnalyze ? _analyze : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        icon: const Icon(Icons.psychology, size: 20),
        label: const Text('Analizar y recomendar workflow',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(_error, style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C)))),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF4F46E5)),
          SizedBox(height: 12),
          Text('Analizando con TensorFlow…',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.account_tree_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Los workflows recomendados aparecerán aquí',
                style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Describí tu problema y tocá "Analizar"',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzedDocs() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 18),
              SizedBox(width: 6),
              Text('Documentos analizados por TensorFlow',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 12),
          ..._analyzedDocs.map((doc) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: Color(0xFF6366F1), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(doc.filename,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600, fontSize: 13),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('${doc.confidence.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4338CA))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(_docTypeLabel(doc.detectedType),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.w500)),
                            if (doc.preview.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(doc.preview,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMatches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('WORKFLOWS RECOMENDADOS',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFF94A3B8))),
        const SizedBox(height: 10),
        ..._matches.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildMatchCard(e.value, e.key),
            )),
      ],
    );
  }

  Widget _buildMatchCard(_WorkflowMatch m, int index) {
    final isTop = index == 0;
    final scoreColor = m.score >= 70
        ? const Color(0xFF059669)
        : m.score >= 40
            ? const Color(0xFFD97706)
            : const Color(0xFF94A3B8);
    final barColor = m.score >= 70
        ? const Color(0xFF10B981)
        : m.score >= 40
            ? const Color(0xFFFBBF24)
            : const Color(0xFFCBD5E1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isTop ? const Color(0xFFA5B4FC) : const Color(0xFFE2E8F0),
          width: isTop ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isTop ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${index + 1}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isTop ? Colors.white : const Color(0xFF64748B))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.workflowName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B))),
                    if (m.workflowDescription.isNotEmpty)
                      Text(m.workflowDescription,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text('Similitud: ${m.cosSim.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${m.score.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: scoreColor)),
                  _ConfidenceBadge(confidence: m.confidence),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: m.score / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          if (m.requiredDocs.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Campos obligatorios del primer paso:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: m.requiredDocs
                  .map((doc) => _FieldChip(
                        label: doc,
                        present: m.presentRequired.contains(doc),
                      ))
                  .toList(),
            ),
          ],
          if (m.optionalDocs.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Opcionales:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: m.optionalDocs
                  .map((doc) => _FieldChip(
                        label: doc,
                        present: m.presentOptional.contains(doc),
                        optional: true,
                      ))
                  .toList(),
            ),
          ],
          if (m.missingRequired.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 16),
                      SizedBox(width: 6),
                      Text('Faltan estos campos obligatorios:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...m.missingRequired.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 5, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 6),
                            Text(f, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
          if (m.docsComplete) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: Color(0xFF16A34A), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Tienes todos los campos obligatorios. ¡Puedes iniciar el trámite!',
                        style: TextStyle(fontSize: 12, color: Color(0xFF15803D))),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: isTop
                ? ElevatedButton.icon(
                    onPressed: () => _iniciarTramite(m),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Iniciar trámite con este workflow',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  )
                : OutlinedButton(
                    onPressed: () => _iniciarTramite(m),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Usar este workflow', style: TextStyle(fontSize: 13)),
                  ),
          ),
        ],
      ),
    );
  }

  String _docTypeLabel(String t) {
    return t.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});
  final String confidence;

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    if (confidence == 'Alta') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
    } else if (confidence == 'Media') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(confidence, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _FieldChip extends StatelessWidget {
  const _FieldChip({required this.label, required this.present, this.optional = false});
  final String label;
  final bool present;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final Color bg, fg, border;
    final IconData icon;
    if (present) {
      bg = const Color(0xFFF0FDF4);
      fg = const Color(0xFF15803D);
      border = const Color(0xFFBBF7D0);
      icon = Icons.check_circle;
    } else if (!optional) {
      bg = const Color(0xFFFFF1F2);
      fg = const Color(0xFFB91C1C);
      border = const Color(0xFFFECACA);
      icon = Icons.cancel;
    } else {
      bg = const Color(0xFFF8FAFC);
      fg = const Color(0xFF94A3B8);
      border = const Color(0xFFE2E8F0);
      icon = Icons.description_outlined;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _AnalyzedDoc {
  const _AnalyzedDoc({
    required this.filename,
    required this.detectedType,
    required this.confidence,
    required this.preview,
  });

  final String filename;
  final String detectedType;
  final double confidence;
  final String preview;

  factory _AnalyzedDoc.fromJson(Map<String, dynamic> j) => _AnalyzedDoc(
        filename: j['filename']?.toString() ?? '',
        detectedType: j['detectedType']?.toString() ?? '',
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
        preview: j['preview']?.toString() ?? '',
      );
}

class _WorkflowMatch {
  const _WorkflowMatch({
    required this.workflowId,
    required this.workflowName,
    required this.workflowDescription,
    required this.score,
    required this.cosSim,
    required this.confidence,
    required this.requiredDocs,
    required this.optionalDocs,
    required this.presentRequired,
    required this.missingRequired,
    required this.presentOptional,
    required this.docsComplete,
  });

  final String workflowId;
  final String workflowName;
  final String workflowDescription;
  final double score;
  final double cosSim;
  final String confidence;
  final List<String> requiredDocs;
  final List<String> optionalDocs;
  final List<String> presentRequired;
  final List<String> missingRequired;
  final List<String> presentOptional;
  final bool docsComplete;

  factory _WorkflowMatch.fromJson(Map<String, dynamic> j) {
    List<String> strList(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? [];
    return _WorkflowMatch(
      workflowId: j['workflowId']?.toString() ?? '',
      workflowName: j['workflowName']?.toString() ?? '',
      workflowDescription: j['workflowDescription']?.toString() ?? '',
      score: (j['score'] as num?)?.toDouble() ?? 0,
      cosSim: (j['cosSim'] as num?)?.toDouble() ?? 0,
      confidence: j['confidence']?.toString() ?? '',
      requiredDocs: strList(j['requiredDocs']),
      optionalDocs: strList(j['optionalDocs']),
      presentRequired: strList(j['presentRequired']),
      missingRequired: strList(j['missingRequired']),
      presentOptional: strList(j['presentOptional']),
      docsComplete: j['docsComplete'] == true,
    );
  }
}
