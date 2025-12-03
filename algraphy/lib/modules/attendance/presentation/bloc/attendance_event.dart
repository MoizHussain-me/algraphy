abstract class AttendanceEvent {}

class LoadAttendanceForToday extends AttendanceEvent {
  final String userId;
  final String date; // yyyy-MM-dd
  LoadAttendanceForToday(this.userId, this.date);
}

class CheckInRequested extends AttendanceEvent {
  final String userId;
  final String date;
  final String timestamp;
  CheckInRequested(this.userId, this.date, this.timestamp);
}

class CheckOutRequested extends AttendanceEvent {
  final String userId;
  final String date;
  final String timestamp;
  CheckOutRequested(this.userId, this.date, this.timestamp);
}
