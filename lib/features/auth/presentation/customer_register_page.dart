import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_routes.dart';
import '../data/auth_service.dart';

class CustomerRegisterPage extends StatefulWidget {
  const CustomerRegisterPage({super.key});

  @override
  State<CustomerRegisterPage> createState() => _CustomerRegisterPageState();
}

class _CustomerRegisterPageState extends State<CustomerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;

    setState(() => _loading = true);

    try {
      final user = await _authService.registerCustomer({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
      });

      if (!mounted) return;

      if (!user.isCustomer) {
        await _authService.logout();
        _showError('La cuenta creada no es de cliente.');
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.store,
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      _showError(_readError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _readError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
      if (data != null) return data.toString();
    }

    return 'No se pudo crear la cuenta.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.person_add_alt_1_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Registro cliente',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crea tu cuenta para comprar en la tienda.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
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
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electronico',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Ingresa tu correo.';
                        if (!text.contains('@')) return 'Correo invalido.';
                        return null;
                      },
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contrasena',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 8) {
                          return 'Usa al menos 8 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Crear cuenta'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Ya tengo cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
