import 'package:flutter/material.dart';

class SecurityUpdateBanner extends StatelessWidget {
  const SecurityUpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F6BAE), Color(0xFF3A2E78)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Security Update Available",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                Text(
                  "System firmware v2.4.1 ready for deployment",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              "VIEW",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}