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
  
  // Signup specific
  final _talentNameController = TextEditingController();
  final List<Map<String, String>> _userTypes = [
    {'label': 'Select User Type', 'value': ''},
    {'label': 'Talent', 'value': 'Talent'},
    {'label': 'Talent Manager / UGC Manager', 'value': 'Talent Manager'},
    {'label': 'Client / Customer', 'value': 'Client'},
    {'label': 'Supplier / Vendor', 'value': 'Supplier'},
    {'label': 'AlGraphy Pro Team', 'value': 'AlGraphy Pro Team'},
  ];

  final List<Map<String, String>> _talentSpecificTypes = [
    {'label': 'Select Talent Type', 'value': ''},
    {'label': 'Model/Cast/Usher', 'value': 'Model/Cast/Usher'},
    {'label': 'Vocal/Voice-over', 'value': 'Vocal/Voice-over'},
    {'label': 'Influencer/Celebrity/UGC', 'value': 'Influencer/Celebrity/UGC'},
    {'label': 'Musician/Solo/Band', 'value': 'Musician/Solo/Band'},
    {'label': 'Media/Photographer/Videographer/Video Editor/Director', 'value': 'Media/Photographer/Videographer/Video Editor/Director'},
    {'label': 'Designer/Graphic/Motion/3D Modeling', 'value': 'Designer/Graphic/Motion/3D Modeling'},
    {'label': 'Interior & Exterior/2D Design/3D Design', 'value': 'Interior & Exterior/2D Design/3D Design'},
    {'label': 'Marketing/Social Media Specialist', 'value': 'Marketing/Social Media Specialist'},
    {'label': 'Content Writer', 'value': 'Content Writer'},
    {'label': 'Journalism/Magazines', 'value': 'Journalism/Magazines'},
    {'label': 'Media Buying/E-commerce', 'value': 'Media Buying/E-commerce'},
    {'label': 'Website/App Developer', 'value': 'Website/App Developer'},
    {'label': 'Sales Specialist / Sales Director', 'value': 'Sales Specialist / Sales Director'},
    {'label': 'HR Specialist / HR Operations / HR Director', 'value': 'HR Specialist / HR Operations / HR Director'},
    {'label': 'Executive Assistant', 'value': 'Executive Assistant'},
    {'label': 'Accountant', 'value': 'Accountant'},
  ];

  String _selectedTalentType = '';
  String _selectedSpecificTalentType = '';
  bool _isTalentSignup = false;

  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _talentNameController.dispose();
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
          } else if (state is AuthTalentRedirect) {
            Navigator.pushNamed(
              context,
              AppRoutes.talentPortal,
              arguments: {'url': state.url},
            );
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
        Text(
          _isTalentSignup ? 'Join our creative community' : 'Sign in to your account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isTalentSignup) ...[
            TextFormField(
              controller: _talentNameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Full Name', Icons.person_outline_rounded),
              validator: (value) => value!.isEmpty ? 'Enter name' : null,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              value: _selectedTalentType,
              items: _userTypes,
              onChanged: (val) {
                setState(() {
                  _selectedTalentType = val;
                  if (val != 'Talent') _selectedSpecificTalentType = '';
                });
              },
            ),
            if (_selectedTalentType == 'Talent') ...[
              const SizedBox(height: 16),
              _buildDropdown(
                value: _selectedSpecificTalentType,
                items: _talentSpecificTypes,
                onChanged: (val) => setState(() => _selectedSpecificTalentType = val),
              ),
            ],
            const SizedBox(height: 16),
          ],
          TextFormField(
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
                if (_isTalentSignup) {
                  if (_selectedTalentType.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a user type"), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  if (_selectedTalentType == 'Talent' && _selectedSpecificTalentType.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a talent type"), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  context.read<AuthBloc>().add(TalentSignupRequested(
                    name: _talentNameController.text.trim(),
                    email: _emailController.text.trim(),
                    password: _passwordController.text,
                    userType: _selectedTalentType,
                    talentType: _selectedTalentType == 'Talent' ? _selectedSpecificTalentType : _selectedTalentType,
                  ));
                } else {
                  context.read<AuthBloc>().add(LoginRequested(
                    _emailController.text.trim(),
                    _passwordController.text,
                  ));
                }
              }
            },
            label: _isTalentSignup ? 'Create Account' : 'Sign In',
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _isTalentSignup = !_isTalentSignup),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                children: [
                  TextSpan(text: _isTalentSignup ? 'Already a member? ' : 'New talent? '),
                  TextSpan(
                    text: _isTalentSignup ? 'Login' : 'Register now',
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