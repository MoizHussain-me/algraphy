class UserModel {
  final String id;
  final String email;
  final String password;
  final String role;
  final bool mustChangePassword;

  // -- EMPLOYEES TABLE --
  final String? firstName;
  final String? lastName;
  final String? nickName;
  final String? employeeId;
  final String? profilePicture;

  // -- FINANCIALS TABLE --
  final double? salary;
  final double? lastMonthCommission;
  final double? employeeHourlyRate;
  final String? iban;

  // -- PERSONAL DETAILS TABLE --
  final String? dateOfBirth;
  final String? gender;
  final String? maritalStatus;
  final String? aboutMe;
  final String? expertise;

  // -- CONTACT DETAILS TABLE --
  final String? workPhoneNumber;
  final String? extension;
  final String? personalMobileNumber;
  final String? personalEmailAddress;
  final String? seatingLocation;
  final String? presentAddress;
  final String? permanentAddress;

  // -- WORK INFO TABLE --
  final String? department;
  final String? location;
  final String? designation;
  final String? dateOfJoining;
  final String? employmentType;
  final String? employeeStatus;
  final String? zohoRole;
  final String? sourceOfHire;
  final String? currentExperience;
  final String? totalExperience;
  final String? jobDescription;
  final String? subJobDescription;

  // -- HIERARCHY TABLE --
  final String? reportingManager;
  final String? secondaryReportingManager;

  UserModel({
    required this.id, required this.email, required this.password,
    this.role = "employee", this.mustChangePassword = true,
    this.firstName, this.lastName, this.nickName, this.employeeId, this.profilePicture,
    this.salary, this.lastMonthCommission, this.employeeHourlyRate, this.iban,
    this.dateOfBirth, this.gender, this.maritalStatus, this.aboutMe, this.expertise,
    this.workPhoneNumber, this.extension, this.personalMobileNumber, this.personalEmailAddress,
    this.seatingLocation, this.presentAddress, this.permanentAddress,
    this.department, this.location, this.designation, this.dateOfJoining,
    this.employmentType, this.employeeStatus, this.zohoRole, this.sourceOfHire,
    this.currentExperience, this.totalExperience, this.jobDescription, this.subJobDescription,
    this.reportingManager, this.secondaryReportingManager,
  });

  String get calculatedAge {
    if (dateOfBirth == null || dateOfBirth!.isEmpty) return "";
    try {
      final dob = DateTime.parse(dateOfBirth!);
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) age--;
      return "$age years";
    } catch (_) { return ""; }
  }

  String get fullName => "$firstName $lastName";

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'email': email, 'password': password, 'role': role, 'mustChangePassword': mustChangePassword,
      'firstName': firstName, 'lastName': lastName, 'nickName': nickName, 'employeeId': employeeId,
      'salary': salary, 'lastMonthCommission': lastMonthCommission, 'employeeHourlyRate': employeeHourlyRate, 'iban': iban,
      'dateOfBirth': dateOfBirth, 'gender': gender, 'maritalStatus': maritalStatus, 'aboutMe': aboutMe, 'expertise': expertise,
      'workPhoneNumber': workPhoneNumber, 'extension': extension, 'personalMobileNumber': personalMobileNumber,
      'personalEmailAddress': personalEmailAddress, 'seatingLocation': seatingLocation,
      'presentAddress': presentAddress, 'permanentAddress': permanentAddress,
      'department': department, 'location': location, 'designation': designation, 'dateOfJoining': dateOfJoining,
      'employmentType': employmentType, 'employeeStatus': employeeStatus, 'zohoRole': zohoRole,
      'sourceOfHire': sourceOfHire, 'currentExperience': currentExperience, 'totalExperience': totalExperience,
      'jobDescription': jobDescription, 'subJobDescription': subJobDescription,
      'reportingManager': reportingManager, 'secondaryReportingManager': secondaryReportingManager,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> m) {
    return UserModel(
      id: m['user_id']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
      password: '', role: m['role'] ?? 'employee',
      mustChangePassword: m['must_change_password'] == 1,
      firstName: m['first_name'], lastName: m['last_name'], nickName: m['nick_name'], employeeId: m['employee_code'],
      profilePicture: m['profile_picture'],
      salary: double.tryParse(m['salary']?.toString() ?? ''),
      lastMonthCommission: double.tryParse(m['last_month_commission']?.toString() ?? ''),
      employeeHourlyRate: double.tryParse(m['hourly_rate']?.toString() ?? ''),
      iban: m['iban'],
      dateOfBirth: m['date_of_birth'], gender: m['gender'], maritalStatus: m['marital_status'], aboutMe: m['about_me'], expertise: m['expertise'],
      workPhoneNumber: m['work_phone'], extension: m['extension'], personalMobileNumber: m['personal_mobile'],
      personalEmailAddress: m['personal_email'], seatingLocation: m['seating_location'],
      presentAddress: m['present_address'], permanentAddress: m['permanent_address'],
      department: m['department'], location: m['location'], designation: m['designation'], dateOfJoining: m['date_of_joining'],
      employmentType: m['employment_type'], employeeStatus: m['employee_status'], zohoRole: m['zoho_role'],
      sourceOfHire: m['source_of_hire'], currentExperience: m['current_experience'], totalExperience: m['total_experience'],
      jobDescription: m['job_description'], subJobDescription: m['sub_job_description'],
      reportingManager: m['reporting_manager_id']?.toString(), secondaryReportingManager: m['secondary_reporting_manager_id']?.toString(),
    );
  }
}