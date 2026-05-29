import 'package:flutter/material.dart';

class WorkerStatusPanel extends StatelessWidget {
  const WorkerStatusPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF456486) : const Color(0xFF1B2A41),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF84A4C5) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Worker Status",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _worker("Worker 21", "Safe", Colors.green),
          _worker("Worker 12", "Restricted Zone", Colors.orange),
          _worker("Worker 8", "Emergency", Colors.red),
        ],
      ),
    );
  }

  Widget _worker(String name, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.person, color: color),
          const SizedBox(width: 10),
          Text(name, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}
