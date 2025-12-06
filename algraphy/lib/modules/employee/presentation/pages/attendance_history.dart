import 'package:flutter/material.dart';

class AttendanceHistoryPage extends StatelessWidget {
  const AttendanceHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final List<Map<String, String>> history = [
      {"date": "Today", "in": "09:00 AM", "out": "--:--", "status": "Present"},
      {"date": "Yesterday", "in": "09:15 AM", "out": "06:00 PM", "status": "Present"},
      {"date": "Tue, 03 Dec", "in": "09:00 AM", "out": "06:10 PM", "status": "Present"},
      {"date": "Mon, 02 Dec", "in": "--:--", "out": "--:--", "status": "Absent"},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Attendance History",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = history[index];
              final isAbsent = item['status'] == 'Absent';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(
                      color: isAbsent ? Colors.red : Colors.green,
                      width: 4,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['date']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['status']!,
                          style: TextStyle(
                            color: isAbsent ? Colors.redAccent : Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (!isAbsent)
                      Row(
                        children: [
                          _buildTimeBadge("IN", item['in']!, Colors.green),
                          const SizedBox(width: 12),
                          _buildTimeBadge("OUT", item['out']!, Colors.red),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBadge(String label, String time, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}