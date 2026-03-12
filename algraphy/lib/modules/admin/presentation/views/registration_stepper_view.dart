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
  final _empIdCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _nickNameCtrl = TextEditingController(); 
  final _emailCtrl = TextEditingController();
  final _jobDescCtrl = TextEditingController(); 
  final _subJobDescCtrl = TextEditingController(); 
  String _systemRole = "employee"; 
  
  final _salaryCtrl = TextEditingController();
  final _lastMonthCommCtrl = TextEditingController(); 
  final _hourlyRateCtrl = TextEditingController(); 
  final _ibanCtrl = TextEditingController();

  String? _selectedDepartment;
  final _locationCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _dojCtrl = TextEditingController();
  final _currExpCtrl = TextEditingController(); 
  final _totalExpCtrl = TextEditingController(); 
  final _sourceOfHireCtrl = TextEditingController(); 
  String? _employmentType;
  String? _employeeStatus;

  String? _selectedReportingManagerId;
  String? _selectedSecondaryManagerId;

  final _dobCtrl = TextEditingController();
  final _ageCtrl = TextEditingController(); 
  String _gender = "Male";
  String? _maritalStatus;
  final _aboutMeCtrl = TextEditingController();
  final _expertiseCtrl = TextEditingController();

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
  }

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
        if (widget.userToEdit != null) _prefillUserData(widget.userToEdit!);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _prefillUserData(UserModel user) {
    _firstNameCtrl.text = user.firstName ?? '';
    _lastNameCtrl.text = user.lastName ?? '';
    _nickNameCtrl.text = user.nickName ?? '';
    _empIdCtrl.text = user.employeeId ?? '';
    _emailCtrl.text = user.email;
    String incomingRole = (user.role).toLowerCase();
    _systemRole = ['employee', 'manager', 'admin'].contains(incomingRole) ? incomingRole : 'employee';
    _jobDescCtrl.text = user.jobDescription ?? '';       
    _subJobDescCtrl.text = user.subJobDescription ?? ''; 
    _salaryCtrl.text = user.salary?.toString() ?? '';
    _lastMonthCommCtrl.text = user.lastMonthCommission?.toString() ?? ''; 
    _hourlyRateCtrl.text = user.employeeHourlyRate?.toString() ?? '';     
    _ibanCtrl.text = user.iban ?? '';
    if (user.department != null && _departments.contains(user.department)) _selectedDepartment = user.department;
    _locationCtrl.text = user.location ?? '';
    _designationCtrl.text = user.designation ?? '';
    _dojCtrl.text = (user.dateOfJoining == "0000-00-00") ? "" : (user.dateOfJoining ?? '');
    _employmentType = user.employmentType;
    _employeeStatus = user.employeeStatus;
    _sourceOfHireCtrl.text = user.sourceOfHire ?? '';
    _currExpCtrl.text = user.currentExperience ?? '';
    _totalExpCtrl.text = user.totalExperience ?? '';
    _dobCtrl.text = (user.dateOfBirth == "0000-00-00") ? "" : (user.dateOfBirth ?? '');
    if (user.calculatedAge.isNotEmpty) _ageCtrl.text = user.calculatedAge;
    _gender = user.gender ?? "Male";
    _maritalStatus = user.maritalStatus;
    _aboutMeCtrl.text = user.aboutMe ?? '';
    _expertiseCtrl.text = user.expertise ?? ''; 
    _workPhoneCtrl.text = user.workPhoneNumber ?? '';
    _extCtrl.text = user.extension ?? '';
    _personalMobileCtrl.text = user.personalMobileNumber ?? '';
    _personalEmailCtrl.text = user.personalEmailAddress ?? '';
    _seatingLocationCtrl.text = user.seatingLocation ?? '';
    _presentAddressCtrl.text = user.presentAddress ?? ''; 
    _permanentAddressCtrl.text = user.permanentAddress ?? ''; 
    _selectedReportingManagerId = user.reportingManager;
    _selectedSecondaryManagerId = user.secondaryReportingManager;
    _profilePicPath = user.profilePicture;
    if (mounted) setState(() {});
  }

  Future<void> _selectDate(TextEditingController controller, {bool calcAge = false}) async {
    final theme = Theme.of(context);
    DateTime initial = DateTime.now();
    if (controller.text.isNotEmpty) {
      try { initial = DateFormat('yyyy-MM-dd').parse(controller.text); } catch (_) {}
    }
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: initial, firstDate: DateTime(1950), lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFFDC2726),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
        if (calcAge) {
          final today = DateTime.now();
          int age = today.year - picked.year;
          if (today.month < picked.month || (today.month == picked.month && today.day < picked.day)) age--;
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
      if (widget.userToEdit == null) {
        await GetIt.I<AdminRepository>().createEmployee(newUser, profilePicPath: _profilePicPath, profilePicBytes: _profilePicBytes);
      } else {
        await GetIt.I<AdminRepository>().updateEmployee(newUser, profilePicPath: _profilePicPath, profilePicBytes: _profilePicBytes);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoadingData) return Center(child: CircularProgressIndicator(color: theme.primaryColor));

    return Column(children: [
      const SizedBox(height: 20), 
      _buildCustomStepperHeader(theme), 
      const SizedBox(height: 20),
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16), 
          padding: const EdgeInsets.all(24), 
          decoration: BoxDecoration(
            color: theme.cardColor, 
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(color: theme.dividerColor.withOpacity(0.1))
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey, 
              child: Column(children: [
                if (_currentStep == 0) _buildProfilePicPicker(theme),
                _buildStepContent(_currentStep, theme, isDark),
              ])
            )
          )
        )
      ),
      _buildBottomNavigation(theme),
    ]);
  }

  Widget _buildProfilePicPicker(ThemeData theme) {
    ImageProvider? imageProvider;
    if (kIsWeb && _profilePicBytes != null) { imageProvider = MemoryImage(_profilePicBytes!); } 
    else if (!kIsWeb && _profilePicPath != null) { imageProvider = FileImage(io.File(_profilePicPath!)); } 
    else if (widget.userToEdit?.profilePicture != null && widget.userToEdit!.profilePicture!.isNotEmpty) { 
      imageProvider = NetworkImage(ImageHelper.getFullUrl(widget.userToEdit!.profilePicture)); 
    }
    return Column(children: [
      GestureDetector(
        onTap: () async { 
          final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true); 
          if (result != null) setState(() { kIsWeb ? _profilePicBytes = result.files.single.bytes : _profilePicPath = result.files.single.path; }); 
        }, 
        child: CircleAvatar(
          radius: 50, 
          backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300], 
          backgroundImage: imageProvider, 
          child: imageProvider == null ? Icon(Icons.camera_alt, color: theme.hintColor, size: 30) : null
        )
      ), 
      const SizedBox(height: 8), 
      Text("Upload Photo", style: TextStyle(color: theme.hintColor, fontSize: 12)), 
      const SizedBox(height: 24)
    ]);
  }

  Widget _buildStepContent(int step, ThemeData theme, bool isDark) {
    switch (step) {
      case 0: // BASIC
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader("Basic Information", theme), const SizedBox(height: 20),
          _buildTwoColumnRow(_customTextField("First Name", _firstNameCtrl, theme, isRequired: true), _customTextField("Last Name", _lastNameCtrl, theme, isRequired: true)),
          const SizedBox(height: 16),
          _buildTwoColumnRow(_customTextField("Nick Name", _nickNameCtrl, theme), _customTextField("Employee ID", _empIdCtrl, theme, isRequired: true, icon: Icons.badge_outlined)),
          const SizedBox(height: 16),
          _buildTwoColumnRow(
              _customTextField("Work Email", _emailCtrl, theme, isRequired: true, icon: Icons.email, validator: (v) => v!.isEmpty ? 'Required' : null),
              _customDropdown("System Access", ["employee", "manager", "admin"], theme, (val) => setState(() => _systemRole = val ?? "employee"), isRequired: true)
          ),
          const SizedBox(height: 16), 
          _customTextField("Job Description", _jobDescCtrl, theme, maxLines: 2),
          const SizedBox(height: 16),
          _customTextField("Sub Job Description", _subJobDescCtrl, theme, maxLines: 2),
        ]);
      case 1: // FINANCIALS
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader("Financial Information", theme), const SizedBox(height: 16),
          _buildTwoColumnRow(_customTextField("Salary", _salaryCtrl, theme, icon: Icons.attach_money, isNumber: true, isSalary: true), _customTextField("Hourly Rate", _hourlyRateCtrl, theme, isNumber: true)), 
          const SizedBox(height: 16),
          _buildTwoColumnRow(_customTextField("Pending Commission", _lastMonthCommCtrl, theme, isNumber: true), _customTextField("IBAN", _ibanCtrl, theme, icon: Icons.account_balance)),
        ]);
      case 2: // CONTACT
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader("Contact Details (Optional)", theme), const SizedBox(height: 20), 
          _buildTwoColumnRow(_customTextField("Work Phone", _workPhoneCtrl, theme, icon: Icons.phone), _customTextField("Personal Mobile", _personalMobileCtrl, theme, icon: Icons.phone_android)), 
          const SizedBox(height: 16), 
          _customTextField("Personal Email", _personalEmailCtrl, theme, icon: Icons.email_outlined), 
          const SizedBox(height: 16), 
          _customTextField("Seating Location", _seatingLocationCtrl, theme, icon: Icons.chair), 
          const SizedBox(height: 16), 
          _customTextField("Present Address", _presentAddressCtrl, theme, icon: Icons.home, maxLines: 3), 
          const SizedBox(height: 16), 
          _customTextField("Permanent Address", _permanentAddressCtrl, theme, icon: Icons.location_city, maxLines: 3)
        ]);
      case 3: // WORK
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader("Work Information", theme), const SizedBox(height: 20),
          _buildTwoColumnRow(_customDropdown("Department", _departments, theme, (val) => setState(() => _selectedDepartment = val), isRequired: true), _customTextField("Location", _locationCtrl, theme, icon: Icons.place)),
          const SizedBox(height: 16),
          _buildTwoColumnRow(_customTextField("Designation", _designationCtrl, theme, icon: Icons.badge), _customTextField("Date of Joining", _dojCtrl, theme, icon: Icons.calendar_today, isDate: true)),
          const SizedBox(height: 16),
          _buildTwoColumnRow(_customDropdown("Emp Type", ["Permanent", "Contract", "Intern"], theme, (val) => setState(() => _employmentType = val)), _customDropdown("Emp Status", ["Active", "Probation", "Terminated"], theme, (val) => setState(() => _employeeStatus = val))),
          const SizedBox(height: 16),
          _buildTwoColumnRow(_customTextField("Current Exp.", _currExpCtrl, theme), _customTextField("Total Exp.", _totalExpCtrl, theme)),
          const SizedBox(height: 16),
          _customTextField("Source of Hire", _sourceOfHireCtrl, theme),
        ]);
      case 4: // PERSONAL
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader("Personal Details (Optional)", theme), const SizedBox(height: 20), 
          _buildTwoColumnRow(_customTextField("Date of Birth", _dobCtrl, theme, icon: Icons.cake, isDate: true), _customTextField("Age", _ageCtrl, theme, readOnly: true)), 
          const SizedBox(height: 16), 
          _customDropdown("Marital Status", ["Single", "Married", "Divorced"], theme, (val) => setState(() => _maritalStatus = val)), 
          const SizedBox(height: 16), 
          Text("Gender", style: TextStyle(color: theme.hintColor, fontSize: 12)), 
          Row(children: [_buildGenderRadio("Male", theme), const SizedBox(width: 20), _buildGenderRadio("Female", theme), const SizedBox(width: 20), _buildGenderRadio("Other", theme)]), 
          const SizedBox(height: 16), 
          _customTextField("About Me", _aboutMeCtrl, theme, maxLines: 3), 
          const SizedBox(height: 16), 
          _customTextField("Expertise", _expertiseCtrl, theme),
          const SizedBox(height: 32),
          Divider(color: theme.dividerColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          _sectionHeader("Hierarchy Information", theme), 
          const SizedBox(height: 20), 
          _buildTwoColumnRow(
            _employeeDropdown("Reporting Manager", _selectedReportingManagerId, theme, (val) => setState(() => _selectedReportingManagerId = val)), 
            _employeeDropdown("Secondary Manager", _selectedSecondaryManagerId, theme, (val) => setState(() => _selectedSecondaryManagerId = val))
          )
        ]);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildGenderRadio(String value, ThemeData theme) { 
    return Row(children: [
      Radio<String>(value: value, groupValue: _gender, activeColor: theme.primaryColor, onChanged: (val) => setState(() => _gender = val!)), 
      Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color))
    ]); 
  }

  Widget _buildTwoColumnRow(Widget left, Widget right) { return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 16), Expanded(child: right)]); }
  
  Widget _sectionHeader(String title, ThemeData theme) { 
    return Text(title, style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)); 
  }

  Widget _customTextField(String label, TextEditingController ctrl, ThemeData theme, {IconData? icon, bool isNumber = false, bool isSalary = false, bool isDate = false, int maxLines = 1, bool isRequired = false, bool readOnly = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl, 
      keyboardType: isNumber ? TextInputType.number : TextInputType.text, 
      inputFormatters: isSalary ? [ThousandsSeparatorInputFormatter()] : [], 
      maxLines: maxLines, 
      readOnly: readOnly || isDate, 
      validator: validator ?? (isRequired ? (val) => val == null || val.isEmpty ? 'Required' : null : null), 
      onTap: isDate ? () => _selectDate(ctrl, calcAge: label == 'Date of Birth') : null, 
      style: TextStyle(color: theme.textTheme.bodyLarge?.color), 
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: TextStyle(color: theme.hintColor), 
        prefixIcon: icon != null ? Icon(icon, color: theme.hintColor) : null, 
        suffixIcon: isDate && ctrl.text.isNotEmpty ? IconButton(icon: Icon(Icons.clear, color: theme.hintColor, size: 16), onPressed: () => ctrl.clear()) : null, 
        filled: true, 
        fillColor: theme.brightness == Brightness.dark ? const Color(0xFF2C2C2C) : theme.scaffoldBackgroundColor, 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
      )
    );
  }

  Widget _customDropdown(String label, List<String> items, ThemeData theme, Function(String?) onChanged, {bool isRequired = false}) {
    String? initialVal;
    if (label == 'System Access') initialVal = _systemRole;
    else initialVal = items.contains(_getValueForLabel(label)) ? _getValueForLabel(label) : null;

    return DropdownButtonFormField<String>(
      value: initialVal, 
      dropdownColor: theme.cardColor, 
      validator: isRequired ? (val) => val == null ? 'Required' : null : null, 
      style: TextStyle(color: theme.textTheme.bodyLarge?.color), 
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: TextStyle(color: theme.hintColor), 
        filled: true, 
        fillColor: theme.brightness == Brightness.dark ? const Color(0xFF2C2C2C) : theme.scaffoldBackgroundColor, 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
      ), 
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), 
      onChanged: onChanged
    );
  }

  String? _getValueForLabel(String label) {
    if (label == 'Department') return _selectedDepartment;
    if (label == 'Emp Type') return _employmentType;
    if (label == 'Emp Status') return _employeeStatus;
    if (label == 'Marital Status') return _maritalStatus;
    return null;
  }

  Widget _employeeDropdown(String label, String? selectedId, ThemeData theme, Function(String?) onChanged) {
    final Set<String> seenIds = {}; 
    final List<DropdownMenuItem<String>> dropdownItems = []; 
    for (var emp in _employeeList) { 
      if ((emp.role == 'admin' || emp.role == 'manager') && !seenIds.contains(emp.id)) { 
        seenIds.add(emp.id); 
        dropdownItems.add(DropdownMenuItem(value: emp.id, child: Text(emp.fullName.isNotEmpty ? emp.fullName : emp.email))); 
      } 
    } 
    String? validId = (selectedId != null && seenIds.contains(selectedId)) ? selectedId : null;
    return DropdownButtonFormField<String>(
      value: validId, 
      dropdownColor: theme.cardColor, 
      style: TextStyle(color: theme.textTheme.bodyLarge?.color), 
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: TextStyle(color: theme.hintColor), 
        filled: true, 
        fillColor: theme.brightness == Brightness.dark ? const Color(0xFF2C2C2C) : theme.scaffoldBackgroundColor, 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
      ), 
      items: dropdownItems, 
      onChanged: onChanged
    );
  }

  Widget _buildCustomStepperHeader(ThemeData theme) { 
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, 
      padding: const EdgeInsets.symmetric(horizontal: 16), 
      child: Row(children: List.generate(_totalSteps, (index) { 
        bool isActive = index == _currentStep; 
        bool isCompleted = index < _currentStep; 
        return Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300), 
            width: 36, height: 36, 
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              color: isActive || isCompleted ? theme.primaryColor : Colors.transparent, 
              border: Border.all(color: isActive || isCompleted ? theme.primaryColor : theme.hintColor, width: 2)
            ), 
            child: Center(child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 20) : Text("${index + 1}", style: TextStyle(color: isActive ? Colors.white : theme.hintColor, fontWeight: FontWeight.bold)))
          ), 
          const SizedBox(width: 8), 
          if (isActive) Text(_stepTitles[index], style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 14)), 
          if (index < _totalSteps - 1) Container(width: 40, height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), color: isCompleted ? theme.primaryColor : theme.dividerColor)
        ]); 
      }))
    ); 
  }

  Widget _buildBottomNavigation(ThemeData theme) { 
    return Container(
      padding: const EdgeInsets.all(16), 
      color: theme.scaffoldBackgroundColor, 
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        if (_currentStep > 0) OutlinedButton(
          onPressed: () => setState(() => _currentStep--), 
          style: OutlinedButton.styleFrom(side: BorderSide(color: theme.hintColor), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), 
          child: Text("Back", style: TextStyle(color: theme.textTheme.bodyLarge?.color))
        ) else const SizedBox(), 
        ElevatedButton(
          onPressed: () => _currentStep < _totalSteps - 1 ? setState(() => _currentStep++) : _submitOnboarding(), 
          style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)), 
          child: Text(widget.userToEdit != null ? "Update" : (_currentStep == _totalSteps - 1 ? "Finish" : "Next"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
        )
      ])
    ); 
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    
    // Remove existing commas to get the raw number
    final String cleanText = newValue.text.replaceAll(',', '');
    final double? value = double.tryParse(cleanText);
    
    if (value == null) return oldValue;

    // Format with commas
    final String newText = NumberFormat("#,##0").format(value);
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}