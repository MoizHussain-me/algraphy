import 'package:algraphy/modules/admin/data/repositories/admin_data_repository.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get_it/get_it.dart'; 
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/image_helper.dart';

class RegistrationStepperView extends StatefulWidget {
  final UserModel? userToEdit; 
  const RegistrationStepperView({super.key, this.userToEdit});

  @override
  State<RegistrationStepperView> createState() => _RegistrationStepperViewState();
}

class _RegistrationStepperViewState extends State<RegistrationStepperView> {
  int _currentStep = 0;
  final int _totalSteps = 5;
  final _formKey = GlobalKey<FormState>();

  final List<String> _stepTitles = ["Basic Info", "Financials", "Contact (Optional)", "Work Info", "Personal (Optional)"];

  List<String> _departments = []; 
  List<UserModel> _employeeList = []; 
  bool _isLoadingData = true;

  // --- CONTROLLERS ---
  
  // Basic
  final _empIdCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _nickNameCtrl = TextEditingController(); 
  final _emailCtrl = TextEditingController();
  final _jobDescCtrl = TextEditingController(); 
  final _subJobDescCtrl = TextEditingController(); 
  String _systemRole = "employee"; // NEW: System Role
  
  // Financials
  final _salaryCtrl = TextEditingController();
  final _lastMonthCommCtrl = TextEditingController(); 
  final _hourlyRateCtrl = TextEditingController(); 
  final _ibanCtrl = TextEditingController();

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
  // Removed _zohoRole

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

  // Image
  String? _profilePicPath;
  Uint8List? _profilePicBytes;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  // CRITICAL FIX: Update form when widget.userToEdit changes
  @override
  void didUpdateWidget(RegistrationStepperView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userToEdit != oldWidget.userToEdit && widget.userToEdit != null) {
      _prefillUserData(widget.userToEdit!);
    }
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
        
        if (widget.userToEdit != null) {
          _prefillUserData(widget.userToEdit!);
        }
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _prefillUserData(UserModel user) {
    // Basic
    _firstNameCtrl.text = user.firstName ?? '';
    _lastNameCtrl.text = user.lastName ?? '';
    _nickNameCtrl.text = user.nickName ?? '';
    _empIdCtrl.text = user.employeeId ?? '';
    _emailCtrl.text = user.email;
    
    // FIX: Normalize role to lowercase to match dropdown values
    String incomingRole = (user.role).toLowerCase();
    if (['employee', 'manager', 'admin'].contains(incomingRole)) {
      _systemRole = incomingRole;
    } else {
      _systemRole = 'employee'; // Fallback to prevent dropdown crash
    }

    _jobDescCtrl.text = user.jobDescription ?? '';       
    _subJobDescCtrl.text = user.subJobDescription ?? ''; 

    // Financials
    _salaryCtrl.text = user.salary?.toString() ?? '';
    _lastMonthCommCtrl.text = user.lastMonthCommission?.toString() ?? ''; 
    _hourlyRateCtrl.text = user.employeeHourlyRate?.toString() ?? '';     
    _ibanCtrl.text = user.iban ?? '';

    // Work
    if (user.department != null && _departments.contains(user.department)) {
      _selectedDepartment = user.department;
    }
    _locationCtrl.text = user.location ?? '';
    _designationCtrl.text = user.designation ?? '';
    _dojCtrl.text = (user.dateOfJoining == "0000-00-00") ? "" : (user.dateOfJoining ?? '');
    _employmentType = user.employmentType;
    _employeeStatus = user.employeeStatus;
    _sourceOfHireCtrl.text = user.sourceOfHire ?? '';
    _currExpCtrl.text = user.currentExperience ?? '';
    _totalExpCtrl.text = user.totalExperience ?? '';

    // Personal
    _dobCtrl.text = (user.dateOfBirth == "0000-00-00") ? "" : (user.dateOfBirth ?? '');
    if (user.calculatedAge.isNotEmpty) _ageCtrl.text = user.calculatedAge;
    
    _gender = user.gender ?? "Male";
    _maritalStatus = user.maritalStatus;
    _aboutMeCtrl.text = user.aboutMe ?? '';
    _expertiseCtrl.text = user.expertise ?? ''; 

    // Contact
    _workPhoneCtrl.text = user.workPhoneNumber ?? '';
    _extCtrl.text = user.extension ?? '';
    _personalMobileCtrl.text = user.personalMobileNumber ?? '';
    _personalEmailCtrl.text = user.personalEmailAddress ?? '';
    _seatingLocationCtrl.text = user.seatingLocation ?? '';
    _presentAddressCtrl.text = user.presentAddress ?? ''; 
    _permanentAddressCtrl.text = user.permanentAddress ?? ''; 

    // Hierarchy
    _selectedReportingManagerId = user.reportingManager;
    _selectedSecondaryManagerId = user.secondaryReportingManager;
    
    _profilePicPath = user.profilePicture;
    
    // Force UI rebuild after prefill
    if (mounted) setState(() {});
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
      id: widget.userToEdit?.id ?? '', 
      email: _emailCtrl.text.trim(), 
      password: '',
      
      // Pass selected System Role (normalized)
      role: _systemRole.toLowerCase(), 
      
      firstName: _firstNameCtrl.text.trim(), lastName: _lastNameCtrl.text.trim(),
      nickName: _nickNameCtrl.text.trim(), employeeId: _empIdCtrl.text.trim(),
      
      salary: double.tryParse(cleanSalary),
      lastMonthCommission: double.tryParse(_lastMonthCommCtrl.text),
      employeeHourlyRate: double.tryParse(_hourlyRateCtrl.text),
      iban: _ibanCtrl.text.trim(),
      
      jobDescription: _jobDescCtrl.text,
      subJobDescription: _subJobDescCtrl.text,

      department: _selectedDepartment, location: _locationCtrl.text,
      designation: _designationCtrl.text, dateOfJoining: _dojCtrl.text,
      employmentType: _employmentType, employeeStatus: _employeeStatus,
      sourceOfHire: _sourceOfHireCtrl.text,
      currentExperience: _currExpCtrl.text, totalExperience: _totalExpCtrl.text,

      dateOfBirth: _dobCtrl.text, gender: _gender, maritalStatus: _maritalStatus,
      aboutMe: _aboutMeCtrl.text, expertise: _expertiseCtrl.text,

      workPhoneNumber: _workPhoneCtrl.text, extension: _extCtrl.text,
      personalMobileNumber: _personalMobileCtrl.text,
      personalEmailAddress: _personalEmailCtrl.text,
      seatingLocation: _seatingLocationCtrl.text,
      presentAddress: _presentAddressCtrl.text,
      permanentAddress: _permanentAddressCtrl.text,
      
      reportingManager: _selectedReportingManagerId,
      secondaryReportingManager: _selectedSecondaryManagerId,
    );

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Submitting...")));
      
      if (widget.userToEdit == null) {
        await GetIt.I<AdminRepository>().createEmployee(newUser, profilePicPath: _profilePicPath, profilePicBytes: _profilePicBytes);
      } else {
        await GetIt.I<AdminRepository>().updateEmployee(newUser, profilePicPath: _profilePicPath, profilePicBytes: _profilePicBytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // ... (Validators & Helpers same as before) ...
  String? _validateEmail(String? val) {
    if (val == null || val.isEmpty) return 'Required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(val)) return 'Invalid Email';
    return null;
  }
  String? _validateIBAN(String? val) {
    if (val == null || val.isEmpty) return null; 
    if (val.length < 15) return 'IBAN too short'; 
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

  // ... (Profile Picker same as before) ...
  Widget _buildProfilePicPicker() {
    ImageProvider? imageProvider;
    if (kIsWeb && _profilePicBytes != null) { imageProvider = MemoryImage(_profilePicBytes!); } 
    else if (!kIsWeb && _profilePicPath != null) { imageProvider = FileImage(io.File(_profilePicPath!)); } 
    else if (widget.userToEdit?.profilePicture != null && widget.userToEdit!.profilePicture!.isNotEmpty) { imageProvider = NetworkImage(ImageHelper.getFullUrl(widget.userToEdit!.profilePicture)); }
    return Column(children: [GestureDetector(onTap: () async { final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true); if (result != null) setState(() { kIsWeb ? _profilePicBytes = result.files.single.bytes : _profilePicPath = result.files.single.path; }); }, child: CircleAvatar(radius: 50, backgroundColor: Colors.grey[800], backgroundImage: imageProvider, child: imageProvider == null ? const Icon(Icons.camera_alt, color: Colors.white, size: 30) : null)), const SizedBox(height: 8), const Text("Upload Photo", style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 24)]);
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0: // BASIC
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader("Basic Information"), const SizedBox(height: 20),
          _buildTwoColumnRow(_customTextField("First Name", _firstNameCtrl, isRequired: true), _customTextField("Last Name", _lastNameCtrl, isRequired: true)),
          const SizedBox(height: 16),
          _buildTwoColumnRow(_customTextField("Nick Name", _nickNameCtrl), _customTextField("Employee ID", _empIdCtrl, isRequired: true, icon: Icons.badge_outlined)),
          const SizedBox(height: 16),
          _buildTwoColumnRow(
             _customTextField("Work Email", _emailCtrl, isRequired: true, icon: Icons.email, validator: _validateEmail),
             _customDropdown("System Access", ["employee", "manager", "admin"], (val) => setState(() => _systemRole = val ?? "employee"), isRequired: true)
          ),
          const SizedBox(height: 16), 
          _customTextField("Job Description", _jobDescCtrl, maxLines: 2),
          const SizedBox(height: 16),
          _customTextField("Sub Job Description", _subJobDescCtrl, maxLines: 2),
        ]);
        
      case 1: // FINANCIALS
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader("Financial Information"), const SizedBox(height: 16),
          _buildTwoColumnRow(_customTextField("Salary", _salaryCtrl, icon: Icons.attach_money, isNumber: true, isSalary: true), _customTextField("Hourly Rate", _hourlyRateCtrl, isNumber: true)), 
          const SizedBox(height: 16),
          _buildTwoColumnRow(_customTextField("Pending Commission", _lastMonthCommCtrl, isNumber: true), _customTextField("IBAN", _ibanCtrl, icon: Icons.account_balance)),
        ]);

      case 2: // CONTACT (OPTIONAL)
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader("Contact Details (Optional)"), const SizedBox(height: 20), 
          _buildTwoColumnRow(_customTextField("Work Phone", _workPhoneCtrl, icon: Icons.phone), _customTextField("Personal Mobile", _personalMobileCtrl, icon: Icons.phone_android)), 
          const SizedBox(height: 16), 
          _customTextField("Personal Email", _personalEmailCtrl, icon: Icons.email_outlined, validator: _validateEmail), 
          const SizedBox(height: 16), 
          _customTextField("Seating Location", _seatingLocationCtrl, icon: Icons.chair), 
          const SizedBox(height: 16), 
          _customTextField("Present Address", _presentAddressCtrl, icon: Icons.home, maxLines: 3), 
          const SizedBox(height: 16), 
          _customTextField("Permanent Address", _permanentAddressCtrl, icon: Icons.location_city, maxLines: 3)
        ]);

      case 3: // WORK
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader("Work Information"), const SizedBox(height: 20),
          _buildTwoColumnRow(_customDropdown("Department", _departments, (val) => setState(() => _selectedDepartment = val), isRequired: true), _customTextField("Location", _locationCtrl, icon: Icons.place)),
          const SizedBox(height: 16),
          _buildTwoColumnRow(_customTextField("Designation", _designationCtrl, icon: Icons.badge), _customTextField("Date of Joining", _dojCtrl, icon: Icons.calendar_today, isDate: true)),
          const SizedBox(height: 16),
          _buildTwoColumnRow(_customDropdown("Emp Type", ["Permanent", "Contract", "Intern"], (val) => setState(() => _employmentType = val)), _customDropdown("Emp Status", ["Active", "Probation", "Terminated"], (val) => setState(() => _employeeStatus = val))),
          const SizedBox(height: 16),
          _buildTwoColumnRow(_customTextField("Current Exp.", _currExpCtrl), _customTextField("Total Exp.", _totalExpCtrl)),
          const SizedBox(height: 16),
          _customTextField("Source of Hire", _sourceOfHireCtrl),
        ]);

      case 4: // PERSONAL (OPTIONAL)
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader("Personal Details (Optional)"), const SizedBox(height: 20), 
          _buildTwoColumnRow(_customTextField("Date of Birth", _dobCtrl, icon: Icons.cake, isDate: true), _customTextField("Age", _ageCtrl, readOnly: true)), 
          const SizedBox(height: 16), 
          _customDropdown("Marital Status", ["Single", "Married", "Divorced"], (val) => setState(() => _maritalStatus = val)), 
          const SizedBox(height: 16), 
          const Text("Gender", style: TextStyle(color: Colors.grey, fontSize: 12)), 
          Row(children: [_buildGenderRadio("Male"), const SizedBox(width: 20), _buildGenderRadio("Female"), const SizedBox(width: 20), _buildGenderRadio("Prefer not to say")]), 
          const SizedBox(height: 16), 
          _customTextField("About Me", _aboutMeCtrl, maxLines: 3), 
          const SizedBox(height: 16), 
          _customTextField("Expertise", _expertiseCtrl),
          const SizedBox(height: 32),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          _sectionHeader("Hierarchy Information"), 
          const SizedBox(height: 20), 
          _buildTwoColumnRow(
            _employeeDropdown("Reporting Manager", _selectedReportingManagerId, (val) => setState(() => _selectedReportingManagerId = val)), 
            _employeeDropdown("Secondary Manager", _selectedSecondaryManagerId, (val) => setState(() => _selectedSecondaryManagerId = val))
          )
        ]);

      default: return const SizedBox.shrink();
    }
  }

  // ... (UI Helpers same as before) ...
  Widget _buildGenderRadio(String value) { return Row(children: [Radio<String>(value: value, groupValue: _gender, activeColor: const Color(0xFFDC2726), onChanged: (val) => setState(() => _gender = val!)), Text(value, style: const TextStyle(color: Colors.white))]); }
  Widget _buildTwoColumnRow(Widget left, Widget right) { return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 16), Expanded(child: right)]); }
  Widget _sectionHeader(String title) { return Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)); }
  Widget _customTextField(String label, TextEditingController ctrl, {IconData? icon, bool isNumber = false, bool isSalary = false, bool isDate = false, int maxLines = 1, bool isRequired = false, bool readOnly = false, String? Function(String?)? validator}) {
    return TextFormField(controller: ctrl, keyboardType: isNumber ? TextInputType.number : TextInputType.text, inputFormatters: isSalary ? [ThousandsSeparatorInputFormatter()] : [], maxLines: maxLines, readOnly: readOnly || isDate, validator: validator ?? (isRequired ? (val) => val == null || val.isEmpty ? 'Required' : null : null), onTap: isDate ? () => _selectDate(ctrl, calcAge: label == 'Date of Birth') : null, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.grey), prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null, suffixIcon: isDate && ctrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 16), onPressed: () => ctrl.clear()) : null, filled: true, fillColor: const Color(0xFF2C2C2C), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
  }
  Widget _customDropdown(String label, List<String> items, Function(String?) onChanged, {bool isRequired = false}) {
    final uniqueItems = items.toSet().toList();
    // Logic to set initial value
    String? initialVal;
    if (label == 'System Access') initialVal = _systemRole; // Set initial for new field
    else initialVal = (items.contains(label == 'Department' ? _selectedDepartment : (label == 'Emp Type' ? _employmentType : (label == 'Emp Status' ? _employeeStatus : (label == 'Marital Status' ? _maritalStatus : null))))) ? (label == 'Department' ? _selectedDepartment : (label == 'Emp Type' ? _employmentType : (label == 'Emp Status' ? _employeeStatus : (label == 'Marital Status' ? _maritalStatus : null)))) : null;

    return DropdownButtonFormField<String>(value: initialVal, dropdownColor: const Color(0xFF2C2C2C), validator: isRequired ? (val) => val == null ? 'Required' : null : null, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: const Color(0xFF2C2C2C), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged);
  }
  Widget _employeeDropdown(String label, String? selectedId, Function(String?) onChanged) {
    final Set<String> seenIds = {}; 
    final List<DropdownMenuItem<String>> dropdownItems = []; 
    for (var emp in _employeeList) { 
      // Only show admins and managers in the reporting manager dropdown
      if ((emp.role == 'admin' || emp.role == 'manager') && !seenIds.contains(emp.id)) { 
        seenIds.add(emp.id); 
        dropdownItems.add(DropdownMenuItem(value: emp.id, child: Text(emp.fullName.isNotEmpty ? emp.fullName : emp.email))); 
      } 
    } 
    String? validSelectedId = selectedId; 
    if (validSelectedId != null && !seenIds.contains(validSelectedId)) validSelectedId = null; 
    return DropdownButtonFormField<String>(value: validSelectedId, dropdownColor: const Color(0xFF2C2C2C), style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: const Color(0xFF2C2C2C), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: dropdownItems, onChanged: onChanged);
  }
  Widget _buildCustomStepperHeader() { return SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: List.generate(_totalSteps, (index) { bool isActive = index == _currentStep; bool isCompleted = index < _currentStep; return Row(children: [AnimatedContainer(duration: const Duration(milliseconds: 300), width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: isActive || isCompleted ? const Color(0xFFDC2726) : Colors.transparent, border: Border.all(color: isActive || isCompleted ? const Color(0xFFDC2726) : Colors.grey, width: 2)), child: Center(child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 20) : Text("${index + 1}", style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)))), const SizedBox(width: 8), if (isActive) Text(_stepTitles[index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), if (index < _totalSteps - 1) Container(width: 40, height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), color: isCompleted ? const Color(0xFFDC2726) : Colors.grey[800])]); }))); }
  Widget _buildBottomNavigation() { return Container(padding: const EdgeInsets.all(16), color: const Color(0xFF080808), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [if (_currentStep > 0) OutlinedButton(onPressed: () => setState(() => _currentStep--), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: const Text("Back", style: TextStyle(color: Colors.white))) else const SizedBox(), ElevatedButton(onPressed: () => _currentStep < _totalSteps - 1 ? setState(() => _currentStep++) : _submitOnboarding(), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2726), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)), child: Text(widget.userToEdit != null ? "Update" : (_currentStep == _totalSteps - 1 ? "Finish" : "Next"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))])); }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final int selectionIndex = newValue.selection.end;
    final double value = double.parse(newValue.text.replaceAll(',', ''));
    final String newText = NumberFormat("#,##0").format(value);
    return TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}