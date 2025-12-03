import 'package:algraphy/core/theme/colors.dart';
import 'package:algraphy/core/theme/typography.dart';
import 'package:algraphy/modules/attendance/data/local_attendance_repository.dart';
import 'package:algraphy/modules/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:algraphy/modules/attendance/presentation/bloc/attendance_event.dart';
import 'package:algraphy/modules/attendance/presentation/bloc/attendance_state.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_bloc.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String _todayDate() => DateFormat('yyyy-MM-dd').format(DateTime.now());
  String _nowIso() => DateTime.now().toIso8601String();

  @override
  void initState() {
    super.initState();
    // will load when the widget is built and bloc is available
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.select((AuthBloc bloc) => bloc.state);
    String? currentUserId;
    if (authState is AuthAuthenticated) currentUserId = authState.user.id;

    return Scaffold(
      body: currentUserId == null
          ? const Center(child: Text('Please login to use attendance.'))
          : BlocProvider(
              create: (_) => AttendanceBloc(LocalAttendanceRepository())..add(LoadAttendanceForToday(currentUserId!, _todayDate())),
              child: BlocBuilder<AttendanceBloc, AttendanceState>(
                builder: (context, state) {
                  if (state is AttendanceLoading) return const Center(child: CircularProgressIndicator());
                  final attendance = state is AttendanceLoaded ? state.today : null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today: ${_todayDate()}', style: const TextStyle(fontFamily: AppTypography.fontFamily, color: AppColors.textGrey)),
                      const SizedBox(height: 12),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Check-in', style: const TextStyle(color: AppColors.white)),
                              const SizedBox(height: 8),
                              attendance?.checkIn == null
                                  ? ElevatedButton(
                                      onPressed: () {
                                        context.read<AttendanceBloc>().add(CheckInRequested(currentUserId!, _todayDate(), _nowIso()));
                                      },
                                      child: const Text('Check In'),
                                    )
                                  : Text('Checked in at: ${attendance!.checkIn}'),
                              const SizedBox(height: 16),
                              Text('Check-out', style: const TextStyle(color: AppColors.white)),
                              const SizedBox(height: 8),
                              attendance?.checkOut == null
                                  ? ElevatedButton(
                                      onPressed: () {
                                        context.read<AttendanceBloc>().add(CheckOutRequested(currentUserId!, _todayDate(), _nowIso()));
                                      },
                                      child: const Text('Check Out'),
                                    )
                                  : Text('Checked out at: ${attendance!.checkOut}'),
                            ],
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
    );
  }
}
