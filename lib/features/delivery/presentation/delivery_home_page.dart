import 'package:flutter/material.dart';

import '../../../core/config/app_routes.dart';
import '../../auth/data/auth_service.dart';

class DeliveryHomePage extends StatefulWidget {
  const DeliveryHomePage({super.key});

  @override
  State<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends State<DeliveryHomePage> {
  final _authService = AuthService();

  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() => _loggingOut = true);
    await _authService.logout();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard delivery'),
        actions: [
          IconButton(
            onPressed: _loggingOut ? null : _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _DeliveryActionCard(
              icon: Icons.storefront_outlined,
              title: 'Tiendas asignadas',
              description:
                  'Visualiza los datos esenciales de las tiendas que tienes asignadas para atender.',
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.deliveryStores);
              },
            ),
            _DeliveryActionCard(
              icon: Icons.assignment_outlined,
              title: 'Pedidos asignados',
              description:
                  'Revisa los pedidos confirmados y pagados que te asignaron para entregar.',
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.deliveryAssignments);
              },
            ),
            _DeliveryActionCard(
              icon: Icons.verified_outlined,
              title: 'Confirmacion de entrega',
              description:
                  'Confirma la entrega cuando completes el pedido con el cliente.',
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.deliveryConfirm);
              },
            ),
            _DeliveryActionCard(
              icon: Icons.toggle_on_outlined,
              title: 'Estado del delivery',
              description:
                  'Cambia tu disponibilidad cuando estes libre o en camino a una entrega.',
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.deliveryStatus);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryActionCard extends StatelessWidget {
  const _DeliveryActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(description),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
