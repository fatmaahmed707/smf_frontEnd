import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import '../../services/auth_service.dart';

class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return AlertDialog(
      title: Text(lang.getText("logout")),
      content: Text(lang.getText("logoutConfirm")),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(lang.getText("cancel")),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await AuthService.instance.logout();
            if (!context.mounted) {
              return;
            }
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          },
          child: Text(
            lang.getText("confirm"),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
