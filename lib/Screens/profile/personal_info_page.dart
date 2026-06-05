import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/language_provider.dart';
import '../../utils/navigation_helper.dart';
import '../../services/users_service.dart';
import '../../models/user.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  bool _isEditing = false;
  final UsersService _usersService = UsersService();
  User? _currentUser;
  bool _isLoading = true;
  String? _loadError;

  // ── Basic Details ────────────────────────────────────────────────────────
  final _fullNameCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _dobCtrl = TextEditingController(text: "");
  final _phoneCtrl = TextEditingController(text: "");
  final _emailCtrl = TextEditingController();
  String _selectedGender = "Prefer not to say";
  final List<String> _genders = ["Male", "Female", "Prefer not to say"];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final user = await _usersService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _fullNameCtrl.text = user.name.trim();
        _emailCtrl.text = user.email.trim();
        _phoneCtrl.text = user.phone ?? '';
        _nationalIdCtrl.text = user.id.trim().isEmpty
            ? context.read<LanguageProvider>().getText('sessionAccount')
            : context.read<LanguageProvider>().getText('accountLinked');
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _nationalIdCtrl.dispose();
    _dobCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleEdit() async {
    setState(() => _isEditing = !_isEditing);
    if (!_isEditing) {
      final lang = context.read<LanguageProvider>();
      final currentUser = _currentUser;
      if (currentUser != null && currentUser.id.trim().isNotEmpty) {
        await _usersService.updateUser(
          id: currentUser.id,
          username: _fullNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          roles: {
            if (currentUser.role?.trim().isNotEmpty == true)
              currentUser.role!.trim()
            else if (currentUser.roles.isNotEmpty)
              currentUser.roles.first
            else
              'USER',
          },
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.getText('personalInformationSaved')),
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
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.grey.withValues(alpha: 0.15);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        AppNavigation.handleSystemBack(
          context,
          fallbackRoute: '/profile',
        );
      },
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
              lang.getText('personalInfo'),
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
                        ? (lang.getText('save'))
                        : (lang.getText('edit')),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                    ? Center(
                        child: Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Basic Details ────────────────────────────────────────
                          _sectionHeader(
                            isDark,
                            icon: Icons.person_outline,
                            label: lang.getText('basicDetails'),
                          ),
                          const SizedBox(height: 12),
                          _card(cardColor, borderColor, [
                            _field(isDark,
                                label: lang.getText('fullName'),
                                ctrl: _fullNameCtrl,
                                icon: Icons.badge_outlined),
                            _field(isDark,
                                label: lang.getText('nationalId'),
                                ctrl: _nationalIdCtrl,
                                icon: Icons.credit_card_outlined),
                            _field(isDark,
                                label: lang.getText('dateOfBirth'),
                                ctrl: _dobCtrl,
                                icon: Icons.calendar_today_outlined,
                                type: TextInputType.datetime),
                            _genderRow(isDark, label: lang.getText('gender')),
                            _field(isDark,
                                label: lang.getText('phoneNumber'),
                                ctrl: _phoneCtrl,
                                icon: Icons.phone_outlined,
                                type: TextInputType.phone),
                            _field(isDark,
                                label: lang.getText('emailLabel'),
                                ctrl: _emailCtrl,
                                icon: Icons.email_outlined,
                                type: TextInputType.emailAddress),
                          ]),

                          const SizedBox(height: 28),

                          if (_isEditing)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _toggleEdit,
                                icon: const Icon(Icons.check,
                                    color: Colors.white),
                                label: Text(
                                  lang.getText('saveChanges'),
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

  Widget _genderRow(bool isDark, {required String label}) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white38 : Colors.black38;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Icon(Icons.people_outline, size: 18, color: subColor),
        const SizedBox(width: 12),
        Expanded(
          child: _isEditing
              ? DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  dropdownColor:
                      isDark ? const Color(0xFF111C30) : Colors.white,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: TextStyle(color: subColor, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedGender = val);
                  },
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(color: subColor, fontSize: 11)),
                      const SizedBox(height: 3),
                      Text(_selectedGender,
                          style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
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
