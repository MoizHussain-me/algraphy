import 'dart:async';
import 'dart:ui';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:algraphy/modules/employee/data/attendance_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';

class AttendanceTimerView extends StatefulWidget {
  final UserModel userName;

  const AttendanceTimerView({super.key, required this.userName});

  @override
  State<AttendanceTimerView> createState() => _AttendanceTimerViewState();
}

class _AttendanceTimerViewState extends State<AttendanceTimerView> {
  Timer? _timer;
  
  // Timer States
  Duration _elapsedTime = Duration.zero;
  Duration _breakDuration = Duration.zero;
  
  // Data from API
  String? _attendanceId;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  DateTime? _breakStartTime;
  
  // Status: null (Not Started), 'Present', 'On Break', 'Completed'
  String? _status; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  Future<void> _fetchStatus() async {
    try {
      final data = await GetIt.I<AttendanceRepository>().getTodayAttendance(widget.userName.id);
      
      if (mounted) {
        setState(() {
          if (data != null) {
            _attendanceId = data['id']?.toString();
            _status = data['status'];
            
            if (data['clock_in'] != null) {
              _checkInTime = DateTime.parse(data['clock_in']);
            }
            if (data['clock_out'] != null) {
              _checkOutTime = DateTime.parse(data['clock_out']);
            }
            if (data['break_start'] != null) {
              _breakStartTime = DateTime.parse(data['break_start']);
            }
            
            // Resume Timer Logic
            if (_status == 'Completed' && _checkOutTime != null && _checkInTime != null) {
               // If completed, fix the time to the final duration
               _elapsedTime = _checkOutTime!.difference(_checkInTime!);
            } else if (_checkInTime != null) {
               _startLocalTicker();
            }
          } else {
            // No record found for today
            _status = null;
            _elapsedTime = Duration.zero;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Actions ---

  Future<void> _handleClockIn() async {
    setState(() => _isLoading = true);
    try {
      await GetIt.I<AttendanceRepository>().checkIn(widget.userName.id);
      await _fetchStatus(); // Refresh to get the generated ID and valid state
    } catch (e) {
      if (mounted) _showError(e.toString());
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleClockOut() async {
    if (_attendanceId == null) return;
    
    // Validate Break Status
    if (_status == 'On Break') {
      _showError("Please Resume Work before Checking Out");
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await GetIt.I<AttendanceRepository>().checkOut(_attendanceId!);
      await _fetchStatus();
    } catch (e) {
      if (mounted) _showError(e.toString());
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBreak() async {
    if (_attendanceId == null) return;
    
    // Determine action based on current status
    bool isStartingBreak = _status != 'On Break';
    String statusPayload = isStartingBreak ? 'On Break' : 'Present';

    setState(() => _isLoading = true);
    try {
      await GetIt.I<AttendanceRepository>().toggleBreak(statusPayload);
      await _fetchStatus();
    } catch (e) {
      if (mounted) _showError(e.toString());
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _startLocalTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_checkInTime != null && mounted && _status != 'Completed') {
        setState(() {
          // 1. Main Timer: Always runs from Clock In (Requirement: timer should not stop)
          _elapsedTime = DateTime.now().difference(_checkInTime!);
          
          // 2. Break Timer: Only runs if On Break
          if (_status == 'On Break' && _breakStartTime != null) {
            _breakDuration = DateTime.now().difference(_breakStartTime!);
          } else {
            _breakDuration = Duration.zero;
          }
        });
      }
    });
  }

  // --- Formatters ---

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return "--:--";
    return DateFormat('hh:mm a').format(dt);
  }

  String _formatDate() {
    return DateFormat('EEEE, d MMMM y').format(DateTime.now());
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFDC2726);
    const Color surfaceColor = Color(0xFF1C1C1C);
    const Color textColor = Colors.white;
    const Color textGrey = Colors.grey;

    // Derived States
    bool isOnDuty = _status == 'Present' || _status == 'On Break';
    bool isOnBreak = _status == 'On Break';
    bool isCompleted = _status == 'Completed';

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date Header
          Text(_formatDate(), style: const TextStyle(color: textGrey, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          
          // Dynamic Greeting
          Text(
            "${_getGreeting()}, ${widget.userName.firstName}", 
            style: const TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),

          // --- Digital Timer Card ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: surfaceColor, 
              borderRadius: BorderRadius.circular(20), 
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
            ),
            child: Column(
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOnBreak 
                        ? Colors.orange.withOpacity(0.1) 
                        : (isOnDuty ? Colors.green.withOpacity(0.1) : (isCompleted ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1))),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOnBreak 
                          ? Colors.orange 
                          : (isOnDuty ? Colors.green : (isCompleted ? Colors.blue : Colors.grey)), 
                      width: 1
                    ),
                  ),
                  child: Text(
                    isOnBreak ? "ON BREAK" : (isOnDuty ? "ON DUTY" : (isCompleted ? "COMPLETED" : "OFF DUTY")),
                    style: TextStyle(
                      color: isOnBreak 
                          ? Colors.orange 
                          : (isOnDuty ? Colors.green : (isCompleted ? Colors.blue : Colors.grey)),
                      fontWeight: FontWeight.bold, 
                      fontSize: 12, 
                      letterSpacing: 1.2
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Main Timer
                Text(
                  _formatDuration(_elapsedTime),
                  style: const TextStyle(
                    color: textColor, 
                    fontSize: 64, 
                    fontWeight: FontWeight.w200, 
                    fontFeatures: [FontFeature.tabularFigures()]
                  ),
                ),
                Text(
                  isCompleted ? "Total Hours Worked" : "Working Hours", 
                  style: const TextStyle(color: textGrey, fontSize: 14)
                ),

                // Break Timer (Visible only when on break)
                if (isOnBreak) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.coffee, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "Break: ${_formatDuration(_breakDuration)}",
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // --- Control Buttons ---
                if (isCompleted)
                  const Text("Shift Completed for Today", style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold))
                else if (!isOnDuty) 
                  // CASE 1: Not Checked In -> Show Clock In
                  GestureDetector(
                    onTap: _handleClockIn,
                    child: _buildCircleButton(
                      icon: Icons.fingerprint, 
                      color: Colors.green, 
                      label: "Tap to Check In"
                    ),
                  )
                else 
                  // CASE 2: Checked In -> Show Break + Clock Out
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Break Button
                      GestureDetector(
                        onTap: _toggleBreak,
                        child: _buildCircleButton(
                          icon: isOnBreak ? Icons.play_arrow : Icons.coffee,
                          color: isOnBreak ? Colors.green : Colors.orange,
                          label: isOnBreak ? "Resume" : "Break",
                          isSmall: false,
                        ),
                      ),
                      
                      const SizedBox(width: 32),

                      // Clock Out Button (Disabled if on break)
                      GestureDetector(
                        onTap: isOnBreak ? null : _handleClockOut,
                        child: Opacity(
                          opacity: isOnBreak ? 0.5 : 1.0,
                          child: _buildCircleButton(
                            icon: Icons.stop,
                            color: primaryRed,
                            label: "Check Out",
                            isSmall: false,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats Grid
          Row(
            children: [
              Expanded(child: _buildStatCard(
                title: "Check In", 
                time: _formatTime(_checkInTime), 
                icon: Icons.login, 
                color: Colors.green, 
                surfaceColor: surfaceColor
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                title: "Check Out", 
                time: _formatTime(_checkOutTime), 
                icon: Icons.logout, 
                color: primaryRed, 
                surfaceColor: surfaceColor
              )),
            ],
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildCircleButton({
    required IconData icon, 
    required Color color, 
    required String label, 
    bool isSmall = false
  }) {
    final double size = isSmall ? 60 : 80;
    final double iconSize = isSmall ? 30 : 40;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 5)
            ],
          ),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildStatCard({required String title, required String time, required IconData icon, required Color color, required Color surfaceColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)), Icon(icon, color: color, size: 18)]),
        const SizedBox(height: 12),
        Text(time, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}