import '../../data/models/attendance_model.dart';

abstract class AttendanceState {}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final AttendanceModel? today;
  AttendanceLoaded(this.today);
}

class AttendanceFailure extends AttendanceState {
  final String message;
  AttendanceFailure(this.message);
}
