class UserModel {
  // System Fields
  final String id; // This is the user_id (e.g., 7)
  final String email;
  final String password;
  final String role;
  final bool mustChangePassword;
  final bool isActive; // Whether the account is enabled (is_active = 1)
  
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

  // -- CLIENT SPECIFIC --
  final String? companyName;
  final String? industry;
  final String? servicesNeeded;

  // -- OFFICE / GEOFENCE --
  final String? officeId;
  final String? officeName;

  // -- HIERARCHY --
  final String? reportingManager; // ID
  final String? reportingManagerName; // Name
  final String? secondaryReportingManager; // ID
  final String? secondaryReportingManagerName; // Name

  UserModel({
    required this.id, required this.email, required this.password,
    this.role = "employee", this.mustChangePassword = true,
    this.isActive = true,
    this.directReportsCount = 0, 
    this.firstName, this.lastName, this.nickName, this.employeeId, this.employeeCode, this.profilePicture,
    this.salary, this.lastMonthCommission, this.employeeHourlyRate, this.iban,
    this.dateOfBirth, this.gender, this.maritalStatus, this.aboutMe, this.expertise,
    this.workPhoneNumber, this.extension, this.personalMobileNumber, this.personalEmailAddress,
    this.seatingLocation, this.presentAddress, this.permanentAddress,
    this.department, this.location, this.designation, this.dateOfJoining,
    this.employmentType, this.employeeStatus, this.sourceOfHire,
    this.currentExperience, this.totalExperience, this.jobDescription, this.subJobDescription,
    this.reportingManager, this.reportingManagerName, this.secondaryReportingManager, this.secondaryReportingManagerName,
    this.companyName, this.industry, this.servicesNeeded,
    this.officeId, this.officeName,
  });

  bool get isManager => role == 'admin' || role == 'manager' || directReportsCount > 0;

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

  factory UserModel.empty() {
    return UserModel(
      id: '',
      email: '',
      password: '',
      role: 'employee',
      mustChangePassword: true,
      firstName: '',
      lastName: '',
    );
  }

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
      isActive: _parseBool(m['is_active'], defaultVal: true),
      directReportsCount: int.tryParse(m['direct_reports_count']?.toString() ?? '0') ?? 0,
      
      firstName: m['first_name'] ?? m['name'], 
      lastName: m['last_name'] ?? '', 
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
      secondaryReportingManagerName: m['secondary_reporting_manager_name'],
      companyName: m['company_name'] ?? m['companyName'],
      industry: m['industry'],
      servicesNeeded: m['services_needed'] ?? m['servicesNeeded'],
      officeId: m['office_id']?.toString(),
      officeName: m['office_name'],
    );
  }

  // Utility: handles bool/int/String from PHP
  static bool _parseBool(dynamic val, {bool defaultVal = false}) {
    if (val == null) return defaultVal;
    if (val is bool) return val;
    if (val is int) return val == 1;
    if (val is String) return val == '1' || val.toLowerCase() == 'true';
    return defaultVal;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': id,
      'user_id': id,
      'email': email,
      'role': role,
      'must_change_password': mustChangePassword,
      'is_active': isActive ? 1 : 0,
      'direct_reports_count': directReportsCount,

      // EMPLOYEES TABLE
      // Backend PHP reads 'employeeId' for employee_code column
      'employeeId': employeeId,     // camelCase key for PHP backend
      'employee_id': employeeId,    // snake_case fallback
      'employee_code': employeeCode,
      'first_name': firstName,
      'last_name': lastName,
      'nick_name': nickName,
      'profile_picture': profilePicture,

      // FINANCIALS
      'salary': salary,
      'hourly_rate': employeeHourlyRate,
      'employeeHourlyRate': employeeHourlyRate,
      'last_month_commission': lastMonthCommission,
      'lastMonthCommission': lastMonthCommission,
      'iban': iban,

      // WORK INFO
      'department': department,
      'location': location,
      'designation': designation,
      'date_of_joining': dateOfJoining,
      'dateOfJoining': dateOfJoining,
      'employment_type': employmentType,
      'employmentType': employmentType,
      'employee_status': employeeStatus,
      'employeeStatus': employeeStatus,
      'source_of_hire': sourceOfHire,
      'sourceOfHire': sourceOfHire,
      'current_experience': currentExperience,
      'currentExperience': currentExperience,
      'total_experience': totalExperience,
      'totalExperience': totalExperience,
      'job_description': jobDescription,
      'jobDescription': jobDescription,
      'sub_job_description': subJobDescription,
      'subJobDescription': subJobDescription,

      // PERSONAL DETAILS
      'date_of_birth': dateOfBirth,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'marital_status': maritalStatus,
      'maritalStatus': maritalStatus,
      'about_me': aboutMe,
      'aboutMe': aboutMe,
      'expertise': expertise,

      // CONTACT DETAILS
      'work_phone': workPhoneNumber,
      'workPhoneNumber': workPhoneNumber,
      'extension': extension,
      'personal_mobile': personalMobileNumber,
      'personalMobileNumber': personalMobileNumber,
      'personal_email': personalEmailAddress,
      'personalEmailAddress': personalEmailAddress,
      'seating_location': seatingLocation,
      'seatingLocation': seatingLocation,
      'present_address': presentAddress,
      'presentAddress': presentAddress,
      'permanent_address': permanentAddress,
      'permanentAddress': permanentAddress,

      // HIERARCHY
      'reporting_manager_id': reportingManager,
      'reportingManager': reportingManager,
      'secondary_reporting_manager_id': secondaryReportingManager,
      'secondaryReportingManager': secondaryReportingManager,
      'secondary_reporting_manager_name': secondaryReportingManagerName,
      'secondaryReportingManagerName': secondaryReportingManagerName,

      // CLIENT SPECIFIC
      'company_name': companyName,
      'companyName': companyName,
      'industry': industry,
      'services_needed': servicesNeeded,
      'servicesNeeded': servicesNeeded,
      'office_id': officeId,
      'officeId': officeId,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? password,
    String? role,
    bool? mustChangePassword,
    bool? isActive,
    int? directReportsCount,
    String? firstName,
    String? lastName,
    String? nickName,
    String? employeeId,
    String? employeeCode,
    String? profilePicture,
    double? salary,
    double? lastMonthCommission,
    double? employeeHourlyRate,
    String? iban,
    String? dateOfBirth,
    String? gender,
    String? maritalStatus,
    String? aboutMe,
    String? expertise,
    String? workPhoneNumber,
    String? extension,
    String? personalMobileNumber,
    String? personalEmailAddress,
    String? seatingLocation,
    String? presentAddress,
    String? permanentAddress,
    String? department,
    String? location,
    String? designation,
    String? dateOfJoining,
    String? employmentType,
    String? employeeStatus,
    String? sourceOfHire,
    String? currentExperience,
    String? totalExperience,
    String? jobDescription,
    String? subJobDescription,
    String? reportingManager,
    String? reportingManagerName,
    String? secondaryReportingManager,
    String? secondaryReportingManagerName,
    String? companyName,
    String? industry,
    String? servicesNeeded,
    String? officeId,
    String? officeName,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      isActive: isActive ?? this.isActive,
      directReportsCount: directReportsCount ?? this.directReportsCount,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nickName: nickName ?? this.nickName,
      employeeId: employeeId ?? this.employeeId,
      employeeCode: employeeCode ?? this.employeeCode,
      profilePicture: profilePicture ?? this.profilePicture,
      salary: salary ?? this.salary,
      lastMonthCommission: lastMonthCommission ?? this.lastMonthCommission,
      employeeHourlyRate: employeeHourlyRate ?? this.employeeHourlyRate,
      iban: iban ?? this.iban,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      aboutMe: aboutMe ?? this.aboutMe,
      expertise: expertise ?? this.expertise,
      workPhoneNumber: workPhoneNumber ?? this.workPhoneNumber,
      extension: extension ?? this.extension,
      personalMobileNumber: personalMobileNumber ?? this.personalMobileNumber,
      personalEmailAddress: personalEmailAddress ?? this.personalEmailAddress,
      seatingLocation: seatingLocation ?? this.seatingLocation,
      presentAddress: presentAddress ?? this.presentAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      department: department ?? this.department,
      location: location ?? this.location,
      designation: designation ?? this.designation,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
      employmentType: employmentType ?? this.employmentType,
      employeeStatus: employeeStatus ?? this.employeeStatus,
      sourceOfHire: sourceOfHire ?? this.sourceOfHire,
      currentExperience: currentExperience ?? this.currentExperience,
      totalExperience: totalExperience ?? this.totalExperience,
      jobDescription: jobDescription ?? this.jobDescription,
      subJobDescription: subJobDescription ?? this.subJobDescription,
      reportingManager: reportingManager ?? this.reportingManager,
      reportingManagerName: reportingManagerName ?? this.reportingManagerName,
      secondaryReportingManager: secondaryReportingManager ?? this.secondaryReportingManager,
      secondaryReportingManagerName: secondaryReportingManagerName ?? this.secondaryReportingManagerName,
      companyName: companyName ?? this.companyName,
      industry: industry ?? this.industry,
      servicesNeeded: servicesNeeded ?? this.servicesNeeded,
      officeId: officeId ?? this.officeId,
      officeName: officeName ?? this.officeName,
    );
  }
}