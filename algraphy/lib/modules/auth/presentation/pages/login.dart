import 'package:algraphy/modules/auth/presentation/bloc/auth_event.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_state.dart';
import 'package:algraphy/core/utils/constants.dart';
import 'package:algraphy/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Unified Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Client Signup Specific
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  
  bool _isClientSignup = false;
  String _selectedIndustry = '';
  String _selectedService = '';

  final List<String> _industries = [
    '', 'E-commerce', 'Real Estate', 'Technology / Software', 'Food & Beverage', 'Fashion & Apparel', 'Healthcare', 'Education', 'Media & Entertainment', 'Other'
  ];

  final List<String> _services = [
    '', 'Photography & Videography', 'Social Media Management', 'Brand Identity & Design', 'Web & App Development', 'Advertising & Media Buying', 'Talent Casting & Influencer Marketing', 'Other'
  ];

  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

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
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
          if (state is ClientSignupSuccess) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration Request Submitted Successfully! Please login.'), 
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
            // Toggle back to login mode
            setState(() {
              _isClientSignup = false;
            });
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.5,
                      colors: [Color(0xFF1A0808), Color(0xFF080808)],
                    ),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 48),
                        _buildUnifiedForm(),
                        const SizedBox(height: 48),
                        _buildPrivacyFooter(),
                      ],
                    ),
                  ),
                ),
              ),
              if (state is AuthLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFDC2726)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
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
                  color: const Color(0xFFDC2726).withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.lock_person, size: 70, color: Colors.grey[800]),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Algraphy Pro',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in to your account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedForm() { // This method was missing and has been added.
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isClientSignup) ...[
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Full Name', Icons.person_outline_rounded),
              validator: (value) => value!.isEmpty ? 'Enter your name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
              validator: (value) => value!.isEmpty ? 'Enter phone number' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Company / Brand Name', Icons.business_outlined),
              validator: (value) => value!.isEmpty ? 'Enter company name' : null,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              value: _selectedIndustry,
              items: _industries.map((e) => {'label': e.isEmpty ? 'Select Industry' : e, 'value': e}).toList(),
              onChanged: (val) => setState(() => _selectedIndustry = val),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              value: _selectedService,
              items: _services.map((e) => {'label': e.isEmpty ? 'Select Service Needed' : e, 'value': e}).toList(),
              onChanged: (val) => setState(() => _selectedService = val),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField( // This TextFormField was missing in the original document.
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Email Address', Icons.alternate_email),
            validator: (value) => value!.isEmpty ? 'Enter email' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Password', Icons.lock_outline_rounded).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            validator: (value) => value!.isEmpty ? 'Enter password' : null,
          ),
          const SizedBox(height: 32),
          _buildSubmitButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (_isClientSignup) {
                  if (_selectedIndustry.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an industry'), backgroundColor: Colors.orange));
                    return;
                  }
                  if (_selectedService.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a service'), backgroundColor: Colors.orange));
                    return;
                  }
                  context.read<AuthBloc>().add(ClientSignupRequested(
                    name: _nameController.text.trim(),
                    email: _emailController.text.trim(),
                    password: _passwordController.text,
                    phone: _phoneController.text.trim(),
                    companyName: _companyController.text.trim(),
                    industry: _selectedIndustry,
                    servicesNeeded: _selectedService,
                  ));
                } else {
                  context.read<AuthBloc>().add(LoginRequested(
                    _emailController.text.trim(),
                    _passwordController.text,
                  ));
                }
              }
            },
            label: _isClientSignup ? 'Submit Request' : 'Sign In',
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _isClientSignup = !_isClientSignup),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                children: [
                  TextSpan(text: _isClientSignup ? 'Already a Client? ' : 'New to Algraphy Pro? '),
                  TextSpan(
                    text: _isClientSignup ? 'Login here' : 'Become a Client',
                    style: const TextStyle(color: Color(0xFFDC2726), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton({required VoidCallback onPressed, required String label}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2726), Color(0xFFB01D1C)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2726).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }



  Widget _buildDropdown({
    required String value,
    required List<Map<String, String>> items,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1C1C1C),
          icon: const Icon(Icons.expand_more_rounded, color: Colors.grey),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          items: items.map((type) {
            return DropdownMenuItem(
              value: type['value'],
              child: Text(type['label']!),
            );
          }).toList(),
          onChanged: (val) => onChanged(val!),
        ),
      ),
    );
  }

  Widget _buildPrivacyFooter() {
    return Column(
      children: [
        Divider(color: Colors.white.withOpacity(0.05)),
        const SizedBox(height: 16),
        Opacity(
          opacity: 0.6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Secured by Algraphy', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 8),
              Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse(AppConstants.privacyPolicyUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
      filled: true,
      fillColor: const Color(0xFF161616),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDC2726), width: 1.5),
      ),
      floatingLabelStyle: const TextStyle(color: Color(0xFFDC2726)),
    );
  }
}