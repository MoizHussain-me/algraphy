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

class RegistrationFormView extends StatefulWidget {
  final UserModel? userToEdit; 
  const RegistrationFormView({super.key, this.userToEdit});

  @override
  State<RegistrationFormView> createState() => _RegistrationFormViewState();
}

class _RegistrationFormViewState extends State<RegistrationFormView> {
  final _formKey = GlobalKey<FormState>();

  List<String> _departments = []; 
  List<UserModel> _employeeList = []; 
  List<Map<String, dynamic>> _officeList = [];
  bool _isLoadingData = true;
  bool _isSubmitting = false;

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
  String? _selectedOfficeId;

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

  // --- FOCUS NODES ---
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _nickNameFocus = FocusNode();
  final _empIdFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _jobDescFocus = FocusNode();
  final _subJobDescFocus = FocusNode();
  
  final _salaryFocus = FocusNode();
  final _hourlyRateFocus = FocusNode();
  final _lastMonthCommFocus = FocusNode();
  final _ibanFocus = FocusNode();

  final _designationFocus = FocusNode();
  final _currExpFocus = FocusNode();
  final _totalExpFocus = FocusNode();
  final _sourceOfHireFocus = FocusNode();

  final _workPhoneFocus = FocusNode();
  final _extFocus = FocusNode();
  final _personalMobileFocus = FocusNode();
  final _personalEmailFocus = FocusNode();
  final _seatingLocationFocus = FocusNode();
  final _presentAddressFocus = FocusNode();
  final _permanentAddressFocus = FocusNode();

  final _aboutMeFocus = FocusNode();
  final _expertiseFocus = FocusNode();

  String? _newProfilePicPath; // Only for fresh local picks
  Uint8List? _profilePicBytes; // Only for fresh web picks

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Dispose all controllers
    _empIdCtrl.dispose(); _firstNameCtrl.dispose(); _lastNameCtrl.dispose(); _nickNameCtrl.dispose();
    _emailCtrl.dispose(); _jobDescCtrl.dispose(); _subJobDescCtrl.dispose(); _salaryCtrl.dispose();
    _lastMonthCommCtrl.dispose(); _hourlyRateCtrl.dispose(); _ibanCtrl.dispose(); _locationCtrl.dispose();
    _designationCtrl.dispose(); _dojCtrl.dispose(); _currExpCtrl.dispose(); _totalExpCtrl.dispose();
    _sourceOfHireCtrl.dispose(); _dobCtrl.dispose(); _ageCtrl.dispose(); _aboutMeCtrl.dispose();
    _expertiseCtrl.dispose(); _workPhoneCtrl.dispose(); _extCtrl.dispose(); _personalMobileCtrl.dispose();
    _personalEmailCtrl.dispose(); _seatingLocationCtrl.dispose(); _presentAddressCtrl.dispose(); _permanentAddressCtrl.dispose();
    
    // Dispose FocusNodes
    _firstNameFocus.dispose(); _lastNameFocus.dispose(); _nickNameFocus.dispose(); _empIdFocus.dispose();
    _emailFocus.dispose(); _jobDescFocus.dispose(); _subJobDescFocus.dispose();
    _salaryFocus.dispose(); _hourlyRateFocus.dispose(); _lastMonthCommFocus.dispose(); _ibanFocus.dispose();
    _designationFocus.dispose(); _currExpFocus.dispose(); _totalExpFocus.dispose(); _sourceOfHireFocus.dispose();
    _workPhoneFocus.dispose(); _extFocus.dispose(); _personalMobileFocus.dispose(); _personalEmailFocus.dispose();
    _seatingLocationFocus.dispose(); _presentAddressFocus.dispose(); _permanentAddressFocus.dispose();
    _aboutMeFocus.dispose(); _expertiseFocus.dispose();

    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    try {
      final repo = GetIt.I<AdminRepository>();
      final results = await Future.wait([
        repo.getDepartments(),
        repo.getAllEmployees(),
        repo.getOffices(),
      ]);
      
      if (mounted) {
        setState(() {
          _departments = results[0] as List<String>;
          _employeeList = results[1] as List<UserModel>;
          _officeList = results[2] as List<Map<String, dynamic>>;
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
    _selectedOfficeId = user.officeId?.toString();
    // NEVER set _newProfilePicPath from existing path (which is a server URL/path)
    if (mounted) setState(() {});
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _firstNameCtrl.clear(); _lastNameCtrl.clear(); _nickNameCtrl.clear(); _empIdCtrl.clear();
    _emailCtrl.clear(); _jobDescCtrl.clear(); _subJobDescCtrl.clear(); _salaryCtrl.clear();
    _lastMonthCommCtrl.clear(); _hourlyRateCtrl.clear(); _ibanCtrl.clear(); _locationCtrl.clear();
    _designationCtrl.clear(); _dojCtrl.clear(); _currExpCtrl.clear(); _totalExpCtrl.clear();
    _sourceOfHireCtrl.clear(); _dobCtrl.clear(); _ageCtrl.clear(); _aboutMeCtrl.clear();
    _expertiseCtrl.clear(); _workPhoneCtrl.clear(); _extCtrl.clear(); _personalMobileCtrl.clear();
    _personalEmailCtrl.clear(); _seatingLocationCtrl.clear(); _presentAddressCtrl.clear(); _permanentAddressCtrl.clear();
    setState(() {
      _newProfilePicPath = null;
      _profilePicBytes = null;
      _selectedDepartment = null;
      _selectedOfficeId = null;
      _selectedReportingManagerId = null;
      _selectedSecondaryManagerId = null;
      _employmentType = null;
      _employeeStatus = null;
      _maritalStatus = null;
      _gender = "Male";
    });
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    setState(() => _isSubmitting = true);

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
      officeId: _selectedOfficeId,
    );

    try {
      if (widget.userToEdit == null) {
        await GetIt.I<AdminRepository>().createEmployee(newUser, profilePicPath: _newProfilePicPath, profilePicBytes: _profilePicBytes);
      } else {
        await GetIt.I<AdminRepository>().updateEmployee(newUser, profilePicPath: _newProfilePicPath, profilePicBytes: _profilePicBytes);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Employee saved successfully"), backgroundColor: Colors.green));
        
        if (widget.userToEdit != null) {
          // If we are editing, we pushed this as a route, so pop.
          Navigator.pop(context, true);
        } else {
          // If we are registering (likely in a tab), don't pop (avoid white screen), just reset.
          _resetForm();
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _scrollToFirstError() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fix validaton errors"), backgroundColor: Colors.orange));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoadingData) return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2726)));

    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? const Color(0xFF0F0F0F) : theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
        //  _buildDraggableHeader(theme),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfilePicPicker(theme),
                    const SizedBox(height: 32),
                    
                    _buildSection(
                      title: "Basic Information",
                      icon: Icons.person_outline,
                      theme: theme,
                      children: [
                        _textFieldRow(
                          _customTextField("First Name", _firstNameCtrl, theme, isRequired: true, focusNode: _firstNameFocus, nextFocus: _lastNameFocus, autoFocus: true),
                          _customTextField("Last Name", _lastNameCtrl, theme, isRequired: true, focusNode: _lastNameFocus, nextFocus: _nickNameFocus),
                        ),
                        _fieldSpacer(),
                        _textFieldRow(
                          _customTextField("Nick Name", _nickNameCtrl, theme, focusNode: _nickNameFocus, nextFocus: _empIdFocus),
                          _customTextField(
                            "Employee ID", 
                            _empIdCtrl, 
                            theme, 
                            isRequired: true, 
                            icon: Icons.badge_outlined, 
                            focusNode: _empIdFocus, 
                            nextFocus: _emailFocus,
                            readOnly: widget.userToEdit == null, // Make read-only for new registrations
                            hint: widget.userToEdit == null ? "Select office to generate ID" : null,
                          ),
                        ),
                        _fieldSpacer(),
                        _textFieldRow(
                          _customTextField(
                            "Work Email", 
                            _emailCtrl, 
                            theme, 
                            isRequired: true, 
                            icon: Icons.email_outlined,
                            focusNode: _emailFocus,
                            nextFocus: _jobDescFocus,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(v)) return 'Invalid email';
                              return null;
                            },
                          ),
                          _customDropdown("System Access", ["employee", "manager", "admin"], theme, (val) => setState(() => _systemRole = val ?? "employee"), isRequired: true),
                        ),
                        _fieldSpacer(),
                        _customTextField("Job Description", _jobDescCtrl, theme, maxLines: 2, focusNode: _jobDescFocus, nextFocus: _subJobDescFocus),
                        _fieldSpacer(),
                        _customTextField("Sub Job Description", _subJobDescCtrl, theme, maxLines: 2, focusNode: _subJobDescFocus, nextFocus: _salaryFocus),
                      ],
                    ),

                    _sectionSpacer(),

                    _buildSection(
                      title: "Financial Information",
                      icon: Icons.account_balance_wallet_outlined,
                      theme: theme,
                      children: [
                        _textFieldRow(
                          _customTextField("Salary", _salaryCtrl, theme, icon: Icons.attach_money, isNumber: true, isSalary: true, focusNode: _salaryFocus, nextFocus: _hourlyRateFocus),
                          _customTextField("Hourly Rate", _hourlyRateCtrl, theme, isNumber: true, icon: Icons.timer_outlined, focusNode: _hourlyRateFocus, nextFocus: _lastMonthCommFocus),
                        ),
                        _fieldSpacer(),
                        _textFieldRow(
                          _customTextField("Pending Commission", _lastMonthCommCtrl, theme, isSalary: true, icon: Icons.trending_up, focusNode: _lastMonthCommFocus, nextFocus: _ibanFocus),
                          _customTextField("IBAN", _ibanCtrl, theme, icon: Icons.account_balance, isIBAN: true, focusNode: _ibanFocus, nextFocus: _designationFocus),
                        ),
                      ],
                    ),

                    _sectionSpacer(),

                    _buildSection(
                      title: "Work Information",
                      icon: Icons.work_outline,
                      theme: theme,
                      children: [
                        _textFieldRow(
                          _customDropdown("Department", _departments, theme, (val) => setState(() => _selectedDepartment = val), isRequired: true),
                          _officeDropdown("Assigned Office", _selectedOfficeId, theme, (val) => setState(() => _selectedOfficeId = val)),
                        ),
                        _fieldSpacer(),
                        _textFieldRow(
                          _customTextField("Designation", _designationCtrl, theme, icon: Icons.work_history_outlined, focusNode: _designationFocus, nextFocus: _currExpFocus),
                          _customTextField("Date of Joining", _dojCtrl, theme, icon: Icons.calendar_today_outlined, isDate: true),
                        ),
                        _fieldSpacer(),
                        _textFieldRow(
                          _customDropdown("Emp Type", ["Permanent", "Contract", "Intern"], theme, (val) => setState(() => _employmentType = val)),
                          _customDropdown("Emp Status", ["Active", "Probation", "Terminated"], theme, (val) => setState(() => _employeeStatus = val)),
                        ),
                        _fieldSpacer(),
                        _textFieldRow(
                          _customTextField("Current Exp.", _currExpCtrl, theme, focusNode: _currExpFocus, nextFocus: _totalExpFocus),
                          _customTextField("Total Exp.", _totalExpCtrl, theme, focusNode: _totalExpFocus, nextFocus: _sourceOfHireFocus),
                        ),
                        _fieldSpacer(),
                        _customTextField("Source of Hire", _sourceOfHireCtrl, theme, focusNode: _sourceOfHireFocus, nextFocus: _workPhoneFocus),
                      ],
                    ),

                    _sectionSpacer(),

                    _buildSection(
                      title: "Contact Details",
                      icon: Icons.contact_phone_outlined,
                      theme: theme,
                      children: [
                        _textFieldRow(
                          _customTextField(
                            "Work Phone", 
                            _workPhoneCtrl, 
                            theme, 
                            icon: Icons.phone_outlined,
                            isPhone: true,
                            focusNode: _workPhoneFocus,
                            nextFocus: _extFocus,
                            validator: (v) {
                              if (v != null && v.isNotEmpty && !RegExp(r"^[0-9 ]{7,15}$").hasMatch(v)) return 'Invalid phone';
                              return null;
                            },
                          ),
                          _customTextField("Extension", _extCtrl, theme, icon: Icons.phone_forwarded, isNumber: true, focusNode: _extFocus, nextFocus: _personalMobileFocus),
                        ),
                        _fieldSpacer(),
                        _textFieldRow(
                          _customTextField(
                            "Personal Mobile", 
                            _personalMobileCtrl, 
                            theme, 
                            isPhone: true,
                            focusNode: _personalMobileFocus,
                            nextFocus: _personalEmailFocus,
                            validator: (v) {
                              if (v != null && v.isNotEmpty && !RegExp(r"^[0-9 ]{7,15}$").hasMatch(v)) return 'Invalid mobile';
                              return null;
                            },
                          ),
                          _customTextField("Personal Email", _personalEmailCtrl, theme, icon: Icons.alternate_email, focusNode: _personalEmailFocus, nextFocus: _seatingLocationFocus),
                        ),
                        _fieldSpacer(),
                        _customTextField("Seating Location", _seatingLocationCtrl, theme, icon: Icons.chair_outlined, focusNode: _seatingLocationFocus, nextFocus: _presentAddressFocus),
                        _fieldSpacer(),
                        _customTextField("Present Address", _presentAddressCtrl, theme, icon: Icons.home_outlined, maxLines: 2, focusNode: _presentAddressFocus, nextFocus: _permanentAddressFocus),
                        _fieldSpacer(),
                        _customTextField("Permanent Address", _permanentAddressCtrl, theme, icon: Icons.location_city_outlined, maxLines: 2, focusNode: _permanentAddressFocus, nextFocus: _aboutMeFocus),
                      ],
                    ),

                    _sectionSpacer(),

                    _buildSection(
                      title: "Personal Details & Hierarchy",
                      icon: Icons.assignment_ind_outlined,
                      theme: theme,
                      children: [
                        _textFieldRow(
                          _customTextField("Date of Birth", _dobCtrl, theme, icon: Icons.cake_outlined, isDate: true),
                          _customTextField("Age", _ageCtrl, theme, readOnly: true),
                        ),
                        _fieldSpacer(),
                        _customDropdown("Marital Status", ["Single", "Married", "Divorced"], theme, (val) => setState(() => _maritalStatus = val)),
                        _fieldSpacer(),
                        Row(
                          children: [
                            Text("Gender: ", style: TextStyle(color: theme.hintColor, fontSize: 13)),
                            _buildGenderRadio("Male", theme),
                            _buildGenderRadio("Female", theme),
                            _buildGenderRadio("Other", theme),
                          ],
                        ),
                        _fieldSpacer(),
                        _customTextField("About Me", _aboutMeCtrl, theme, maxLines: 3, focusNode: _aboutMeFocus, nextFocus: _expertiseFocus),
                        _fieldSpacer(),
                        _customTextField("Expertise", _expertiseCtrl, theme, focusNode: _expertiseFocus),
                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 24),
                        _textFieldRow(
                          _employeeDropdown("Reporting Manager", _selectedReportingManagerId, theme, (val) => setState(() => _selectedReportingManagerId = val)), 
                          _employeeDropdown("Secondary Manager", _selectedSecondaryManagerId, theme, (val) => setState(() => _selectedSecondaryManagerId = val)),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 100), // Height for button
                  ],
                ),
              ),
            ),
          ),
          _buildBottomSubmit(theme),
        ],
      ),
    );
  }

  Widget _buildDraggableHeader(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text(
          widget.userToEdit == null ? "Register New Employee" : "Update Employee",
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildSection({required String title, required IconData icon, required ThemeData theme, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? const Color(0xFF1C1C1C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFDC2726), size: 20),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _textFieldRow(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }

  Widget _fieldSpacer() => const SizedBox(height: 16);
  Widget _sectionSpacer() => const SizedBox(height: 24);

  // --- WIDGET BUILDERS BORROWED & POLISHED FROM STEPPER ---

  Widget _buildProfilePicPicker(ThemeData theme) {
    ImageProvider? imageProvider;
    if (kIsWeb && _profilePicBytes != null) { 
      imageProvider = MemoryImage(_profilePicBytes!); 
    } 
    else if (!kIsWeb && _newProfilePicPath != null && _newProfilePicPath!.isNotEmpty) { 
      imageProvider = FileImage(io.File(_newProfilePicPath!)); 
    } 
    else if (widget.userToEdit?.profilePicture != null && widget.userToEdit!.profilePicture!.isNotEmpty) { 
      imageProvider = NetworkImage(ImageHelper.getFullUrl(widget.userToEdit!.profilePicture)); 
    }
    return Column(children: [
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () async { 
          final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true); 
          if (result != null) setState(() { 
            if (kIsWeb) {
              _profilePicBytes = result.files.single.bytes;
            } else {
              _newProfilePicPath = result.files.single.path;
            }
          }); 
        }, 
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDC2726), width: 2),
              ),
              child: CircleAvatar(
                radius: 54, 
                backgroundColor: const Color(0xFF2C2C2C), 
                backgroundImage: imageProvider, 
                child: imageProvider == null ? const Icon(Icons.person_add_alt_1_outlined, color: Colors.grey, size: 40) : null
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFDC2726), shape: BoxShape.circle),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ),
          ],
        )
      ), 
      const SizedBox(height: 12), 
      const Text("Profile Picture", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)), 
    ]);
  }

  Widget _buildGenderRadio(String value, ThemeData theme) { 
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Radio<String>(
        value: value, 
        groupValue: _gender, 
        activeColor: const Color(0xFFDC2726), 
        onChanged: (val) => setState(() => _gender = val!),
        visualDensity: VisualDensity.compact,
      ), 
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 13))
    ]); 
  }

  Widget _customTextField(String label, TextEditingController ctrl, ThemeData theme, {IconData? icon, bool isNumber = false, bool isSalary = false, bool isPhone = false, bool isIBAN = false, bool isDate = false, int maxLines = 1, bool isRequired = false, bool readOnly = false, bool autoFocus = false, FocusNode? focusNode, FocusNode? nextFocus, String? Function(String?)? validator, String? hint}) {
    List<TextInputFormatter> formatters = [];
    if (isNumber || isSalary || isPhone) formatters.add(FilteringTextInputFormatter.allow(RegExp(r'[0-9.SA ]'))); 
    if (isSalary) formatters.add(ThousandsSeparatorInputFormatter());
    if (isPhone) formatters.add(SaudiPhoneInputFormatter());
    if (isIBAN) formatters.add(SaudiIBANInputFormatter());

    return TextFormField(
      controller: ctrl, 
      focusNode: focusNode,
      autofocus: autoFocus,
      keyboardType: (isNumber || isSalary || isPhone || isIBAN) ? TextInputType.number : TextInputType.text, 
      textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (v) {
        if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
      },
      inputFormatters: formatters,
      maxLines: maxLines, 
      readOnly: readOnly || isDate, 
      validator: validator ?? (isRequired ? (val) => (val == null || val.trim().isEmpty) ? 'Required' : null : null), 
      onTap: isDate ? () => _selectDate(ctrl, calcAge: label == 'Date of Birth') : null, 
      style: const TextStyle(color: Colors.white, fontSize: 14), 
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 13), 
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey[600], size: 18) : null, 
        suffixIcon: (isDate || (isRequired && ctrl.text.isEmpty)) ? null : (ctrl.text.isEmpty ? null : IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 14), onPressed: () => setState(() => ctrl.clear()))), 
        filled: true, 
        fillColor: const Color(0xFF2C2C2C).withOpacity(0.5), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2726))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      )
    );
  }

  Widget _customDropdown(String label, List<String> items, ThemeData theme, Function(String?) onChanged, {bool isRequired = false}) {
    String? initialVal;
    if (label == 'System Access') initialVal = _systemRole;
    else initialVal = items.contains(_getValueForLabel(label)) ? _getValueForLabel(label) : null;

    return DropdownButtonFormField<String>(
      value: initialVal, 
      dropdownColor: const Color(0xFF1C1C1C), 
      validator: isRequired ? (val) => val == null ? 'Required' : null : null, 
      style: const TextStyle(color: Colors.white, fontSize: 14), 
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 13), 
        filled: true, 
        fillColor: const Color(0xFF2C2C2C).withOpacity(0.5), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      isExpanded: true,
      dropdownColor: const Color(0xFF1C1C1C), 
      style: const TextStyle(color: Colors.white, fontSize: 14), 
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 13), 
        filled: true, 
        fillColor: const Color(0xFF2C2C2C).withOpacity(0.5), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ), 
      items: dropdownItems, 
      onChanged: onChanged
    );
  }

  Widget _officeDropdown(String label, String? selectedId, ThemeData theme, Function(String?) onChanged) {
    final Set<String> seenIds = {};
    final List<DropdownMenuItem<String>> dropdownItems = [];
    for (var office in _officeList) {
      final id = office['id'].toString();
      if (!seenIds.contains(id)) {
        seenIds.add(id);
        dropdownItems.add(DropdownMenuItem(value: id, child: Text(office['name'] ?? 'Unknown')));
      }
    }
    String? validId = (selectedId != null && seenIds.contains(selectedId)) ? selectedId : null;
    return DropdownButtonFormField<String>(
      value: validId,
      isExpanded: true,
      dropdownColor: const Color(0xFF1C1C1C), 
      style: const TextStyle(color: Colors.white, fontSize: 14), 
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 13), 
        filled: true, 
        fillColor: const Color(0xFF2C2C2C).withOpacity(0.5), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ), 
      items: dropdownItems, 
      onChanged: (val) async {
        onChanged(val);
        if (val != null && widget.userToEdit == null) {
          // Auto-generate ID for new employees
          try {
            final repo = GetIt.I<AdminRepository>();
            final newId = await repo.generateEmployeeId(val);
            if (newId != null) {
              setState(() {
                _empIdCtrl.text = newId;
              });
            }
          } catch (e) {
            debugPrint("Error generating ID: $e");
          }
        }
      }
    );
  }

  Widget _buildBottomSubmit(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2726),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSubmitting 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    widget.userToEdit == null ? "Register Employee" : "Save Changes",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final String cleanText = newValue.text.replaceAll(',', '');
    final double? value = double.tryParse(cleanText);
    if (value == null) return oldValue;
    final String newText = NumberFormat("#,##0").format(value);
    return TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}

class SaudiPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 10) text = text.substring(0, 10);
    
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
       if (i == 3) formatted += ' ';
       if (i == 7) formatted += ' ';
       formatted += text[i];
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class SaudiIBANInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    
    // Ensure it starts with SA
    if (!text.startsWith('SA')) {
      if (text.length > 0 && 'SA'.startsWith(text)) {
        // partial match at start
      } else {
        text = 'SA' + text;
      }
    }
    
    if (text.length > 24) text = text.substring(0, 24);
    
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
       if (i > 0 && i % 4 == 0) formatted += ' ';
       formatted += text[i];
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
