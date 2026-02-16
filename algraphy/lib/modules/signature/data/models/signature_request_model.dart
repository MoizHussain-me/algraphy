class SignatureRequestModel {
  final String id;
  final String employeeId;
  final String documentTitle;
  final String originalPath;
  final String? signedPath;
  final String token;
  final String status;
  final String? createdAt; // Added this
  final String? signedAt;  // Added this
  final String? firstName; // From the JOIN
  final String? lastName;  // From the JOIN
  final String? expiryDate; // Added this

  SignatureRequestModel({
    required this.id,
    required this.employeeId,
    required this.documentTitle,
    required this.originalPath,
    this.signedPath,
    required this.token,
    required this.status,
    this.createdAt,
    this.signedAt,
    this.firstName,
    this.lastName,
    this.expiryDate,
  });

  factory SignatureRequestModel.fromJson(Map<String, dynamic> json) {
    return SignatureRequestModel(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      documentTitle: json['document_title'] ?? '',
      originalPath: json['original_path'] ?? '',
      signedPath: json['signed_path'],
      token: json['token'] ?? '',
      status: json['status'] ?? 'Pending',
      createdAt: json['created_at'],
      signedAt: json['signed_at'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      expiryDate: json['expiry_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'document_title': documentTitle,
      'original_path': originalPath,
      'signed_path': signedPath,
      'token': token,
      'status': status,
      'created_at': createdAt,
      'signed_at': signedAt,
    };
  }

  String get employeeFullName => "$firstName $lastName";
}