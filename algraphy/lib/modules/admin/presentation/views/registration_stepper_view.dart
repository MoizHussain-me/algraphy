import 'package:flutter/material.dart';

class RegistrationStepperView extends StatefulWidget {
  const RegistrationStepperView({super.key});

  @override
  State<RegistrationStepperView> createState() => _RegistrationStepperViewState();
}

class _RegistrationStepperViewState extends State<RegistrationStepperView> {
  int _currentStep = 0;
  final int _totalSteps = 5; // Work, Basic, Hierarchy, Personal, Contact

  // Step Titles
  final List<String> _stepTitles = [
    "Work Info",
    "Basic Info",
    "Hierarchy",
    "Personal",
    "Contact"
  ];

  // --- Controllers ---
  
  // 1. Work Info
  final _departmentCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _dojCtrl = TextEditingController(); // Date of Joining
  String? _employmentType; // Dropdown
  String? _employeeStatus; // Dropdown

  // 2. Basic Info
  final _empIdCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();

  // 3. Hierarchy
  final _reportingManagerCtrl = TextEditingController(); // Should be dropdown later
  final _secondaryManagerCtrl = TextEditingController();

  // 4. Personal
  final _dobCtrl = TextEditingController();
  String? _gender; // Dropdown
  String? _maritalStatus; // Dropdown
  final _aboutMeCtrl = TextEditingController();

  // 5. Contact
  final _workPhoneCtrl = TextEditingController();
  final _personalMobileCtrl = TextEditingController();
  final _seatingLocationCtrl = TextEditingController();
  final _presentAddressCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    const Color backgroundDark = Color(0xFF080808);
    const Color cardColor = Color(0xFF1C1C1C);

    return Column(
      children: [
        const SizedBox(height: 20),
        // 1. Custom Horizontal Header
        _buildCustomStepperHeader(),
        
        const SizedBox(height: 20),
        
        // 2. Scrollable Form Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: SingleChildScrollView(
              child: _buildStepContent(_currentStep),
            ),
          ),
        ),

        // 3. Navigation Actions
        _buildBottomNavigation(),
      ],
    );
  }

  // --- Step Content Builder ---
  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("Work Information"),
            const SizedBox(height: 20),
            _buildTwoColumnRow(
              _customTextField("Department", _departmentCtrl, icon: Icons.business),
              _customTextField("Location", _locationCtrl, icon: Icons.place),
            ),
            const SizedBox(height: 16),
            _buildTwoColumnRow(
              _customTextField("Designation", _designationCtrl, icon: Icons.badge),
              _customTextField("Date of Joining", _dojCtrl, icon: Icons.calendar_today, isDate: true),
            ),
            const SizedBox(height: 16),
            _buildTwoColumnRow(
              _customDropdown("Employment Type", ["Permanent", "Contract", "Intern"], (val) => _employmentType = val),
              _customDropdown("Employee Status", ["Active", "Probation", "Terminated"], (val) => _employeeStatus = val),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("Basic Information"),
            const SizedBox(height: 20),
            _buildTwoColumnRow(
              _customTextField("First Name", _firstNameCtrl),
              _customTextField("Last Name", _lastNameCtrl),
            ),
            const SizedBox(height: 16),
            _buildTwoColumnRow(
              _customTextField("Employee ID", _empIdCtrl, icon: Icons.badge_outlined),
              _customTextField("Email Address", _emailCtrl, icon: Icons.email_outlined),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            _sectionHeader("Financials"),
            const SizedBox(height: 16),
            _buildTwoColumnRow(
              _customTextField("Salary", _salaryCtrl, icon: Icons.attach_money, isNumber: true),
              _customTextField("IBAN", _ibanCtrl, icon: Icons.account_balance),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("Hierarchy Information"),
            const SizedBox(height: 20),
            _buildTwoColumnRow(
              _customTextField("Reporting Manager", _reportingManagerCtrl, icon: Icons.supervisor_account),
              _customTextField("Secondary Manager", _secondaryManagerCtrl, icon: Icons.person_outline),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("Personal Details"),
            const SizedBox(height: 20),
            _buildTwoColumnRow(
              _customTextField("Date of Birth", _dobCtrl, icon: Icons.cake, isDate: true),
              _customDropdown("Gender", ["Male", "Female", "Other"], (val) => _gender = val),
            ),
            const SizedBox(height: 16),
            _customDropdown("Marital Status", ["Single", "Married", "Divorced"], (val) => _maritalStatus = val),
            const SizedBox(height: 16),
            _customTextField("About Me", _aboutMeCtrl, maxLines: 3),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("Contact Details"),
            const SizedBox(height: 20),
            _buildTwoColumnRow(
              _customTextField("Work Phone Number", _workPhoneCtrl, icon: Icons.phone_in_talk),
              _customTextField("Personal Mobile", _personalMobileCtrl, icon: Icons.phone_android),
            ),
            const SizedBox(height: 16),
            _customTextField("Seating Location", _seatingLocationCtrl, icon: Icons.chair),
            const SizedBox(height: 16),
            _customTextField("Present Address", _presentAddressCtrl, icon: Icons.home, maxLines: 3),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Helper for Split Rows ---
  Widget _buildTwoColumnRow(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }

  // --- UI Components ---

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _customTextField(
    String label, 
    TextEditingController ctrl, 
    {IconData? icon, bool isNumber = false, bool isDate = false, int maxLines = 1}
  ) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      readOnly: isDate, // Prevent manual typing for dates
      onTap: isDate ? () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1950),
          lastDate: DateTime(2100)
        );
        if(pickedDate != null) {
          // Format however you like, e.g. YYYY-MM-DD
          ctrl.text = pickedDate.toString().split(" ")[0]; 
        }
      } : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2726)),
        ),
      ),
    );
  }

  Widget _customDropdown(String label, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      dropdownColor: const Color(0xFF2C2C2C),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  // --- Header & Navigation (Zoho Style) ---

  Widget _buildCustomStepperHeader() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          bool isActive = index == _currentStep;
          bool isCompleted = index < _currentStep;
          bool isLast = index == _totalSteps - 1;

          return Row(
            children: [
              // Circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive || isCompleted ? const Color(0xFFDC2726) : Colors.transparent,
                  border: Border.all(
                    color: isActive || isCompleted ? const Color(0xFFDC2726) : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted 
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 8),
              // Title (Only show if active or on large screen logic)
              if (isActive) 
                Text(
                  _stepTitles[index],
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              
              // Line
              if (!isLast)
                Container(
                  width: 40,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: isCompleted ? const Color(0xFFDC2726) : Colors.grey[800],
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF080808),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Back", style: TextStyle(color: Colors.white)),
            )
          else
            const SizedBox(),

          ElevatedButton(
            onPressed: () {
              if (_currentStep < _totalSteps - 1) {
                setState(() => _currentStep++);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Onboarding Triggered Successfully!")),
                );
                // Here you would call your AuthRepository to save the full User Model
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2726),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
              _currentStep == _totalSteps - 1 ? "Finish" : "Next",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}