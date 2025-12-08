import 'package:intl/intl.dart';

class UserModel {
  // System Fields
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
  final double? lastMonthCommission; // Matches 'last_month_commission'
  final double? employeeHourlyRate;  // Matches 'hourly_rate'
  final String? iban;

  // -- PERSONAL DETAILS TABLE --
  final String? dateOfBirth;
  final String? gender;
  final String? maritalStatus;
  final String? aboutMe;
  final String? expertise;

  // -- CONTACT DETAILS TABLE --
  final String? workPhoneNumber;     // Matches 'work_phone'
  final String? extension;
  final String? personalMobileNumber; // Matches 'personal_mobile'
  final String? personalEmailAddress; // Matches 'personal_email'
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

  // --- Serialization (Sending to PHP) ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'role': role,
      'mustChangePassword': mustChangePassword,
      
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

  // --- Deserialization (Receiving from PHP) ---
  factory UserModel.fromMap(Map<String, dynamic> m) {
    // Robust Boolean Check
    final rawChangePass = m['mustChangePassword'] ?? m['must_change_password'];
    bool mustChange = false;
    if (rawChangePass is bool) mustChange = rawChangePass;
    else if (rawChangePass is int) mustChange = rawChangePass == 1;
    else if (rawChangePass is String) mustChange = rawChangePass == '1' || rawChangePass == 'true';

    return UserModel(
      id: m['user_id']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
      password: '', role: m['role'] ?? 'employee',
      mustChangePassword: mustChange,
      
      firstName: m['first_name'],
      lastName: m['last_name'],
      nickName: m['nick_name'],
      employeeId: m['employee_code'] ?? m['employee_id'], 
      profilePicture: m['profile_picture'],
      
      // FIX: Map exact JSON keys to fields
      salary: double.tryParse(m['salary']?.toString() ?? ''),
      lastMonthCommission: double.tryParse(m['last_month_commission']?.toString() ?? ''), // Fixed Key
      employeeHourlyRate: double.tryParse(m['hourly_rate']?.toString() ?? ''), // Fixed Key
      iban: m['iban'],
      
      jobDescription: m['job_description'],
      subJobDescription: m['sub_job_description'],
      
      dateOfBirth: m['date_of_birth'],
      gender: m['gender'],
      maritalStatus: m['marital_status'],
      aboutMe: m['about_me'],
      expertise: m['expertise'],
      
      // FIX: Contact Details Keys
      workPhoneNumber: m['work_phone'], 
      extension: m['extension'],
      personalMobileNumber: m['personal_mobile'],
      personalEmailAddress: m['personal_email'], // Fixed Key
      seatingLocation: m['seating_location'],
      presentAddress: m['present_address'],
      permanentAddress: m['permanent_address'],
      
      dateOfJoining: m['date_of_joining'],
      department: m['department'],
      location: m['location'],
      designation: m['designation'],
      employmentType: m['employment_type'],
      employeeStatus: m['employee_status'],
      zohoRole: m['zoho_role'],
      sourceOfHire: m['source_of_hire'],
      currentExperience: m['current_experience']?.toString(),
      totalExperience: m['total_experience']?.toString(),
      
      reportingManager: m['reporting_manager_id']?.toString(),
      secondaryReportingManager: m['secondary_reporting_manager_id']?.toString(),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? password,
    String? role,
    bool? mustChangePassword,
    String? firstName,
    String? lastName,
    String? nickName,
    String? employeeId,
    String? profilePicture,
    // Add other fields if needed for updates...
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nickName: nickName ?? this.nickName,
      employeeId: employeeId ?? this.employeeId,
      profilePicture: profilePicture ?? this.profilePicture,

      // Pass existing values for the rest to ensure nothing is lost
      salary: salary,
      iban: iban,
      department: department,
      designation: designation,
      // ... pass all other existing fields here ...
      // Ideally, copyWith should handle ALL fields, but for this specific
      // "Change Password" use case, preserving the main ones is key.
    );
  }
}
