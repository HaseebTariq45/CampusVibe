import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _universityController = TextEditingController();
  final _departmentController = TextEditingController();
  final _yearController = TextEditingController();
  bool _isLoading = false;
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'University Email'),
              validator: (value) => !value!.contains('@') ? 'Invalid email' : null,
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextFormField(
              controller: _universityController,
              decoration: const InputDecoration(labelText: 'University'),
            ),
            TextFormField(
              controller: _departmentController,
              decoration: const InputDecoration(labelText: 'Department'),
            ),
            TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(labelText: 'Year'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = await _authService.registerWithEmail(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
        _universityController.text,
        _departmentController.text,
        int.parse(_yearController.text),
      );

      if (user != null && mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _universityController.dispose();
    _departmentController.dispose();
    _yearController.dispose();
    super.dispose();
  }
}
