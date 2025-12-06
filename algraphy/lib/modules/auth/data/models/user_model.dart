class UserModel {
  // --- System & Auth Fields ---
  final String id;
  final String email;
  final String password; // Plain text for demo/local (Hash in real backend)
  final String role; // "admin" or "employee"
  final bool mustChangePassword;
  final String onboardingStatus; // "Not Triggered", "In Progress", "Completed"
  final String? addedBy;
  final String? addedTime;
  final String? modifiedBy;
  final String? modifiedTime;

  // --- 1. Basic Information ---
  final String? employeeId; // e.g. JED-2035
  final String? firstName;
  final String? lastName;
  final String? nickName;
  final String? emailAddress; // Work email
  final String? jobDescription;
  final String? subJobDescription;
  
  // -- Financials --
  final double? salary;
  final double? lastMonthCommission;
  final double? employeeHourlyRate;
  final double? testingSingleLineHoursRate;
  final String? iban;

  // -- Uploads --
  final String? idDocument; // Path/URL
  final String? passport;   // Path/URL
  final String? contract;   // Path/URL

  // --- 2. Work Information ---
  final String? department;
  final String? location;
  final String? designation;
  final String? zohoRole; // "Team Member", "Admin"
  final String? employmentType; // "Permanent", "Contract"
  final String? employeeStatus; // "Active", "Probation"
  final String? sourceOfHire;
  final String? dateOfJoining;
  final String? currentExperience;
  final String? totalExperience;
  final String? cv;       // Path/URL
  final String? jobOffer; // Path/URL
  final List<String>? otherFiles;

  // --- 3. Hierarchy Information ---
  final String? reportingManager; // Store ID or Name
  final String? secondaryReportingManager;

  // --- 4. Personal Details ---
  final String? dateOfBirth;
  final String? age; // Can be string "29 years 1 month" or calculated
  final String? gender;
  final String? maritalStatus;
  final String? aboutMe;
  final String? expertise;
  final String? familyDoc; // Path/URL

  // --- 5. Contact Details ---
  final String? workPhoneNumber;
  final String? extension;
  final String? personalMobileNumber;
  final String? personalEmailAddress;
  final String? seatingLocation;
  final String? tags;
  final String? presentAddress;
  final String? permanentAddress;

  // --- 6. Separation Information ---
  final String? dateOfExit;

  // --- 7. Identity Information ---
  final String? iqamaExpire; // Specific to your screenshot

  UserModel({
    required this.id,
    required this.email,
    required this.password,
    this.role = "employee",
    this.mustChangePassword = true,
    this.onboardingStatus = "Not Triggered",
    this.addedBy,
    this.addedTime,
    this.modifiedBy,
    this.modifiedTime,
    this.employeeId,
    this.firstName,
    this.lastName,
    this.nickName,
    this.emailAddress,
    this.jobDescription,
    this.subJobDescription,
    this.salary,
    this.lastMonthCommission,
    this.employeeHourlyRate,
    this.testingSingleLineHoursRate,
    this.iban,
    this.idDocument,
    this.passport,
    this.contract,
    this.department,
    this.location,
    this.designation,
    this.zohoRole,
    this.employmentType,
    this.employeeStatus,
    this.sourceOfHire,
    this.dateOfJoining,
    this.currentExperience,
    this.totalExperience,
    this.cv,
    this.jobOffer,
    this.otherFiles,
    this.reportingManager,
    this.secondaryReportingManager,
    this.dateOfBirth,
    this.age,
    this.gender,
    this.maritalStatus,
    this.aboutMe,
    this.expertise,
    this.familyDoc,
    this.workPhoneNumber,
    this.extension,
    this.personalMobileNumber,
    this.personalEmailAddress,
    this.seatingLocation,
    this.tags,
    this.presentAddress,
    this.permanentAddress,
    this.dateOfExit,
    this.iqamaExpire,
  });

  // --- Helper to get Full Name ---
  String get fullName => "$firstName $lastName";

  // --- Serialization (Map -> Object) ---
  factory UserModel.fromMap(Map<String, dynamic> m) {
    return UserModel(
      id: m['id']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
      password: m['password']?.toString() ?? '',
      role: m['role']?.toString() ?? 'employee',
      mustChangePassword: m['mustChangePassword'] == 1 || m['mustChangePassword'] == true,
      onboardingStatus: m['onboardingStatus']?.toString() ?? 'Not Triggered',
      addedBy: m['addedBy'],
      addedTime: m['addedTime'],
      modifiedBy: m['modifiedBy'],
      modifiedTime: m['modifiedTime'],
      employeeId: m['employeeId'],
      firstName: m['firstName'],
      lastName: m['lastName'],
      nickName: m['nickName'],
      emailAddress: m['emailAddress'],
      jobDescription: m['jobDescription'],
      subJobDescription: m['subJobDescription'],
      salary: double.tryParse(m['salary'].toString()),
      lastMonthCommission: double.tryParse(m['lastMonthCommission'].toString()),
      employeeHourlyRate: double.tryParse(m['employeeHourlyRate'].toString()),
      testingSingleLineHoursRate: double.tryParse(m['testingSingleLineHoursRate'].toString()),
      iban: m['iban'],
      idDocument: m['idDocument'],
      passport: m['passport'],
      contract: m['contract'],
      department: m['department'],
      location: m['location'],
      designation: m['designation'],
      zohoRole: m['zohoRole'],
      employmentType: m['employmentType'],
      employeeStatus: m['employeeStatus'],
      sourceOfHire: m['sourceOfHire'],
      dateOfJoining: m['dateOfJoining'],
      currentExperience: m['currentExperience'],
      totalExperience: m['totalExperience'],
      cv: m['cv'],
      jobOffer: m['jobOffer'],
      otherFiles: m['otherFiles'] != null ? List<String>.from(m['otherFiles']) : [],
      reportingManager: m['reportingManager'],
      secondaryReportingManager: m['secondaryReportingManager'],
      dateOfBirth: m['dateOfBirth'],
      age: m['age'],
      gender: m['gender'],
      maritalStatus: m['maritalStatus'],
      aboutMe: m['aboutMe'],
      expertise: m['expertise'],
      familyDoc: m['familyDoc'],
      workPhoneNumber: m['workPhoneNumber'],
      extension: m['extension'],
      personalMobileNumber: m['personalMobileNumber'],
      personalEmailAddress: m['personalEmailAddress'],
      seatingLocation: m['seatingLocation'],
      tags: m['tags'],
      presentAddress: m['presentAddress'],
      permanentAddress: m['permanentAddress'],
      dateOfExit: m['dateOfExit'],
      iqamaExpire: m['iqamaExpire'],
    );
  }

  // --- Serialization (Object -> Map) ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'role': role,
      'mustChangePassword': mustChangePassword,
      'onboardingStatus': onboardingStatus,
      'addedBy': addedBy,
      'addedTime': addedTime,
      'modifiedBy': modifiedBy,
      'modifiedTime': modifiedTime,
      'employeeId': employeeId,
      'firstName': firstName,
      'lastName': lastName,
      'nickName': nickName,
      'emailAddress': emailAddress,
      'jobDescription': jobDescription,
      'subJobDescription': subJobDescription,
      'salary': salary,
      'lastMonthCommission': lastMonthCommission,
      'employeeHourlyRate': employeeHourlyRate,
      'testingSingleLineHoursRate': testingSingleLineHoursRate,
      'iban': iban,
      'idDocument': idDocument,
      'passport': passport,
      'contract': contract,
      'department': department,
      'location': location,
      'designation': designation,
      'zohoRole': zohoRole,
      'employmentType': employmentType,
      'employeeStatus': employeeStatus,
      'sourceOfHire': sourceOfHire,
      'dateOfJoining': dateOfJoining,
      'currentExperience': currentExperience,
      'totalExperience': totalExperience,
      'cv': cv,
      'jobOffer': jobOffer,
      'otherFiles': otherFiles,
      'reportingManager': reportingManager,
      'secondaryReportingManager': secondaryReportingManager,
      'dateOfBirth': dateOfBirth,
      'age': age,
      'gender': gender,
      'maritalStatus': maritalStatus,
      'aboutMe': aboutMe,
      'expertise': expertise,
      'familyDoc': familyDoc,
      'workPhoneNumber': workPhoneNumber,
      'extension': extension,
      'personalMobileNumber': personalMobileNumber,
      'personalEmailAddress': personalEmailAddress,
      'seatingLocation': seatingLocation,
      'tags': tags,
      'presentAddress': presentAddress,
      'permanentAddress': permanentAddress,
      'dateOfExit': dateOfExit,
      'iqamaExpire': iqamaExpire,
    };
  }
}