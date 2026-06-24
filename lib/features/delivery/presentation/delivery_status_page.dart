import 'package:flutter/material.dart';

import '../data/delivery_models.dart';
import '../data/delivery_service.dart';

class DeliveryStatusPage extends StatefulWidget {
  const DeliveryStatusPage({super.key});

  @override
  State<DeliveryStatusPage> createState() => _DeliveryStatusPageState();
}

class _DeliveryStatusPageState extends State<DeliveryStatusPage> {
  final _deliveryService = DeliveryService();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  DeliveryProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await _deliveryService.getProfile();
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo cargar tu estado de delivery.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeStatus(String status) async {
    if (_saving) return;

    setState(() => _saving = true);
    try {
      final profile = await _deliveryService.updateStatus(
        operationalStatus: status,
      );
      if (!mounted) return;
      setState(() => _profile = profile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar tu estado.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado del delivery'),
        actions: [
          IconButton(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 96),
          const Icon(Icons.toggle_off_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadProfile,
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    final profile = _profile;
    if (profile == null) {
      return const Center(child: Text('No hay perfil delivery disponible.'));
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.isEmpty ? 'Delivery' : profile.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text('Estado actual: ${_labelFor(profile.operationalStatus)}'),
                const SizedBox(height: 6),
                Text(
                  profile.available ? 'Disponible: Si' : 'Disponible: No',
                ),
                if (profile.hasActiveDelivery) ...[
                  const SizedBox(height: 6),
                  const Text('Tienes una entrega activa asignada.'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _StatusButton(
          title: 'Disponible',
          subtitle: 'Estoy libre para recibir pedidos.',
          icon: Icons.check_circle_outline,
          selected: profile.operationalStatus == 'libre',
          loading: _saving,
          onPressed: () => _changeStatus('libre'),
        ),
        _StatusButton(
          title: 'En camino a una entrega',
          subtitle: 'Estoy ocupado entregando un pedido.',
          icon: Icons.route_outlined,
          selected: profile.operationalStatus == 'ocupado',
          loading: _saving,
          onPressed: () => _changeStatus('ocupado'),
        ),
        _StatusButton(
          title: 'Inactivo',
          subtitle: 'No estoy disponible temporalmente.',
          icon: Icons.pause_circle_outline,
          selected: profile.operationalStatus == 'inactivo',
          loading: _saving,
          onPressed: () => _changeStatus('inactivo'),
        ),
        _StatusButton(
          title: 'Desconectado',
          subtitle: 'Termine mi jornada o sali de turno.',
          icon: Icons.power_settings_new,
          selected: profile.operationalStatus == 'desconectado',
          loading: _saving,
          onPressed: () => _changeStatus('desconectado'),
        ),
      ],
    );
  }

  String _labelFor(String value) {
    switch (value) {
      case 'libre':
        return 'Disponible';
      case 'ocupado':
        return 'En camino / ocupado';
      case 'inactivo':
        return 'Inactivo';
      case 'desconectado':
        return 'Desconectado';
      default:
        return value.isEmpty ? 'Sin estado' : value;
    }
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.loading,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          selected ? Icons.radio_button_checked : icon,
          color: selected ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: selected ? const Text('Actual') : null,
        enabled: !loading,
        onTap: selected || loading ? null : onPressed,
      ),
    );
  }
}
