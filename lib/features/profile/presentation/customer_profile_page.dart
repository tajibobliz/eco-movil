import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/storage/user_storage.dart';
import '../../cart/state/cart_provider.dart';
import '../data/profile_service.dart';

class CustomerProfilePage extends ConsumerStatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  ConsumerState<CustomerProfilePage> createState() =>
      _CustomerProfilePageState();
}

class _CustomerProfilePageState extends ConsumerState<CustomerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final _tokenStorage = TokenStorage();
  final _userStorage = UserStorage();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final hasToken = await _tokenStorage.hasAccessToken();
    if (!hasToken) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.customerLogin);
      return;
    }

    try {
      final user = await _profileService.getProfile();
      if (!mounted) return;
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
    } catch (error) {
      if (!mounted) return;
      if (error is DioException &&
          (error.response?.statusCode == 401 ||
              error.response?.statusCode == 403)) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.customerLogin);
        return;
      }

      setState(() {
        _error = 'No se pudo cargar tu perfil.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _saving) return;

    setState(() => _saving = true);

    try {
      await _profileService.updateProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readError(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await _tokenStorage.clear();
    await _userStorage.clear();
    await ref.read(cartProvider.notifier).clear();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.store,
      (_) => false,
    );
  }

  String _readError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data != null) return data.toString();
    }

    return 'No se pudieron guardar los cambios.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
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
          const Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
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

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(
          Icons.account_circle_outlined,
          size: 78,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 14),
        Text(
          'Datos de cliente',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) {
                  return (value?.trim().isEmpty ?? true)
                      ? 'Ingresa tu nombre.'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) {
                  return (value?.trim().isEmpty ?? true)
                      ? 'Ingresa tu apellido.'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Correo electronico',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _saveProfile,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesion'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
