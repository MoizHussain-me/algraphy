class TeamLeaveRequest {
  final String id;
  final String employeeName;
  final String? profilePicture;
  final String leaveType;
  final String startDate;
  final String endDate;
  final int daysCount;
  final String reason;
  final String status;

  TeamLeaveRequest({
    required this.id,
    required this.employeeName,
    this.profilePicture,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    required this.reason,
    required this.status,
  });

  factory TeamLeaveRequest.fromJson(Map<String, dynamic> json) {
    return TeamLeaveRequest(
      id: json['id'].toString(),
      employeeName: "${json['first_name']} ${json['last_name']}",
      profilePicture: json['profile_picture'],
      leaveType: json['leave_type'] ?? 'General',
      startDate: json['start_date'],
      endDate: json['end_date'],
      daysCount: int.tryParse(json['days_count'].toString()) ?? 1,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
    );
  }
}