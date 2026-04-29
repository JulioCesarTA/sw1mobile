import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/models.dart';
import '../home_repository.dart';
import 'tramite_detail_page.dart';

class TramitesPage extends StatefulWidget {
  const TramitesPage({super.key, required this.session});

  final UserSession session;

  @override
  State<TramitesPage> createState() => _TramitesPageState();
}

class _TramitesPageState extends State<TramitesPage> {
  final HomeRepository _repository = HomeRepository();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<TramiteItem>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchTramites(widget.session.accessToken);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _repository.fetchTramites(widget.session.accessToken);
    });
    await _future;
  }

  void _openDetail(String tramiteId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TramiteDetailPage(
          tramiteId: tramiteId,
          accessToken: widget.session.accessToken,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TramiteItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final message = snapshot.error is ApiException
              ? (snapshot.error as ApiException).message
              : 'No se pudieron cargar los tramites.';
          return _TramitesError(message: message, onRetry: _reload);
        }

        final items = snapshot.data ?? const <TramiteItem>[];
        final filtered = items.where((item) {
          final haystack = [
            item.code,
            item.title,
            item.clientName,
            item.status,
          ].join(' ').toLowerCase();
          return haystack.contains(_query.toLowerCase());
        }).toList();

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Mis trámites',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              const Text('Seguimiento de tus trámites en tiempo real.'),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar por codigo, titulo, cliente o estado',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _query = value.trim();
                  });
                },
              ),
              const SizedBox(height: 20),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('No hay tramites para mostrar con el filtro actual.'),
                )
              else
                ...filtered.map(
                  (item) => _TramiteCard(
                    item: item,
                    onViewDetail: () => _openDetail(item.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TramiteCard extends StatelessWidget {
  const _TramiteCard({required this.item, required this.onViewDetail});

  final TramiteItem item;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.code.isEmpty ? '-' : item.code,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ),
                _StatusChip(status: item.status),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onViewDetail,
                  icon: const Icon(Icons.visibility_outlined),
                  tooltip: 'Ver detalle',
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
            if (item.title.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.title, style: theme.textTheme.bodyMedium),
            ],
            if (item.clientName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Cliente: ${item.clientName}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Actualizado: ${_formatDate(item.updatedAt ?? item.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

class _TramitesError extends StatelessWidget {
  const _TramitesError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
