import 'dart:async';
import 'dart:ui';
import 'package:algraphy/modules/employee/data/attendance_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';

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
  bool _isLoading = true; // Loading state for API

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

  // --- 1. Fetch Initial Status from Server ---
  Future<void> _fetchStatus() async {
    try {
      final data = await GetIt.I<AttendanceRepository>().getTodayStatus();
      
      if (mounted) {
        setState(() {
          _isCheckedIn = data['isCheckedIn'] ?? false;
          
          if (data['checkInTime'] != null) {
            _checkInTime = DateTime.parse(data['checkInTime']);
            
            // If currently checked in, resume timer based on server time
            if (_isCheckedIn) {
              _startLocalTicker(); 
            } else {
               // If checked out, calculate final duration
               if (data['checkOutTime'] != null) {
                 _checkOutTime = DateTime.parse(data['checkOutTime']);
                 _elapsedTime = _checkOutTime!.difference(_checkInTime!);
               }
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching status: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. Button Actions ---
  Future<void> _handleCheckAction() async {
    setState(() => _isLoading = true);
    try {
      if (_isCheckedIn) {
        // CHECK OUT
        await GetIt.I<AttendanceRepository>().checkOut();
        _stopTimer();
      } else {
        // CHECK IN
        await GetIt.I<AttendanceRepository>().checkIn();
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 3. Timer Logic ---
  void _startTimer() {
    setState(() {
      _isCheckedIn = true;
      _checkInTime = DateTime.now(); // Local time sync with server roughly
      _checkOutTime = null;
      _startLocalTicker();
    });
  }

  void _startLocalTicker() {
    _timer?.cancel();
    // Update UI every second based on difference from _checkInTime
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_checkInTime != null && mounted) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_checkInTime!);
        });
      }
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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Date Header
          Text(_formatDate(), style: const TextStyle(color: textGrey, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text("Good Morning, User", style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),

          // 2. Digital Timer Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isCheckedIn ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isCheckedIn ? Colors.green : Colors.orange, width: 1),
                  ),
                  child: Text(_isCheckedIn ? "ON DUTY" : "OFF DUTY", style: TextStyle(color: _isCheckedIn ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                ),
                const SizedBox(height: 24),
                Text(
                  _formatDuration(_elapsedTime),
                  style: const TextStyle(color: textColor, fontSize: 64, fontWeight: FontWeight.w200, fontFeatures: [FontFeature.tabularFigures()]),
                ),
                const Text("Working Hours", style: TextStyle(color: textGrey, fontSize: 14)),
                const SizedBox(height: 40),
                
                // CHECK IN BUTTON
                GestureDetector(
                  onTap: _handleCheckAction, // CONNECTED TO API
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCheckedIn ? primaryRed : Colors.green,
                      boxShadow: [BoxShadow(color: (_isCheckedIn ? primaryRed : Colors.green).withOpacity(0.4), blurRadius: 20, spreadRadius: 5)],
                    ),
                    child: Icon(_isCheckedIn ? Icons.stop : Icons.fingerprint, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_isCheckedIn ? "Tap to Check Out" : "Tap to Check In", style: const TextStyle(color: textGrey, fontSize: 14)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Stats Grid
          Row(
            children: [
              Expanded(child: _buildStatCard(title: "Check In", time: _formatTime(_checkInTime), icon: Icons.login, color: Colors.green, surfaceColor: surfaceColor)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(title: "Check Out", time: _formatTime(_checkOutTime), icon: Icons.logout, color: primaryRed, surfaceColor: surfaceColor)),
            ],
          ),
          const SizedBox(height: 16),
          // ... (Rest of UI)
        ],
      ),
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