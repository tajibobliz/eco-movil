import 'package:flutter/material.dart';

import '../../../core/config/app_routes.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 76,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Bienvenido a EcomSaaS',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Un espacio para clientes que quieren seguir sus pedidos y guardar tiendas visitadas, y para deliverys que reciben pedidos confirmados y pagados para llevarlos a sus clientes.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 30),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.customerLogin);
                    },
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Ingresar como cliente'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.deliveryLogin);
                    },
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('Ingresar como delivery'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.customerRegister,
                      );
                    },
                    child: const Text('Crear cuenta cliente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
