import 'package:flutter/material.dart';

import '../data/delivery_models.dart';
import '../data/delivery_service.dart';

class DeliveryStoresPage extends StatefulWidget {
  const DeliveryStoresPage({super.key});

  @override
  State<DeliveryStoresPage> createState() => _DeliveryStoresPageState();
}

class _DeliveryStoresPageState extends State<DeliveryStoresPage> {
  final _deliveryService = DeliveryService();

  bool _loading = true;
  String? _error;
  List<DeliveryStore> _stores = [];

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stores = await _deliveryService.getAssignedStores();
      if (!mounted) return;
      setState(() => _stores = stores);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar tus tiendas asignadas.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiendas asignadas'),
        actions: [
          IconButton(
            onPressed: _loadStores,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStores,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _MessageList(
        icon: Icons.storefront_outlined,
        message: _error!,
        action: FilledButton(
          onPressed: _loadStores,
          child: const Text('Reintentar'),
        ),
      );
    }

    if (_stores.isEmpty) {
      return const _MessageList(
        icon: Icons.storefront_outlined,
        message: 'No tienes tiendas asignadas por el momento.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _stores.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final store = _stores[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                if ((store.businessType ?? '').isNotEmpty)
                  _InfoRow(
                    icon: Icons.category_outlined,
                    text: store.businessType!,
                  ),
                if ((store.phone ?? '').isNotEmpty)
                  _InfoRow(icon: Icons.phone_outlined, text: store.phone!),
                if ((store.email ?? '').isNotEmpty)
                  _InfoRow(icon: Icons.mail_outline, text: store.email!),
                _InfoRow(
                  icon: Icons.verified_outlined,
                  text: 'Estado: ${store.status}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 96),
        Icon(icon, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (action != null) ...[
          const SizedBox(height: 16),
          action!,
        ],
      ],
    );
  }
}
