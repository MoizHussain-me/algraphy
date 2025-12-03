import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/local_attendance_repository.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final LocalAttendanceRepository _repo;

  AttendanceBloc(this._repo) : super(AttendanceInitial()) {
    on<LoadAttendanceForToday>((e, emit) async {
      emit(AttendanceLoading());
      try {
        final today = await _repo.getForDate(e.userId, e.date);
        emit(AttendanceLoaded(today));
      } catch (ex) {
        emit(AttendanceFailure(ex.toString()));
      }
    });

    on<CheckInRequested>((e, emit) async {
      emit(AttendanceLoading());
      try {
        await _repo.checkIn(e.userId, e.date, e.timestamp);
        final today = await _repo.getForDate(e.userId, e.date);
        emit(AttendanceLoaded(today));
      } catch (ex) {
        emit(AttendanceFailure(ex.toString()));
      }
    });

    on<CheckOutRequested>((e, emit) async {
      emit(AttendanceLoading());
      try {
        await _repo.checkOut(e.userId, e.date, e.timestamp);
        final today = await _repo.getForDate(e.userId, e.date);
        emit(AttendanceLoaded(today));
      } catch (ex) {
        emit(AttendanceFailure(ex.toString()));
      }
    });
  }
}
