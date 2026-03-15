import 'package:algraphy/modules/auth/presentation/bloc/auth_bloc.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_event.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_state.dart';
import 'package:algraphy/core/utils/constants.dart';
import 'package:algraphy/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  
  bool _isClientSignup = false;
  String _selectedIndustry = '';
  String _selectedService = '';
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();

  final List<String> _industries = ['', 'E-commerce', 'Real Estate', 'Technology', 'Food & Beverage', 'Other'];
  final List<String> _services = ['', 'Photography', 'Social Media', 'Design', 'Development', 'Other'];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Detect Theme Mode
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
          if (state is ClientSignupSuccess) {
            setState(() => _isClientSignup = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Request Submitted! Please login.'), backgroundColor: Colors.green),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // 2. Dynamic Background Gradient (Matches Profile Depth)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.8, -0.8),
                      radius: 1.5,
                      colors: isDark 
                        ? [const Color(0xFF1A0808), theme.scaffoldBackgroundColor] 
                        : [const Color(0xFFFEECEC), theme.scaffoldBackgroundColor],
                    ),
                  ),
                ),
              ),
              
              // Center(
              //   child: SingleChildScrollView(
              //     physics: const BouncingScrollPhysics(),
              //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              //     child: ConstrainedBox(
              //       constraints: const BoxConstraints(maxWidth: 400),
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.stretch,
              //         children: [
              //           _buildHeader(theme, isDark),
              //           const SizedBox(height: 40),
              //           _buildUnifiedForm(theme, isDark),
              //           const SizedBox(height: 20),
              //           _buildPrivacyFooter(theme, isDark),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),
              Center(
  child: ScrollConfiguration(
    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false), // 1. Hides the scrollbar
    child: SingleChildScrollView(
      physics: const ClampingScrollPhysics(), // 2. Prevents "bouncing" on web
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          // 3. This ensures the column doesn't try to take infinite height
          minHeight: 0, 
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 4. Critical: Only take needed space
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(theme, isDark),
            const SizedBox(height: 40),
            _buildUnifiedForm(theme, isDark),
            const SizedBox(height: 10),
            _buildPrivacyFooter(theme, isDark),
          ],
        ),
      ),
    ),
  ),
),
              if (state is AuthLoading)
                Container(
                  color: Colors.black45,
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFFDC2726))),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Hero(
          tag: 'app_logo',
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2726).withOpacity(isDark ? 0.15 : 0.08),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: 90,
              errorBuilder: (c, e, s) => Icon(Icons.lock_person, size: 70, color: isDark ? Colors.white24 : Colors.black26),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Algraphy Pro', style: theme.textTheme.displayLarge),
        const SizedBox(height: 8),
        Text(
          _isClientSignup ? 'Create your client account' : 'Sign in to your account',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildUnifiedForm(ThemeData theme, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_isClientSignup) ...[
            _buildField(_nameController, 'Full Name', Icons.person_outline, isDark),
            const SizedBox(height: 16),
            _buildField(_phoneController, 'Phone Number', Icons.phone_outlined, isDark, type: TextInputType.phone),
            const SizedBox(height: 16),
            _buildField(_companyController, 'Company Name', Icons.business_outlined, isDark),
            const SizedBox(height: 16),
            _buildDropdown(_selectedIndustry, _industries, 'Select Industry', (v) => setState(() => _selectedIndustry = v!), isDark),
            const SizedBox(height: 16),
            _buildDropdown(_selectedService, _services, 'Service Needed', (v) => setState(() => _selectedService = v!), isDark),
            const SizedBox(height: 16),
          ],
          _buildField(_emailController, 'Email Address', Icons.alternate_email, isDark, type: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildField(
            _passwordController, 
            'Password', 
            Icons.lock_outline, 
            isDark, 
            obscure: !_isPasswordVisible,
            suffix: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, size: 18),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          const SizedBox(height: 32),
          _buildSubmitButton(
            label: _isClientSignup ? 'Submit Request' : 'Sign In',
            onPressed: _handleAuthAction,
          ),
          const SizedBox(height: 20),
          _buildToggleLink(isDark),
        ],
      ),
    );
  }

  // --- REUSABLE DYNAMIC COMPONENTS ---

  Widget _buildField(TextEditingController controller, String label, IconData icon, bool isDark, {bool obscure = false, TextInputType? type, Widget? suffix}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
      decoration: _inputDecoration(label, icon, isDark).copyWith(suffixIcon: suffix),
      validator: (v) => v!.isEmpty ? 'Field required' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      filled: true,
      fillColor: isDark ? const Color(0xFF161616) : Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDC2726), width: 1.5),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, String hint, Function(String?) onChanged, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          hint: Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          items: items.skip(1).map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSubmitButton({required String label, required VoidCallback onPressed}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFFDC2726), Color(0xFFB01D1C)]),
        boxShadow: [
          BoxShadow(color: const Color(0xFFDC2726).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildToggleLink(bool isDark) {
    return TextButton(
      onPressed: () => setState(() => _isClientSignup = !_isClientSignup),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          children: [
            TextSpan(text: _isClientSignup ? 'Already a Client? ' : 'New to Algraphy Pro? '),
            const TextSpan(text: 'Click here', style: TextStyle(color: Color(0xFFDC2726), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyFooter(ThemeData theme, bool isDark) {
    return Column(
      children: [
        const Text('By continuing, you agree to our', style: TextStyle(color: Colors.grey, fontSize: 11)),
        GestureDetector(
          onTap: () => launchUrl(Uri.parse(AppConstants.privacyPolicyUrl)),
          child: Text('Privacy Policy', style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFFDC2726), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _handleAuthAction() {
    if (_formKey.currentState!.validate()) {
      if (_isClientSignup) {
        context.read<AuthBloc>().add(ClientSignupRequested(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text,
          companyName: _companyController.text,
          industry: _selectedIndustry,
          servicesNeeded: _selectedService,
        ));
      } else {
        context.read<AuthBloc>().add(LoginRequested(_emailController.text.trim(), _passwordController.text));
      }
    }
  }
}