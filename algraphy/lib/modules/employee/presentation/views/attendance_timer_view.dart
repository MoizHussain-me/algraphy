import 'dart:async';
import 'dart:ui';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:algraphy/modules/employee/data/employee_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:algraphy/core/theme/colors.dart';

class AttendanceTimerView extends StatefulWidget {
  final UserModel userName;
  final VoidCallback? onViewMore;

  const AttendanceTimerView({super.key, required this.userName, this.onViewMore});

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
  List<Map<String, dynamic>> _recentHistory = [];

  bool _isProcessingAction = false;

  // Geofencing States
  double? _distanceFromOffice;
  bool _isWithinRange = false;

  // Dynamic Geofence Values
  double? _targetLat;
  double? _targetLng;
  double? _targetRadius;
  String? _officeName;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _updateLocationAndDistance();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await GetIt.I<EmployeeRepository>().getAttendanceHistory();
      if (mounted) {
        final Map<String, Map<String, dynamic>> uniqueDays = {};
        for(var item in data) {
          final date = item['date']?.toString();
          if (date != null && !uniqueDays.containsKey(date)) {
            uniqueDays[date] = item;
          }
        }
        
        var sortedList = uniqueDays.values.toList();
        sortedList.sort((a,b) {
          final dateA = DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });

        setState(() {
          _recentHistory = sortedList.take(5).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  Future<void> _fetchStatus() async {
    try {
      final response = await GetIt.I<EmployeeRepository>().getTodayStatus();
      
      if (mounted) {
        setState(() {
          if (response != null) {
            final data = response['data'];
            final geo = response['geofence'];

            if (geo != null) {
              _targetLat = double.tryParse(geo['geofence_lat']?.toString() ?? '');
              _targetLng = double.tryParse(geo['geofence_lng']?.toString() ?? '');
              _targetRadius = double.tryParse(geo['geofence_radius']?.toString() ?? '');
              _officeName = geo['office_name'];
            }

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
                 _elapsedTime = _checkOutTime!.difference(_checkInTime!);
              } else if (_checkInTime != null) {
                 _startLocalTicker();
              }
            } else {
              _status = null;
              _elapsedTime = Duration.zero;
            }
          }
          _isLoading = false;
        });
        // After fetching status (which includes geofence data), update distance
        _updateLocationAndDistance();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLocationAndDistance() async {
    try {
      if (_targetLat == null || _targetLng == null) return;
      
      if (!await _checkLocationPermission()) return;
      
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      double distance = Geolocator.distanceBetween(
        pos.latitude, 
        pos.longitude, 
        _targetLat!, 
        _targetLng!
      );

      if (mounted) {
        setState(() {
          _distanceFromOffice = distance;
          _isWithinRange = distance <= (_targetRadius ?? 100.0);
        });
      }
    } catch (e) {
      debugPrint("Error updating geofence: $e");
    }
  }

  // --- Actions ---

  Future<void> _handleClockIn() async {
    if (_isProcessingAction) return;
    setState(() => _isProcessingAction = true);

    // 1. Check Permissions and Geofence
    if (!await _checkLocationPermission()) {
      if (mounted) setState(() => _isProcessingAction = false);
      return;
    }
    
    await _updateLocationAndDistance();
    
    if (!_isWithinRange) {
      _showError("You are too far from the office (${_distanceFromOffice?.toStringAsFixed(0)}m). Please go to the office to clock in.");
      if (mounted) setState(() => _isProcessingAction = false);
      return;
    }

    try {
      await GetIt.I<EmployeeRepository>().checkIn();
      await _fetchStatus(); // Refresh to get the generated ID and valid state
      await _fetchHistory();
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
    if (mounted) setState(() => _isProcessingAction = false);
  }

  Future<void> _handleClockOut() async {
    if (_attendanceId == null || _isProcessingAction) return;
    setState(() => _isProcessingAction = true);
    
    // 1. Check Permissions and Geofence
    if (!await _checkLocationPermission()) {
      if (mounted) setState(() => _isProcessingAction = false);
      return;
    }
    
    await _updateLocationAndDistance();
    
    if (!_isWithinRange) {
      _showError("You are too far from the office (${_distanceFromOffice?.toStringAsFixed(0)}m). Please go back to the office to clock out.");
      if (mounted) setState(() => _isProcessingAction = false);
      return;
    }

    // Validate Break Status
    if (_status == 'On Break') {
      _showError("Please Resume Work before Checking Out");
      if (mounted) setState(() => _isProcessingAction = false);
      return;
    }

    try {
      await GetIt.I<EmployeeRepository>().checkOut();
      await _fetchStatus();
      await _fetchHistory();
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
    if (mounted) setState(() => _isProcessingAction = false);
  }

  Future<void> _toggleBreak() async {
    if (_attendanceId == null || _isProcessingAction) return;
    setState(() => _isProcessingAction = true);
    
    // Determine action based on current status
    bool isStartingBreak = _status != 'On Break';
    String statusPayload = isStartingBreak ? 'On Break' : 'Present';

    try {
      await GetIt.I<EmployeeRepository>().toggleBreak(statusPayload);
      await _fetchStatus();
      await _fetchHistory();
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
    if (mounted) setState(() => _isProcessingAction = false);
  }

  Future<bool> _checkLocationPermission() async {
    // 1. Web handling
    if (kIsWeb) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) _showError("Location permissions are permanently denied. Please enable them in your browser settings.");
        return false;
      }
      return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    }

    // 2. Mobile handling
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) _showError("Location services are disabled. Please enable them to continue.");
      return false;
    }

    var status = await Permission.locationWhenInUse.status;
    
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
      if (status.isDenied) {
        if (mounted) _showError("Location permission is required for attendance.");
        return false;
      }
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Location Permission Required"),
            content: const Text("Attendance requires location access. Please enable it in app settings."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              TextButton(onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              }, child: const Text("Open Settings")),
            ],
          ),
        );
      }
      return false;
    }

    if (status.isGranted) {
      try {
        await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low)
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
    }

    return status.isGranted;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _startLocalTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_checkInTime != null && mounted && _status != 'Completed') {
        setState(() {
          // 1. Main Timer
          _elapsedTime = DateTime.now().difference(_checkInTime!);
          
          // 2. Break Timer
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
    return "$hours:$minutes";
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

  String _formatTimeStr(dynamic timeStr) {
    if (timeStr == null || timeStr == '') return '--:--';
    try {
      final dt = DateTime.parse(timeStr.toString());
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return '--:--';
    }
  }

  String _formatHours(dynamic hours) {
    if (hours == null) return '-';
    final h = double.tryParse(hours.toString()) ?? 0.0;
    return h.toStringAsFixed(1);
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    // Derived States
    bool isOnDuty = _status == 'Present' || _status == 'On Break';
    bool isOnBreak = _status == 'On Break';
    bool isCompleted = _status == 'Completed';

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_elapsedTime.inHours);
    final minutes = twoDigits(_elapsedTime.inMinutes.remainder(60));
    final seconds = twoDigits(_elapsedTime.inSeconds.remainder(60));

    return Container(
      color: Colors.black, // Dark background matching the design
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Optional: Header
            Text(_formatDate(), style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(
              "${_getGreeting()}, ${widget.userName.firstName}", 
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // --- 1. Top Timer Card ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12, // Gap between components in a row
                    runSpacing: 12, // Gap between rows if wrapped
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Digital Timer
                      Row(
                        mainAxisSize: MainAxisSize.min, // Ensure child Row only takes what it needs
                        children: [
                          _buildTimeBox(hours),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(":", style: TextStyle(color: Colors.grey, fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                          _buildTimeBox(minutes),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(":", style: TextStyle(color: Colors.grey, fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                          _buildTimeBox(seconds),
                        ],
                      ),
                      
                      // Action Buttons
                      Row(
                        mainAxisSize: MainAxisSize.min, // Ensure child Row only takes what it needs
                        children: [
                          if (isOnDuty) ...[
                            _buildActionButton(
                              label: isOnBreak ? "Resume" : "Break",
                              color: const Color(0xFFDC2726),
                              onTap: _toggleBreak,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (!isCompleted)
                            _buildActionButton(
                              label: !isOnDuty ? "Check-in" : "Check-out",
                              color: !isOnDuty ? Colors.green : const Color(0xFFEF5350), // Red accent
                              onTap: !isOnDuty ? _handleClockIn : (isOnBreak ? null : _handleClockOut),
                            )
                          else
                            const Text("Completed", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Status
                  Text(
                    isOnBreak ? "On Break" : (isOnDuty ? "In" : (isCompleted ? "Completed" : "Out")),
                    style: TextStyle(
                      color: isOnBreak ? const Color(0xFFDC2726) : (isOnDuty ? Colors.green : Colors.grey),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  // Geofence Distance Indicator
                  if (_distanceFromOffice != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isWithinRange ? Icons.location_on : Icons.location_off,
                              size: 14,
                              color: _isWithinRange ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isWithinRange 
                                  ? "Within Range (${_distanceFromOffice!.toStringAsFixed(0)}m)" 
                                  : "Out of Range (${_distanceFromOffice!.toStringAsFixed(0)}m)",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _isWithinRange ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        if (_officeName != null)
                          Text(
                            " at $_officeName",
                            style: TextStyle(
                              fontSize: 12, 
                              color: (_isWithinRange ? Colors.green : Colors.red).withOpacity(0.7)
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- 2. Activity / Work Schedule Card ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.access_time, color: Colors.lightBlue, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Recent Activity", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text("Last 5 days", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // History Rows
                  if (_recentHistory.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text("No recent activity.", style: TextStyle(color: Colors.grey))),
                    )
                  else
                    ..._recentHistory.map((item) {
                      final dateStr = item['date']?.toString();
                      final dt = DateTime.tryParse(dateStr ?? '') ?? DateTime.now();
                      final isCompleted = item['clock_out'] != null;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildActivityRow(
                          day: dt.day.toString(),
                          dayStr: DateFormat('E').format(dt).toUpperCase(),
                          title: "Attendance",
                          timeStr: "In: ${_formatTimeStr(item['clock_in'])} | Out: ${_formatTimeStr(item['clock_out'])}",
                          status: isCompleted ? "Completed" : "Active",
                          statusColor: isCompleted ? Colors.green : const Color(0xFFDC2726),
                          hours: _formatHours(item['work_hours']),
                        ),
                      );
                    }),
                  
                  // View More Button
                  Center(
                    child: OutlinedButton(
                      onPressed: widget.onViewMore ?? () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text("View More", style: TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // --- 3. Time Logs Card (Matching Design Placeholder) ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF5350).withOpacity(0.2), // Light red
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.timer_outlined, color: Color(0xFFEF5350), size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Time Logs",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "You are yet to submit your time logs today!",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      // Navigate to or open Time Logs feature
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "Time Log",
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildTimeBox(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF323232), // Grey box for timer numbers
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w400,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildActionButton({required String label, required Color color, VoidCallback? onTap}) {
    bool isProcessing = _isProcessingAction && onTap != null;
    
    return Material(
      color: (onTap == null || isProcessing) ? color.withOpacity(0.3) : color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Widget _buildActivityRow({
    required String day,
    required String dayStr,
    required String title,
    required String timeStr,
    required String status,
    required Color statusColor,
    required String hours,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Dark circle with date
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(day, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(dayStr, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Center text column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(status, style: TextStyle(color: statusColor, fontSize: 12)),
            ],
          ),
        ),
        // Right side hours
        if (hours.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(hours, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text("Hrs", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
      ],
    );
  }
}