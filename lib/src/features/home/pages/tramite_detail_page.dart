import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/models.dart';
import '../home_repository.dart';

class TramiteDetailPage extends StatefulWidget {
  const TramiteDetailPage({
    super.key,
    required this.tramiteId,
    required this.accessToken,
  });

  final String tramiteId;
  final String accessToken;

  @override
  State<TramiteDetailPage> createState() => _TramiteDetailPageState();
}

class _TramiteDetailPageState extends State<TramiteDetailPage> {
  late Future<TramiteDetail> _future;
  final _repository = HomeRepository();

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchTramiteDetail(
      widget.tramiteId,
      widget.accessToken,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del trámite'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<TramiteDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'No se pudo cargar el trámite.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(message, textAlign: TextAlign.center),
              ),
            );
          }

          final detail = snapshot.data!;
          return _TramiteDetailContent(detail: detail);
        },
      ),
    );
  }
}

class _TramiteDetailContent extends StatelessWidget {
  const _TramiteDetailContent({required this.detail});

  final TramiteDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        detail.code,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                    ),
                    _StatusChip(status: detail.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(detail.title, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Recorrido del trámite',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (detail.history.isEmpty)
          const Text('Sin historial disponible.')
        else
          _HistoryTimeline(entries: detail.history),
      ],
    );
  }
}

class _HistoryTimeline extends StatelessWidget {
  const _HistoryTimeline({required this.entries});

  final List<HistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _TimelineRow(
            entry: entries[i],
            isLast: i == entries.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.isLast});

  final HistoryEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrent = entry.isCurrent;
    final dotColor = isCurrent
        ? const Color(0xFF0F766E)
        : entry.action == 'RECHAZADO' || entry.action == 'DECISION_RECHAZADA'
            ? const Color(0xFFB91C1C)
            : Colors.grey.shade400;

    final stageName =
        entry.stageName.isNotEmpty ? entry.stageName : _actionLabel(entry.action);
    final subtitle = _buildSubtitle(entry);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: isCurrent
                        ? Border.all(color: const Color(0xFF0F766E), width: 2)
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stageName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isCurrent ? const Color(0xFF0F766E) : null,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'ACTUAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                  if (entry.comment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.comment,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                  if (entry.changedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(entry.changedAt!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(HistoryEntry entry) {
    final parts = <String>[];
    if (entry.departmentName.isNotEmpty) parts.add(entry.departmentName);
    if (entry.jobRoleName.isNotEmpty) parts.add(entry.jobRoleName);
    return parts.join(' · ');
  }

  String _actionLabel(String action) {
    return switch (action) {
      'CREADO' => 'Trámite creado',
      'AVANZADO' => 'Avanzado',
      'RECHAZADO' => 'Rechazado',
      'DECISION_RECHAZADA' => 'Decisión rechazada',
      'LOOP_APROBADO' => 'Iteración aprobada',
      'LOOP_RECHAZADO' => 'Devuelto a revisión',
      'BIFURCACION' => 'Rama paralela',
      'UNION_COMPLETADA' => 'Ramas unificadas',
      _ => action,
    };
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${pad(local.day)}/${pad(local.month)}/${local.year} ${pad(local.hour)}:${pad(local.minute)}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final estado = status.toUpperCase();
    final color = switch (estado) {
      'COMPLETADO' => const Color(0xFF166534),
      'RECHAZADO' => const Color(0xFFB91C1C),
      'EN_PROGRESO' => const Color(0xFF0F766E),
      'PENDIENTE' => const Color(0xFF475569),
      _ => const Color(0xFF475569),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
