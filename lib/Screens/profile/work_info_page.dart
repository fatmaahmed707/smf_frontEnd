import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/language_provider.dart';
import '../../utils/navigation_helper.dart';

class WorkInfoPage extends StatefulWidget {
  const WorkInfoPage({super.key});

  @override
  State<WorkInfoPage> createState() => _WorkInfoPageState();
}

class _WorkInfoPageState extends State<WorkInfoPage> {
  bool _isEditing = false;

  // ── Employee Data ────────────────────────────────────────────────────────
  final _jobTitleCtrl = TextEditingController(text: "ADMIN");
  final _departmentCtrl = TextEditingController(text: "Security Operations");
  final _managerCtrl = TextEditingController(text: "");
  final _locationCtrl = TextEditingController(text: "Zone A — Building 3");
  final _shiftCtrl = TextEditingController(text: "Morning — 07:00 to 15:00");

  // ── Qualifications ───────────────────────────────────────────────────────
  final _certificatesCtrl =
      TextEditingController(text: "ISO 45001, Fire Safety Level 2");
  final _safetyCoursesCtrl =
      TextEditingController(text: "First Aid, Hazmat Handling");
  final _equipmentCtrl =
      TextEditingController(text: "Radio Unit #14, Tablet #07");

  // ── Status ───────────────────────────────────────────────────────────────
  String _employmentStatus = "Active";
  String _attendanceStatus = "Present";

  final List<String> _employmentOptions = ["Active", "On Leave", "Remote"];
  final List<String> _attendanceOptions = ["Present", "Absent", "On Break"];

  @override
  void dispose() {
    _jobTitleCtrl.dispose();
    _departmentCtrl.dispose();
    _managerCtrl.dispose();
    _locationCtrl.dispose();
    _shiftCtrl.dispose();
    _certificatesCtrl.dispose();
    _safetyCoursesCtrl.dispose();
    _equipmentCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
    if (!_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Work information saved successfully ✓"),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final isDark = themeProvider.isDarkMode;
    final bgColor = isDark ? const Color(0xFF0A1628) : const Color(0xFFF4F6FA);
    final cardColor = isDark ? const Color(0xFF111C30) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.withValues(alpha: 0.15);

    return WillPopScope(
      onWillPop: () => AppNavigation.handleSystemBack(
        context,
        fallbackRoute: '/profile',
      ),
      child: Directionality(
        textDirection: lang.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0A1628) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black87),
            onPressed: () => AppNavigation.goBack(
              context,
              fallbackRoute: '/profile',
            ),
          ),
          title: Text(
            lang.isArabic ? "معلومات العمل" : "Work Information",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _toggleEdit,
                icon: Icon(
                  _isEditing ? Icons.check : Icons.edit_outlined,
                  size: 18,
                  color: _isEditing ? Colors.green : Colors.blueAccent,
                ),
                label: Text(
                  _isEditing
                      ? (lang.isArabic ? "حفظ" : "Save")
                      : (lang.isArabic ? "تعديل" : "Edit"),
                  style: TextStyle(
                    color: _isEditing ? Colors.green : Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Employee Data ──────────────────────────────────────────
              _sectionHeader(
                isDark,
                icon: Icons.work_outline,
                label: lang.isArabic ? "بيانات الموظف" : "Employee Data",
              ),
              const SizedBox(height: 12),
              _card(cardColor, borderColor, [
                _field(isDark,
                    label: lang.isArabic ? "المسمى الوظيفي" : "Job Title",
                    ctrl: _jobTitleCtrl,
                    icon: Icons.badge_outlined),
                _field(isDark,
                    label: lang.isArabic ? "القسم" : "Department",
                    ctrl: _departmentCtrl,
                    icon: Icons.business_outlined),
                _field(isDark,
                    label: lang.isArabic ? "اسم المدير" : "Manager Name",
                    ctrl: _managerCtrl,
                    icon: Icons.person_outline),
                _field(isDark,
                    label: lang.isArabic ? "موقع العمل" : "Work Location",
                    ctrl: _locationCtrl,
                    icon: Icons.location_on_outlined),
                _field(isDark,
                    label: lang.isArabic ? "جدول الوردية" : "Shift Schedule",
                    ctrl: _shiftCtrl,
                    icon: Icons.schedule_outlined),
              ]),

              const SizedBox(height: 24),

              // ── Qualifications ─────────────────────────────────────────
              _sectionHeader(
                isDark,
                icon: Icons.school_outlined,
                label: lang.isArabic
                    ? "المؤهلات والتدريب"
                    : "Qualifications & Training",
                accent: Colors.teal,
              ),
              const SizedBox(height: 12),
              _card(cardColor, borderColor, [
                _field(isDark,
                    label: lang.isArabic
                        ? "الشهادات التدريبية"
                        : "Training Certificates",
                    ctrl: _certificatesCtrl,
                    icon: Icons.workspace_premium_outlined),
                _field(isDark,
                    label: lang.isArabic
                        ? "دورات السلامة المكتملة"
                        : "Safety Courses Completed",
                    ctrl: _safetyCoursesCtrl,
                    icon: Icons.health_and_safety_outlined),
                _field(isDark,
                    label: lang.isArabic
                        ? "المعدات المخصصة"
                        : "Equipment Assigned",
                    ctrl: _equipmentCtrl,
                    icon: Icons.devices_outlined),
              ]),

              const SizedBox(height: 24),

              // ── Status ─────────────────────────────────────────────────
              _sectionHeader(
                isDark,
                icon: Icons.toggle_on_outlined,
                label: lang.isArabic ? "الحالة" : "Status",
                accent: Colors.orange,
              ),
              const SizedBox(height: 12),
              _card(cardColor, borderColor, [
                _dropdownRow(
                  isDark,
                  label: lang.isArabic ? "حالة التوظيف" : "Employment Status",
                  icon: Icons.work_history_outlined,
                  value: _employmentStatus,
                  options: _employmentOptions,
                  chipColors: {
                    "Active": Colors.green,
                    "On Leave": Colors.orange,
                    "Remote": Colors.blueAccent,
                  },
                  onChanged: (v) => setState(() => _employmentStatus = v!),
                ),
                _dropdownRow(
                  isDark,
                  label: lang.isArabic ? "حالة الحضور" : "Attendance Status",
                  icon: Icons.how_to_reg_outlined,
                  value: _attendanceStatus,
                  options: _attendanceOptions,
                  chipColors: {
                    "Present": Colors.green,
                    "Absent": Colors.red,
                    "On Break": Colors.orange,
                  },
                  onChanged: (v) => setState(() => _attendanceStatus = v!),
                ),
              ]),

              const SizedBox(height: 28),

              if (_isEditing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _toggleEdit,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: Text(
                      lang.isArabic ? "حفظ التغييرات" : "Save Changes",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(bool isDark,
      {required IconData icon,
      required String label,
      Color accent = Colors.blueAccent}) {
    return Row(children: [
      Icon(icon, color: accent, size: 18),
      const SizedBox(width: 8),
      Text(label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          )),
    ]);
  }

  Widget _card(Color cardColor, Color borderColor, List<Widget> children) {
    final divider =
        Divider(height: 1, color: borderColor, indent: 16, endIndent: 16);
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) rows.add(divider);
    }
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: rows),
    );
  }

  Widget _field(
    bool isDark, {
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white38 : Colors.black38;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: subColor),
        const SizedBox(width: 12),
        Expanded(
          child: _isEditing
              ? TextField(
                  controller: ctrl,
                  keyboardType: type,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: TextStyle(color: subColor, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(color: subColor, fontSize: 11)),
                      const SizedBox(height: 3),
                      Text(
                        ctrl.text.isEmpty ? "—" : ctrl.text,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
        ),
        if (_isEditing)
          Icon(Icons.edit,
              size: 14, color: isDark ? Colors.white24 : Colors.black26),
      ]),
    );
  }

  Widget _dropdownRow(
    bool isDark, {
    required String label,
    required IconData icon,
    required String value,
    required List<String> options,
    required Map<String, Color> chipColors,
    required ValueChanged<String?> onChanged,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white38 : Colors.black38;
    final chipColor = chipColors[value] ?? Colors.blueAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: subColor),
        const SizedBox(width: 12),
        Expanded(
          child: _isEditing
              ? DropdownButtonFormField<String>(
                  initialValue: value,
                  dropdownColor:
                      isDark ? const Color(0xFF111C30) : Colors.white,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: TextStyle(color: subColor, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  items: options
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
                  onChanged: onChanged,
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(color: subColor, fontSize: 11)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: chipColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: chipColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          value,
                          style: TextStyle(
                            color: chipColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        if (_isEditing)
          Icon(Icons.edit,
              size: 14, color: isDark ? Colors.white24 : Colors.black26),
      ]),
    );
  }
}
