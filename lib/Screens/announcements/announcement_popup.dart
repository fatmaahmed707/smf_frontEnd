import 'package:flutter/material.dart';
import 'announcement_model.dart';

class AnnouncementPopup extends StatefulWidget {
  final AnnouncementModel announcement;

  const AnnouncementPopup({super.key, required this.announcement});

  @override
  State<AnnouncementPopup> createState() => _AnnouncementPopupState();
}

class _AnnouncementPopupState extends State<AnnouncementPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  Color getPriorityColor() {
    switch (widget.announcement.priority.toLowerCase()) {
      case "critical":
        return Colors.red;
      case "high":
        return Colors.orange;
      case "medium":
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void acknowledge() {
    setState(() {
      widget.announcement.isRead = true;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final color = getPriorityColor();

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 25,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, color: color, size: 60),
                const SizedBox(height: 10),
                Text(
                  widget.announcement.priority.toUpperCase(),
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                const SizedBox(height: 15),
                Text(
                  widget.announcement.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Text(
                  widget.announcement.message,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade700),
                const SizedBox(height: 10),
                Text(
                  "Sent by: ${widget.announcement.sender}",
                  style: const TextStyle(color: Colors.white54),
                ),
                Text(
                  "Time: ${widget.announcement.timestamp}",
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                  ),
                  onPressed: acknowledge,
                  child: const Text(
                    "ACKNOWLEDGE",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}