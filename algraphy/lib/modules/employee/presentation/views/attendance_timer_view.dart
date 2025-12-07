import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceTimerView extends StatefulWidget {
  const AttendanceTimerView({super.key});

  @override
  State<AttendanceTimerView> createState() => _AttendanceTimerViewState();
}

class _AttendanceTimerViewState extends State<AttendanceTimerView> {
  // Logic Variables
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  bool _isCheckedIn = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Logic Methods ---
  void _startTimer() {
    setState(() {
      _isCheckedIn = true;
      _checkInTime = DateTime.now();
      _checkOutTime = null;
      _elapsedTime = Duration.zero;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        final now = DateTime.now();
        _elapsedTime = now.difference(_checkInTime!);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isCheckedIn = false;
      _checkOutTime = DateTime.now();
    });
  }

  // --- Format Helpers ---
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

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFDC2726);
    const Color surfaceColor = Color(0xFF1C1C1C);
    const Color textColor = Colors.white;
    const Color textGrey = Colors.grey;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Date Header
          Text(
            _formatDate(),
            style: const TextStyle(
              color: textGrey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Good Morning, User",
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),

          // 2. Digital Timer Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isCheckedIn
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isCheckedIn ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _isCheckedIn ? "ON DUTY" : "OFF DUTY",
                    style: TextStyle(
                      color: _isCheckedIn ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _formatDuration(_elapsedTime),
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 64,
                    fontWeight: FontWeight.w200,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const Text(
                  "Working Hours",
                  style: TextStyle(color: textGrey, fontSize: 14),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _isCheckedIn ? _stopTimer : _startTimer,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCheckedIn ? primaryRed : Colors.green,
                      boxShadow: [
                        BoxShadow(
                          color: (_isCheckedIn ? primaryRed : Colors.green)
                              .withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Icon(
                      _isCheckedIn ? Icons.stop : Icons.fingerprint,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isCheckedIn ? "Tap to Check Out" : "Tap to Check In",
                  style: const TextStyle(color: textGrey, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: "Check In",
                  time: _formatTime(_checkInTime),
                  icon: Icons.login,
                  color: Colors.green,
                  surfaceColor: surfaceColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: "Check Out",
                  time: _formatTime(_checkOutTime),
                  icon: Icons.logout,
                  color: primaryRed,
                  surfaceColor: surfaceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history, color: Colors.blueAccent),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Total Hours Today",
                      style: TextStyle(color: textGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _checkOutTime != null
                          ? _formatDuration(_checkOutTime!.difference(_checkInTime!))
                          : "--:--:--",
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String time,
    required IconData icon,
    required Color color,
    required Color surfaceColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}