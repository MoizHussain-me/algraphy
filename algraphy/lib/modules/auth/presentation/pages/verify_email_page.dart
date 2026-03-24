import 'package:flutter/material.dart';
import 'package:algraphy/modules/auth/data/auth_repository.dart';
import '../../../../config/di/injector.dart';
import '../../../../core/services/logger_service.dart';

class VerifyEmailPage extends StatefulWidget {
  final String token;
  const VerifyEmailPage({super.key, required this.token});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isVerified = false;
  String? _errorMessage;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  Future<void> _verifyToken() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = getIt<AuthRepository>();
      final result = await repo.verifyEmail(widget.token);
      setState(() {
        _isVerified = true;
        _userEmail = result['email'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      logger.e("AUTH: Token verification failed: $e");
    }
  }

  Future<void> _submitPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = getIt<AuthRepository>();
      await repo.setupInitialPassword(widget.token, _newPassCtrl.text.trim());
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password set successfully! Please login.")),
      );
      
      // Redirect to login
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Account Verification"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _isLoading && !_isVerified
              ? const CircularProgressIndicator(color: Color(0xFFDC2726))
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null && !_isVerified) {
      return Column(
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 24),
          Text(
            "Invalid or Expired Link",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text("Back to Login"),
          )
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user_outlined, size: 80, color: Color(0xFFDC2726)),
          const SizedBox(height: 24),
          const Text(
            "Welcome to Algraphy!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            "Setting up account for: ${_userEmail ?? ''}",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          
          TextFormField(
            controller: _newPassCtrl,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration("Create Password"),
            validator: (val) {
              if (val == null || val.length < 6) return "Min 6 characters";
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _confirmPassCtrl,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration("Confirm Password"),
            validator: (val) {
              if (val != _newPassCtrl.text) return "Passwords do not match";
              return null;
            },
          ),
          const SizedBox(height: 32),

          if (_errorMessage != null)
             Padding(
               padding: const EdgeInsets.only(bottom: 16),
               child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
             ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2726),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _submitPassword,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("Verify & Set Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1C1C1C),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
