import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AdminCreateUserPage extends StatefulWidget {
  const AdminCreateUserPage({super.key});

  @override
  State<AdminCreateUserPage> createState() => _AdminCreateUserPageState();
}

class _AdminCreateUserPageState extends State<AdminCreateUserPage> {
  int _currentStep = 0;

  // Step 1: Work Info Controllers
  final departmentCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final designationCtrl = TextEditingController();
  String? employmentTypeValue;
  String? employeeStatusValue;
  final dateOfJoiningCtrl = TextEditingController();
  final currentExperienceCtrl = TextEditingController();
  final totalExperienceCtrl = TextEditingController();
  String? cvFileName;

  // Step 2: Basic Info Controllers
  final employeeIdCtrl = TextEditingController();
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final nickNameCtrl = TextEditingController();
  final salaryCtrl = TextEditingController();

  // Step 3: Hierarchy Controllers
  final reportingManagerCtrl = TextEditingController();
  final secondaryReportingManagerCtrl = TextEditingController();

  // Step 4: Personal Details Controllers
  final dateOfBirthCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  String? genderValue;
  String? maritalStatusValue;
  final aboutMeCtrl = TextEditingController();
  final expertiseCtrl = TextEditingController();
  String? familyDocFileName;

  final List<String> employmentTypes = ['Full-Time', 'Part-Time', 'Contract'];
  final List<String> employeeStatuses = ['Active', 'Probation', 'Inactive'];
  final List<String> genders = ['Male', 'Female', 'Other'];
  final List<String> maritalStatuses = ['Single', 'Married', 'Divorced'];

  Future<void> _pickFile(Function(String) onPicked) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      onPicked(result.files.single.name);
    }
  }

  List<Step> getSteps() => [
        Step(
          title: const Text('Work Info'),
          content: Column(
            children: [
              TextField(controller: departmentCtrl, decoration: const InputDecoration(labelText: 'Department')),
              TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location')),
              TextField(controller: designationCtrl, decoration: const InputDecoration(labelText: 'Designation')),
              DropdownButtonFormField<String>(
                value: employmentTypeValue,
                items: employmentTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => employmentTypeValue = v),
                decoration: const InputDecoration(labelText: 'Employment Type'),
              ),
              DropdownButtonFormField<String>(
                value: employeeStatusValue,
                items: employeeStatuses.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => employeeStatusValue = v),
                decoration: const InputDecoration(labelText: 'Employee Status'),
              ),
              TextField(
                controller: dateOfJoiningCtrl,
                decoration: const InputDecoration(labelText: 'Date of Joining'),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100));
                  if (date != null) {
                    dateOfJoiningCtrl.text = "${date.toLocal()}".split(' ')[0];
                  }
                },
              ),
              TextField(controller: currentExperienceCtrl, decoration: const InputDecoration(labelText: 'Current Experience')),
              TextField(controller: totalExperienceCtrl, decoration: const InputDecoration(labelText: 'Total Experience')),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _pickFile((name) => setState(() => cvFileName = name)),
                    child: const Text('Upload CV'),
                  ),
                  const SizedBox(width: 10),
                  Text(cvFileName ?? 'No file chosen'),
                ],
              ),
            ],
          ),
        ),
        Step(
          title: const Text('Basic Info'),
          content: Column(
            children: [
              TextField(controller: employeeIdCtrl, decoration: const InputDecoration(labelText: 'Employee ID')),
              TextField(controller: firstNameCtrl, decoration: const InputDecoration(labelText: 'First Name')),
              TextField(controller: lastNameCtrl, decoration: const InputDecoration(labelText: 'Last Name')),
              TextField(controller: nickNameCtrl, decoration: const InputDecoration(labelText: 'Nick Name')),
              TextField(controller: salaryCtrl, decoration: const InputDecoration(labelText: 'Salary')),
            ],
          ),
        ),
        Step(
          title: const Text('Hierarchy Info'),
          content: Column(
            children: [
              TextField(controller: reportingManagerCtrl, decoration: const InputDecoration(labelText: 'Reporting Manager')),
              TextField(controller: secondaryReportingManagerCtrl, decoration: const InputDecoration(labelText: 'Secondary Reporting Manager')),
            ],
          ),
        ),
        Step(
          title: const Text('Personal Details'),
          content: Column(
            children: [
              TextField(
                controller: dateOfBirthCtrl,
                decoration: const InputDecoration(labelText: 'Date of Birth'),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime(1990),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now());
                  if (date != null) dateOfBirthCtrl.text = "${date.toLocal()}".split(' ')[0];
                },
              ),
              TextField(controller: ageCtrl, decoration: const InputDecoration(labelText: 'Age')),
              DropdownButtonFormField<String>(
                value: genderValue,
                items: genders.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => genderValue = v),
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              DropdownButtonFormField<String>(
                value: maritalStatusValue,
                items: maritalStatuses.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => maritalStatusValue = v),
                decoration: const InputDecoration(labelText: 'Marital Status'),
              ),
              TextField(controller: aboutMeCtrl, decoration: const InputDecoration(labelText: 'About Me')),
              TextField(controller: expertiseCtrl, decoration: const InputDecoration(labelText: 'Expertise')),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _pickFile((name) => setState(() => familyDocFileName = name)),
                    child: const Text('Upload Family Doc'),
                  ),
                  const SizedBox(width: 10),
                  Text(familyDocFileName ?? 'No file chosen'),
                ],
              ),
            ],
          ),
        ),
      ];

  void _onStepContinue() {
    // Optional: Validate before continue
    if (_currentStep < getSteps().length - 1) {
      setState(() => _currentStep += 1);
    } else {
      _submit();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) setState(() => _currentStep -= 1);
  }

  void _submit() {
    // Collect all data and print (backend later)
    print('=== User Data ===');
    print('Work Info: Department: ${departmentCtrl.text}, Location: ${locationCtrl.text}');
    print('Basic Info: Name: ${firstNameCtrl.text} ${lastNameCtrl.text}, Employee ID: ${employeeIdCtrl.text}');
    print('Hierarchy: Reporting: ${reportingManagerCtrl.text}');
    print('Personal: DOB: ${dateOfBirthCtrl.text}, Gender: $genderValue');
    print('CV: $cvFileName, Family Doc: $familyDocFileName');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Created (UI only)')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Employee')),
      body: Stepper(
        currentStep: _currentStep,
        steps: getSteps(),
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        type: StepperType.vertical,
      ),
    );
  }
}
