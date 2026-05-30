import 'package:flutter/material.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _authService = AuthService();
  final _tokenStorage = TokenStorage();

  @override
  void initState() {
    super.initState();
    _resolveInitialRoute();
  }

  Future<void> _resolveInitialRoute() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final hasToken = await _tokenStorage.hasAccessToken();

    if (!mounted) return;

    if (!hasToken) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.store);
      return;
    }

    try {
      final user = await _authService.getMe();
      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        user.isCustomer ? AppRoutes.store : AppRoutes.customerLogin,
      );
    } catch (_) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.customerLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'ECO Cliente',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 18),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
