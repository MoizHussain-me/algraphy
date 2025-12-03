import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();

  final List<String> _steps = ['Name', 'Contact', 'Work Info'];

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    } else {
      if (_formKey.currentState!.validate()) {
        // Form complete
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Completed!')),
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  double _progressValue() => (_currentStep + 1) / _steps.length;

  Widget _stepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
            TextFormField(
              controller: _firstNameCtrl,
              decoration: _inputDecoration('First Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameCtrl,
              decoration: _inputDecoration('Last Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            TextFormField(
              controller: _emailCtrl,
              decoration: _inputDecoration('Email'),
              validator: (v) => v!.isEmpty ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: _inputDecoration('Phone Number'),
              validator: (v) => v!.isEmpty ? 'Enter a valid phone' : null,
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            TextFormField(
              controller: _designationCtrl,
              decoration: _inputDecoration('Designation'),
              validator: (v) => v!.isEmpty ? 'Enter your designation' : null,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top Progress Bar
            LinearProgressIndicator(
              value: _progressValue(),
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: _stepContent(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: _previousStep,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    child: const Text('Back'),
                  ),
                ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Text(
                      _currentStep == _steps.length - 1 ? 'Finish' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
