class UserModel {
  final String id;
  final String email;
  final String password;
  final String role; // "admin" or "employee"
  final bool mustChangePassword;

  // Work Information
  final String? department;
  final String? location;
  final String? designation;
  final String? cv;
  final String? jobOffer;
  final String? zohoRole;
  final String? employmentType;
  final String? employeeStatus;
  final String? sourceOfHire;
  final String? dateOfJoining;
  final String? currentExperience;
  final String? totalExperience;
  final List<String>? otherFiles;

  // Basic Info
  final String? employeeId;
  final String? firstName;
  final String? lastName;
  final String? nickName;
  final double? salary;
  final double? lastMonthCommission;
  final double? employeeHourlyRate;
  final double? testingSingleLineHoursRate;
  final String? iban;
  final String? emailAddress;
  final String? jobDescription;
  final String? subJobDescription;
  final String? idNumber;
  final String? passport;
  final String? contract;

  // Hierarchy
  final String? reportingManager;
  final String? secondaryReportingManager;

  // Personal Info
  final String? dateOfBirth;
  final int? age;
  final String? gender;
  final String? maritalStatus;
  final String? aboutMe;
  final String? expertise;
  final List<String>? familyDocs;

  UserModel({
    required this.id,
    required this.email,
    required this.password,
    this.role = "employee",
    this.mustChangePassword = true,
    this.department,
    this.location,
    this.designation,
    this.cv,
    this.jobOffer,
    this.zohoRole,
    this.employmentType,
    this.employeeStatus,
    this.sourceOfHire,
    this.dateOfJoining,
    this.currentExperience,
    this.totalExperience,
    this.otherFiles,
    this.employeeId,
    this.firstName,
    this.lastName,
    this.nickName,
    this.salary,
    this.lastMonthCommission,
    this.employeeHourlyRate,
    this.testingSingleLineHoursRate,
    this.iban,
    this.emailAddress,
    this.jobDescription,
    this.subJobDescription,
    this.idNumber,
    this.passport,
    this.contract,
    this.reportingManager,
    this.secondaryReportingManager,
    this.dateOfBirth,
    this.age,
    this.gender,
    this.maritalStatus,
    this.aboutMe,
    this.expertise,
    this.familyDocs,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'password': password,
        'role': role,
        'mustChangePassword': mustChangePassword,
        'department': department,
        'location': location,
        'designation': designation,
        'cv': cv,
        'jobOffer': jobOffer,
        'zohoRole': zohoRole,
        'employmentType': employmentType,
        'employeeStatus': employeeStatus,
        'sourceOfHire': sourceOfHire,
        'dateOfJoining': dateOfJoining,
        'currentExperience': currentExperience,
        'totalExperience': totalExperience,
        'otherFiles': otherFiles,
        'employeeId': employeeId,
        'firstName': firstName,
        'lastName': lastName,
        'nickName': nickName,
        'salary': salary,
        'lastMonthCommission': lastMonthCommission,
        'employeeHourlyRate': employeeHourlyRate,
        'testingSingleLineHoursRate': testingSingleLineHoursRate,
        'iban': iban,
        'emailAddress': emailAddress,
        'jobDescription': jobDescription,
        'subJobDescription': subJobDescription,
        'idNumber': idNumber,
        'passport': passport,
        'contract': contract,
        'reportingManager': reportingManager,
        'secondaryReportingManager': secondaryReportingManager,
        'dateOfBirth': dateOfBirth,
        'age': age,
        'gender': gender,
        'maritalStatus': maritalStatus,
        'aboutMe': aboutMe,
        'expertise': expertise,
        'familyDocs': familyDocs,
      };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        id: m['id'],
        email: m['email'],
        password: m['password'],
        role: m['role'] ?? "employee",
        mustChangePassword: m['mustChangePassword'] ?? true,
        department: m['department'],
        location: m['location'],
        designation: m['designation'],
        cv: m['cv'],
        jobOffer: m['jobOffer'],
        zohoRole: m['zohoRole'],
        employmentType: m['employmentType'],
        employeeStatus: m['employeeStatus'],
        sourceOfHire: m['sourceOfHire'],
        dateOfJoining: m['dateOfJoining'],
        currentExperience: m['currentExperience'],
        totalExperience: m['totalExperience'],
        otherFiles: List<String>.from(m['otherFiles'] ?? []),
        employeeId: m['employeeId'],
        firstName: m['firstName'],
        lastName: m['lastName'],
        nickName: m['nickName'],
        salary: m['salary']?.toDouble(),
        lastMonthCommission: m['lastMonthCommission']?.toDouble(),
        employeeHourlyRate: m['employeeHourlyRate']?.toDouble(),
        testingSingleLineHoursRate: m['testingSingleLineHoursRate']?.toDouble(),
        iban: m['iban'],
        emailAddress: m['emailAddress'],
        jobDescription: m['jobDescription'],
        subJobDescription: m['subJobDescription'],
        idNumber: m['idNumber'],
        passport: m['passport'],
        contract: m['contract'],
        reportingManager: m['reportingManager'],
        secondaryReportingManager: m['secondaryReportingManager'],
        dateOfBirth: m['dateOfBirth'],
        age: m['age'],
        gender: m['gender'],
        maritalStatus: m['maritalStatus'],
        aboutMe: m['aboutMe'],
        expertise: m['expertise'],
        familyDocs: List<String>.from(m['familyDocs'] ?? []),
      );
}
