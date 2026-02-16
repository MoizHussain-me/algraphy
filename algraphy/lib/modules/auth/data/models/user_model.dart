class UserModel {
  // System Fields
  final String id; // This is the user_id (e.g., 7)
  final String email;
  final String password;
  final String role;
  final bool mustChangePassword;
  
  // NEW: Hierarchy Logic
  final int directReportsCount;

  // -- EMPLOYEES TABLE --
  final String? firstName;
  final String? lastName;
  final String? nickName;
  final String? employeeId;   // THIS WILL BE THE PRIMARY KEY (e.g., 5)
  final String? employeeCode; // THIS WILL BE THE CODE (e.g., EMP-1001)
  final String? profilePicture;

  // -- FINANCIALS --
  final double? salary;
  final double? lastMonthCommission; 
  final double? employeeHourlyRate;
  final String? iban;

  // -- PERSONAL --
  final String? dateOfBirth; 
  final String? gender;
  final String? maritalStatus;
  final String? aboutMe;
  final String? expertise;

  // -- CONTACT --
  final String? workPhoneNumber;
  final String? extension;
  final String? personalMobileNumber;
  final String? personalEmailAddress;
  final String? seatingLocation;
  final String? presentAddress;
  final String? permanentAddress;

  // -- WORK --
  final String? department;
  final String? location;
  final String? designation;
  final String? dateOfJoining;
  final String? employmentType;
  final String? employeeStatus;
  final String? sourceOfHire;
  final String? currentExperience;
  final String? totalExperience;
  final String? jobDescription;
  final String? subJobDescription;

  // -- HIERARCHY --
  final String? reportingManager; // ID
  final String? reportingManagerName; // Name
  final String? secondaryReportingManager; // ID

  UserModel({
    required this.id, required this.email, required this.password,
    this.role = "employee", this.mustChangePassword = true,
    this.directReportsCount = 0, 
    this.firstName, this.lastName, this.nickName, this.employeeId, this.employeeCode, this.profilePicture,
    this.salary, this.lastMonthCommission, this.employeeHourlyRate, this.iban,
    this.dateOfBirth, this.gender, this.maritalStatus, this.aboutMe, this.expertise,
    this.workPhoneNumber, this.extension, this.personalMobileNumber, this.personalEmailAddress,
    this.seatingLocation, this.presentAddress, this.permanentAddress,
    this.department, this.location, this.designation, this.dateOfJoining,
    this.employmentType, this.employeeStatus, this.sourceOfHire,
    this.currentExperience, this.totalExperience, this.jobDescription, this.subJobDescription,
    this.reportingManager, this.reportingManagerName, this.secondaryReportingManager,
  });

  bool get isManager => role == 'admin' || directReportsCount > 0;

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

  factory UserModel.fromMap(Map<String, dynamic> m) {
    final rawChangePass = m['mustChangePassword'] ?? m['must_change_password'];
    bool mustChange = false;
    if (rawChangePass is bool) mustChange = rawChangePass;
    else if (rawChangePass is int) mustChange = rawChangePass == 1;
    else if (rawChangePass is String) mustChange = rawChangePass == '1' || rawChangePass == 'true';

    return UserModel(
      // SYSTEM ID (User ID)
      id: m['userId']?.toString() ?? m['user_id']?.toString() ?? m['id']?.toString() ?? '', 
      
      email: m['email']?.toString() ?? '',     
      password: '', 
      role: m['role'] ?? 'employee',
      mustChangePassword: mustChange,
      directReportsCount: int.tryParse(m['direct_reports_count']?.toString() ?? '0') ?? 0,
      
      firstName: m['first_name'], 
      lastName: m['last_name'], 
      nickName: m['nick_name'], 

      // Numeric PK of employees table
      employeeId: m['employee_id']?.toString() ?? m['id']?.toString(), 

      // Visible code (e.g., EMP-1001)
      employeeCode: m['employee_code']?.toString() ?? m['employeeId']?.toString(), 
      
      profilePicture: m['profile_picture'],
      salary: double.tryParse(m['salary']?.toString() ?? ''),
      lastMonthCommission: double.tryParse(m['last_month_commission']?.toString() ?? ''),
      employeeHourlyRate: double.tryParse(m['hourly_rate']?.toString() ?? ''),
      iban: m['iban'],
      jobDescription: m['job_description'], 
      subJobDescription: m['sub_job_description'],
      dateOfBirth: m['date_of_birth'], 
      gender: m['gender'], 
      maritalStatus: m['marital_status'], 
      aboutMe: m['about_me'], 
      expertise: m['expertise'],
      workPhoneNumber: m['work_phone'], 
      extension: m['extension'], 
      personalMobileNumber: m['personal_mobile'],
      personalEmailAddress: m['personal_email'], 
      seatingLocation: m['seating_location'],
      presentAddress: m['present_address'], 
      permanentAddress: m['permanent_address'],
      dateOfJoining: m['date_of_joining'], 
      department: m['department'], 
      location: m['location'], 
      designation: m['designation'],
      employmentType: m['employment_type'], 
      employeeStatus: m['employee_status'],
      sourceOfHire: m['source_of_hire'], 
      currentExperience: m['current_experience']?.toString(), 
      totalExperience: m['total_experience']?.toString(),
      reportingManager: m['reporting_manager_id']?.toString(),
      reportingManagerName: m['reporting_manager_name'],
      secondaryReportingManager: m['secondary_reporting_manager_id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': id,
      'user_id': id,
      'email': email,
      'role': role,
      'must_change_password': mustChangePassword,
      'direct_reports_count': directReportsCount,
      
      // EMPLOYEES TABLE
      'employee_id': employeeId,
      'employee_code': employeeCode,
      'first_name': firstName,
      'last_name': lastName,
      'nick_name': nickName,
      'profile_picture': profilePicture,

      // OTHER FIELDS
      'salary': salary,
      'hourly_rate': employeeHourlyRate,
      'last_month_commission': lastMonthCommission,
      'iban': iban,
      'department': department,
      'location': location,
      'designation': designation,
      'date_of_joining': dateOfJoining,
      'employment_type': employmentType,
      'employee_status': employeeStatus,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'marital_status': maritalStatus,
      'reporting_manager_id': reportingManager,
      'secondary_reporting_manager_id': secondaryReportingManager,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? password,
    String? role,
    bool? mustChangePassword,
    int? directReportsCount,
    String? firstName,
    String? lastName,
    String? nickName,
    String? employeeId,
    String? employeeCode,
    String? profilePicture,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      directReportsCount: directReportsCount ?? this.directReportsCount,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nickName: nickName ?? this.nickName,
      employeeId: employeeId ?? this.employeeId,
      employeeCode: employeeCode ?? this.employeeCode,
      profilePicture: profilePicture ?? this.profilePicture,
      salary: salary,
      iban: iban,
      department: department,
      designation: designation,
    );
  }
}