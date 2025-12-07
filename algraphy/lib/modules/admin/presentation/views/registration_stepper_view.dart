import 'package:algraphy/modules/admin/data/repositories/admin_data_repository.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get_it/get_it.dart'; 
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';


class RegistrationStepperView extends StatefulWidget {
  final UserModel? userToEdit; // NEW: Accept user for editing

  const RegistrationStepperView({super.key, this.userToEdit});

  @override
  State<RegistrationStepperView> createState() => _RegistrationStepperViewState();
}

class _RegistrationStepperViewState extends State<RegistrationStepperView> {
  int _currentStep = 0;
  final int _totalSteps = 5;
  final _formKey = GlobalKey<FormState>();

  final List<String> _stepTitles = ["Basic Info", "Personal Details", "Contact Info", "Work Info", "Hierarchy Info"];

  List<String> _departments = []; 
  List<UserModel> _employeeList = []; 
  bool _isLoadingData = true;

  // Work
  String? _selectedDepartment;
  final _locationCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _dojCtrl = TextEditingController();
  final _currExpCtrl = TextEditingController(); 
  final _totalExpCtrl = TextEditingController(); 
  final _sourceOfHireCtrl = TextEditingController(); 
  String? _employmentType;
  String? _employeeStatus;
  String? _zohoRole; 

  // Basic
  final _empIdCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _nickNameCtrl = TextEditingController(); 
  final _emailCtrl = TextEditingController();
  final _jobDescCtrl = TextEditingController(); 
  final _subJobDescCtrl = TextEditingController(); 
  
  // Financials
  final _salaryCtrl = TextEditingController();
  final _lastMonthCommCtrl = TextEditingController(); 
  final _ibanCtrl = TextEditingController();

  // Hierarchy
  String? _selectedReportingManagerId;
  String? _selectedSecondaryManagerId;

  // Personal
  final _dobCtrl = TextEditingController();
  final _ageCtrl = TextEditingController(); 
  String _gender = "Male";
  String? _maritalStatus;
  final _aboutMeCtrl = TextEditingController();
  final _expertiseCtrl = TextEditingController();

  // Contact
  final _workPhoneCtrl = TextEditingController();
  final _extCtrl = TextEditingController(); 
  final _personalMobileCtrl = TextEditingController();
  final _personalEmailCtrl = TextEditingController(); 
  final _seatingLocationCtrl = TextEditingController();
  final _presentAddressCtrl = TextEditingController();
  final _permanentAddressCtrl = TextEditingController(); 

  String? _profilePicPath;
  Uint8List? _profilePicBytes;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    // NEW: Prefill data if editing
    if (widget.userToEdit != null) {
      _prefillUserData(widget.userToEdit!);
    }
  }

  void _prefillUserData(UserModel user) {
    // Basic
    _empIdCtrl.text = user.employeeId ?? '';
    _firstNameCtrl.text = user.firstName ?? '';
    _lastNameCtrl.text = user.lastName ?? '';
    _nickNameCtrl.text = user.nickName ?? '';
    _emailCtrl.text = user.email;
    
    // Financials
    _salaryCtrl.text = user.salary?.toString() ?? '';
    _ibanCtrl.text = user.iban ?? '';
    
    // Work
    // Note: Dropdown values must exist in the lists fetched from API or they won't show
    _selectedDepartment = user.department; 
    _locationCtrl.text = user.location ?? '';
    _designationCtrl.text = user.designation ?? '';
    _dojCtrl.text = user.dateOfJoining ?? '';
    _employmentType = user.employmentType;
    _employeeStatus = user.employeeStatus;
    
    // Personal
    _dobCtrl.text = user.dateOfBirth ?? '';
    _gender = user.gender ?? "Male";
    _maritalStatus = user.maritalStatus;
    _aboutMeCtrl.text = user.aboutMe ?? '';
    
    // Contact
    _workPhoneCtrl.text = user.workPhoneNumber ?? '';
    _personalMobileCtrl.text = user.personalMobileNumber ?? '';
    _seatingLocationCtrl.text = user.seatingLocation ?? '';
    
    // Hierarchy
    _selectedReportingManagerId = user.reportingManager;
    _selectedSecondaryManagerId = user.secondaryReportingManager;
    
    // Handle Image (If URL exists)
    _profilePicPath = user.profilePicture;
  }

  Future<void> _fetchInitialData() async {
    try {
      final repo = GetIt.I<AdminRepository>();
      final results = await Future.wait([
        repo.getDepartments(),
        repo.getAllEmployees(),
      ]);
      
      if (mounted) {
        setState(() {
          _departments = results[0] as List<String>;
          _employeeList = results[1] as List<UserModel>;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _selectDate(TextEditingController controller, {bool calcAge = false}) async {
    DateTime initial = DateTime.now();
    if (controller.text.isNotEmpty) {
      try { initial = DateFormat('yyyy-MM-dd').parse(controller.text); } catch (_) {}
    }
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: initial, firstDate: DateTime(1950), lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFFDC2726), onPrimary: Colors.white, surface: Color(0xFF1C1C1C), onSurface: Colors.white)), child: child!);
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
        if (calcAge) {
          final today = DateTime.now();
          int age = today.year - picked.year;
          if (today.month < picked.month || (today.month == picked.month && today.day < picked.day)) {
            age--;
          }
          _ageCtrl.text = "$age years";
        }
      });
    }
  }

  Future<void> _submitOnboarding() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fix errors"), backgroundColor: Colors.orange));
      return;
    }

    final cleanSalary = _salaryCtrl.text.replaceAll(',', '');

    final newUser = UserModel(
      id: widget.userToEdit?.id ?? '', // Use existing ID if editing
      email: _emailCtrl.text.trim(), 
      password: '', // Password not updated here usually
      firstName: _firstNameCtrl.text.trim(), lastName: _lastNameCtrl.text.trim(),
      nickName: _nickNameCtrl.text.trim(), employeeId: _empIdCtrl.text.trim(),
      
      salary: double.tryParse(cleanSalary),
      iban: _ibanCtrl.text.trim(),
      lastMonthCommission: double.tryParse(_lastMonthCommCtrl.text),

      department: _selectedDepartment, location: _locationCtrl.text,
      designation: _designationCtrl.text, dateOfJoining: _dojCtrl.text,
      employmentType: _employmentType, employeeStatus: _employeeStatus,
      zohoRole: _zohoRole, currentExperience: _currExpCtrl.text,
      totalExperience: _totalExpCtrl.text, sourceOfHire: _sourceOfHireCtrl.text,

      dateOfBirth: _dobCtrl.text, gender: _gender, maritalStatus: _maritalStatus,
      aboutMe: _aboutMeCtrl.text, expertise: _expertiseCtrl.text,

      workPhoneNumber: _workPhoneCtrl.text, extension: _extCtrl.text,
      personalMobileNumber: _personalMobileCtrl.text,
      personalEmailAddress: _personalEmailCtrl.text, seatingLocation: _seatingLocationCtrl.text,
      presentAddress: _presentAddressCtrl.text, permanentAddress: _permanentAddressCtrl.text,
      
      reportingManager: _selectedReportingManagerId, secondaryReportingManager: _selectedSecondaryManagerId,
      
      jobDescription: _jobDescCtrl.text, subJobDescription: _subJobDescCtrl.text,
    );

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Submitting...")));
      
      // Check if we are creating or updating
      if (widget.userToEdit == null) {
        await GetIt.I<AdminRepository>().createEmployee(newUser, profilePicPath: _profilePicPath,profilePicBytes: _profilePicBytes);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Employee Created!")));
      } else {
    
        await GetIt.I<AdminRepository>().updateEmployee(newUser, profilePicPath: _profilePicPath,profilePicBytes: _profilePicBytes);
      }
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // --- VALIDATORS ---
  String? _validateEmail(String? val) {
    if (val == null || val.isEmpty) return 'Required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(val)) return 'Invalid Email';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _isLoadingData ? const Center(child: CircularProgressIndicator()) : Column(children: [
      const SizedBox(height: 20), _buildCustomStepperHeader(), const SizedBox(height: 20),
      Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: SingleChildScrollView(child: Form(key: _formKey, child: Column(children: [
          if (_currentStep == 0) _buildProfilePicPicker(),
          _buildStepContent(_currentStep),
        ]))))),
      _buildBottomNavigation(),
    ]);
  }

  Widget _buildProfilePicPicker() {
    return Column(children: [
      GestureDetector(onTap: () async {
        final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
        if (result != null) setState(() { kIsWeb ? _profilePicBytes = result.files.single.bytes : _profilePicPath = result.files.single.path; });
      }, child: CircleAvatar(radius: 50, backgroundColor: Colors.grey[800], backgroundImage: (kIsWeb && _profilePicBytes != null) ? MemoryImage(_profilePicBytes!) : (!kIsWeb && _profilePicPath != null) ? FileImage(io.File(_profilePicPath!)) as ImageProvider : null, child: (_profilePicPath == null && _profilePicBytes == null) ? const Icon(Icons.camera_alt, color: Colors.white, size: 30) : null)),
      const SizedBox(height: 8), const Text("Upload Photo", style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 24)
    ]);
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0: return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader("Basic Information"), const SizedBox(height: 20),
          _buildTwoColumnRow(_customTextField("First Name", _firstNameCtrl, isRequired: true), _customTextField("Last Name", _lastNameCtrl, isRequired: true)),
          const SizedBox(height: 16),
          _buildTwoColumnRow(_customTextField("Nick Name", _nickNameCtrl), _customTextField("Employee ID", _empIdCtrl, isRequired: true, icon: Icons.badge_outlined)),
          const SizedBox(height: 16),
          _customTextField("Work Email (Login ID)", _emailCtrl, isRequired: true, icon: Icons.email, validator: _validateEmail),
          const SizedBox(height: 16), const Divider(color: Colors.white24), _sectionHeader("Financials"), const SizedBox(height: 16),
          _buildTwoColumnRow(_customTextField("Salary", _salaryCtrl, icon: Icons.attach_money, isNumber: true, isSalary: true), _customTextField("Pending Commission", _lastMonthCommCtrl, isNumber: true)),
          const SizedBox(height: 16),
          _customTextField("IBAN", _ibanCtrl, icon: Icons.account_balance),
          const SizedBox(height: 16),
          _customTextField("Job Description", _jobDescCtrl, maxLines: 2),
          const SizedBox(height: 16),
          _customTextField("Sub Job Description", _subJobDescCtrl, maxLines: 2),
        ]);
      case 1: return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader("Personal Details"), const SizedBox(height: 20),
          _buildTwoColumnRow(_customTextField("Date of Birth", _dobCtrl, icon: Icons.cake, isDate: true), _customTextField("Age", _ageCtrl, readOnly: true)),
          const SizedBox(height: 16),
          _customDropdown("Marital Status", ["Single", "Married", "Divorced"], (val) => _maritalStatus = val),
          const SizedBox(height: 16), const Text("Gender", style: TextStyle(color: Colors.grey, fontSize: 12)),
          Row(children: [_buildGenderRadio("Male"), const SizedBox(width: 20), _buildGenderRadio("Female")]),
          const SizedBox(height: 16),
          _customTextField("About Me (Optional)", _aboutMeCtrl, maxLines: 3),
          const SizedBox(height: 16), _customTextField("Expertise", _expertiseCtrl),
        ]);
      case 2: return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader("Contact Details"), const SizedBox(height: 20),
          _buildTwoColumnRow(_customTextField("Work Phone", _workPhoneCtrl, icon: Icons.phone), _customTextField("Personal Mobile", _personalMobileCtrl, icon: Icons.phone_android)),
          const SizedBox(height: 16),
          _customTextField("Personal Email", _personalEmailCtrl, icon: Icons.email_outlined, validator: _validateEmail),
          const SizedBox(height: 16),
          _customTextField("Seating Location", _seatingLocationCtrl, icon: Icons.chair),
          const SizedBox(height: 16),
          _customTextField("Present Address", _presentAddressCtrl, icon: Icons.home, maxLines: 3),
          const SizedBox(height: 16),
          _customTextField("Permanent Address", _permanentAddressCtrl, icon: Icons.location_city, maxLines: 3),
        ]);
      case 3: return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader("Work Information"), const SizedBox(height: 20),
          _buildTwoColumnRow(_customDropdown("Department", _departments, (val) => _selectedDepartment = val, isRequired: true), _customTextField("Location", _locationCtrl, icon: Icons.place)),
          const SizedBox(height: 16),
          _buildTwoColumnRow(_customTextField("Designation", _designationCtrl, icon: Icons.badge), _customTextField("Date of Joining", _dojCtrl, icon: Icons.calendar_today, isDate: true)),
          const SizedBox(height: 16),
          _buildTwoColumnRow(_customDropdown("Emp Type", ["Permanent", "Contract", "Intern"], (val) => _employmentType = val), _customDropdown("Emp Status", ["Active", "Probation", "Terminated"], (val) => _employeeStatus = val)),
          const SizedBox(height: 16),
          _customDropdown("Zoho Role", ["Team Member", "Manager", "Admin"], (val) => _zohoRole = val),
          const SizedBox(height: 16),
          _buildTwoColumnRow(_customTextField("Current Exp.", _currExpCtrl), _customTextField("Total Exp.", _totalExpCtrl)),
          const SizedBox(height: 16),
          _customTextField("Source of Hire", _sourceOfHireCtrl),
        ]);
      case 4: return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader("Hierarchy Information"), const SizedBox(height: 20),
          _buildTwoColumnRow(_employeeDropdown("Reporting Manager", _selectedReportingManagerId, (val) => _selectedReportingManagerId = val), _employeeDropdown("Secondary Manager", _selectedSecondaryManagerId, (val) => _selectedSecondaryManagerId = val)),
        ]);
      default: return const SizedBox.shrink();
    }
  }

  // --- Widgets ---
  Widget _buildGenderRadio(String value) { return Row(children: [Radio<String>(value: value, groupValue: _gender, activeColor: const Color(0xFFDC2726), onChanged: (val) => setState(() => _gender = val!)), Text(value, style: const TextStyle(color: Colors.white))]); }
  Widget _buildTwoColumnRow(Widget left, Widget right) { return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 16), Expanded(child: right)]); }
  Widget _sectionHeader(String title) { return Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)); }
  
  Widget _customTextField(String label, TextEditingController ctrl, {IconData? icon, bool isNumber = false, bool isSalary = false, bool isDate = false, int maxLines = 1, bool isRequired = false, bool readOnly = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isSalary ? [ThousandsSeparatorInputFormatter()] : [],
      maxLines: maxLines,
      readOnly: readOnly || isDate,
      validator: validator ?? (isRequired ? (val) => val == null || val.isEmpty ? 'Required' : null : null),
      onTap: isDate ? () => _selectDate(ctrl, calcAge: label == 'Date of Birth') : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.grey), prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null, filled: true, fillColor: const Color(0xFF2C2C2C), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
    );
  }

  Widget _customDropdown(String label, List<String> items, Function(String?) onChanged, {bool isRequired = false}) {
    final uniqueItems = items.toSet().toList();
    return DropdownButtonFormField<String>(
      value: (items.contains(label == 'Department' ? _selectedDepartment : (label == 'Emp Type' ? _employmentType : (label == 'Emp Status' ? _employeeStatus : (label == 'Zoho Role' ? _zohoRole : (label == 'Marital Status' ? _maritalStatus : null)))))) ? (label == 'Department' ? _selectedDepartment : (label == 'Emp Type' ? _employmentType : (label == 'Emp Status' ? _employeeStatus : (label == 'Zoho Role' ? _zohoRole : (label == 'Marital Status' ? _maritalStatus : null))))) : null,
      dropdownColor: const Color(0xFF2C2C2C),
      validator: isRequired ? (val) => val == null ? 'Required' : null : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: const Color(0xFF2C2C2C), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
      items: uniqueItems.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _employeeDropdown(String label, String? selectedId, Function(String?) onChanged) {
    final Set<String> seenIds = {};
    final List<DropdownMenuItem<String>> dropdownItems = [];
    for (var emp in _employeeList) {
      if (!seenIds.contains(emp.id)) {
        seenIds.add(emp.id);
        dropdownItems.add(DropdownMenuItem(value: emp.id, child: Text(emp.fullName.isNotEmpty ? emp.fullName : emp.email)));
      }
    }
    String? validSelectedId = selectedId;
    if (validSelectedId != null && !seenIds.contains(validSelectedId)) validSelectedId = null;

    return DropdownButtonFormField<String>(
      value: validSelectedId,
      dropdownColor: const Color(0xFF2C2C2C),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: const Color(0xFF2C2C2C), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
      items: dropdownItems,
      onChanged: onChanged,
    );
  }

  Widget _buildCustomStepperHeader() {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: List.generate(_totalSteps, (index) { bool isActive = index == _currentStep; bool isCompleted = index < _currentStep; return Row(children: [AnimatedContainer(duration: const Duration(milliseconds: 300), width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: isActive || isCompleted ? const Color(0xFFDC2726) : Colors.transparent, border: Border.all(color: isActive || isCompleted ? const Color(0xFFDC2726) : Colors.grey, width: 2)), child: Center(child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 20) : Text("${index + 1}", style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)))), const SizedBox(width: 8), if (isActive) Text(_stepTitles[index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), if (index < _totalSteps - 1) Container(width: 40, height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), color: isCompleted ? const Color(0xFFDC2726) : Colors.grey[800])]); })));
  }

  Widget _buildBottomNavigation() {
    return Container(padding: const EdgeInsets.all(16), color: const Color(0xFF080808), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [if (_currentStep > 0) OutlinedButton(onPressed: () => setState(() => _currentStep--), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: const Text("Back", style: TextStyle(color: Colors.white))) else const SizedBox(), ElevatedButton(onPressed: () => _currentStep < _totalSteps - 1 ? setState(() => _currentStep++) : _submitOnboarding(), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2726), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)), child: Text(widget.userToEdit != null ? "Update" : (_currentStep == _totalSteps - 1 ? "Finish" : "Next"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))]));
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final double value = double.parse(newValue.text.replaceAll(',', ''));
    final String newText = NumberFormat("#,##0").format(value);
    return TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}