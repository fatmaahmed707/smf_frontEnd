import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import '../../services/auth_service.dart';
import '../../services/frontend_report_snapshot.dart';
import '../../utils/frontend_report_pdf.dart';
import '../../utils/report_download.dart';

class ReportsPage extends StatelessWidget {
  final dynamic palette;

  const ReportsPage({super.key, required this.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final metricColumns = width >= 1200
            ? 4
            : width >= 760
                ? 2
                : 1;
        final metricRatio = width >= 1200
            ? 1.35
            : width >= 760
                ? 1.65
                : 1.45;
        final snapshot = FrontendReportSnapshot.instance;
        final assignedOwnerIds = snapshot.assignedDevices
            .where((device) => device.ownerId.trim().isNotEmpty)
            .map((device) => device.ownerId)
            .toSet();
        final unassignedUsers = snapshot.users
            .where((user) => !assignedOwnerIds.contains(user.id))
            .length;
        final offlineDevices = snapshot.assignedDevices
            .where(
              (device) => device.status.toUpperCase().contains('OFFLINE'),
            )
            .length;
        final sosDevices = snapshot.assignedDevices
            .where((device) => device.status.toUpperCase().contains('SOS'))
            .length;
        final violationDevices = snapshot.assignedDevices
            .where((device) => device.violationCount > 0)
            .length;
        final riskFlags =
            unassignedUsers + offlineDevices + sosDevices + violationDevices;

        return SingleChildScrollView(
          padding: EdgeInsets.all(width < 560 ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(palette: palette),
              const SizedBox(height: 22),
              GridView.count(
                crossAxisCount: metricColumns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: metricRatio,
                children: [
                  _MetricCard(
                    label: 'Loaded Users',
                    value: snapshot.users.length.toString(),
                    subtitle: 'Current Users Management data',
                    icon: Icons.groups_2_outlined,
                    color: const Color(0xFF38BDF8),
                  ),
                  _MetricCard(
                    label: 'Assigned Devices',
                    value: snapshot.assignedDevices.length.toString(),
                    subtitle: 'Device records assigned to users',
                    icon: Icons.devices_other_outlined,
                    color: const Color(0xFF22C55E),
                  ),
                  _MetricCard(
                    label: 'Unassigned Users',
                    value: unassignedUsers.toString(),
                    subtitle: 'Users without an assigned device',
                    icon: Icons.person_off_outlined,
                    color: const Color(0xFFFBBF24),
                  ),
                  _MetricCard(
                    label: 'Risk Flags',
                    value: riskFlags.toString(),
                    subtitle: 'Offline, SOS, violations, unassigned',
                    icon: Icons.report_gmailerrorred_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 1050;
                  if (stacked) {
                    return Column(
                      children: [
                        _ReportsList(palette: palette),
                        const SizedBox(height: 20),
                        _ExportPanel(palette: palette),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: _ReportsList(palette: palette)),
                      const SizedBox(width: 20),
                      Expanded(flex: 4, child: _ExportPanel(palette: palette)),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final dynamic palette;

  const _Header({required this.palette});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  palette.primaryBlue2.withOpacity(0.28),
                  palette.primaryBlue.withOpacity(0.08),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.primaryBlue2.withOpacity(0.22),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.assessment_rounded,
              color: palette.primaryBlue2,
              size: 34,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.getText('reports'),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lang.getText('reportsSubtitle'),
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.textMuted.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.cardBorder),
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  final reportLanguage = await _selectReportLanguage(
                    context,
                    palette,
                  );
                  if (reportLanguage == null) return;
                  final bytes = await buildFrontendSnapshotPdf(
                    generatedBy: AuthService.instance.userId,
                    language: reportLanguage,
                  );
                  await downloadReportPdf(bytes, frontendSnapshotFilename());
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'PDF report generated from current frontend-loaded data only.',
                      ),
                    ),
                  );
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                }
              },
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(lang.getText('generateReport')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: palette.textMuted,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<ReportLanguage?> _selectReportLanguage(
  BuildContext context,
  dynamic palette,
) {
  return showDialog<ReportLanguage>(
    context: context,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final cardColor = isDark
          ? const Color.fromRGBO(5, 18, 45, 0.94)
          : const Color.fromRGBO(255, 255, 255, 0.98);
      final borderColor = isDark
          ? const Color.fromRGBO(56, 189, 248, 0.22)
          : const Color.fromRGBO(59, 130, 246, 0.16);
      final textColor = isDark ? Colors.white : const Color(0xFF061942);
      final mutedColor =
          isDark ? const Color(0xFF9DB2D8) : const Color(0xFF6678A5);

      Widget option({
        required String title,
        required String subtitle,
        required IconData icon,
        required ReportLanguage value,
      }) {
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pop(context, value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.innerCardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.primaryBlue.withOpacity(0.14),
                  ),
                  child: Icon(icon, color: palette.primaryBlue2, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: mutedColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: mutedColor),
              ],
            ),
          ),
        );
      }

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Report Language',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                option(
                  title: 'English',
                  subtitle: 'Generate report in English',
                  icon: Icons.language_rounded,
                  value: ReportLanguage.english,
                ),
                const SizedBox(height: 10),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: option(
                    title: 'العربية',
                    subtitle: 'إنشاء التقرير باللغة العربية',
                    icon: Icons.translate_rounded,
                    value: ReportLanguage.arabic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.dark
        ? (
            bg: const Color.fromRGBO(5, 18, 45, 0.72),
            border: const Color.fromRGBO(56, 189, 248, 0.22),
            text: const Color(0xFFF8FAFC),
            muted: const Color(0xFF9DB2D8),
          )
        : (
            bg: const Color.fromRGBO(255, 255, 255, 0.86),
            border: const Color.fromRGBO(59, 130, 246, 0.16),
            text: const Color(0xFF061B5B),
            muted: const Color(0xFF6678A5),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 220;
        final iconSize = compact ? 42.0 : 48.0;

        return Container(
          padding: EdgeInsets.all(compact ? 16 : 20),
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.24),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: compact ? 22 : 24),
              ),
              SizedBox(height: compact ? 10 : 14),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 14 : 15,
                ),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 32 : 38,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.muted),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportsList extends StatelessWidget {
  final dynamic palette;

  const _ReportsList({required this.palette});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final reports = [
      (
        lang.getText('dailyOperationsSummary'),
        lang.getText('generatedAtMorning'),
        lang.getText('ready')
      ),
      (
        lang.getText('emergencyDrillAudit'),
        lang.getText('preparedForLeadership'),
        lang.getText('review')
      ),
      (
        lang.getText('deviceHealthSnapshot'),
        lang.getText('tracksMaintenance'),
        lang.getText('ready')
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.getText('recentReports'),
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ...reports.map(
            (report) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: palette.innerCardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.innerCardBorder),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 620;
                  final leading = Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.primaryBlue.withOpacity(0.14),
                    ),
                    child: Icon(
                      Icons.insert_drive_file_outlined,
                      color: palette.primaryBlue2,
                    ),
                  );
                  final details = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.$1,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        report.$2,
                        style: TextStyle(color: palette.textMuted),
                      ),
                    ],
                  );
                  final status = Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: palette.primaryBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      report.$3,
                      style: TextStyle(
                        color: palette.primaryBlue2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            leading,
                            const SizedBox(width: 14),
                            Expanded(child: details),
                          ],
                        ),
                        const SizedBox(height: 12),
                        status,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      leading,
                      const SizedBox(width: 14),
                      Expanded(child: details),
                      const SizedBox(width: 12),
                      status,
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportPanel extends StatelessWidget {
  final dynamic palette;

  const _ExportPanel({required this.palette});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.getText('exportCenter'),
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            lang.getText('exportCenterDesc'),
            style: TextStyle(color: palette.textMuted, height: 1.5),
          ),
          const SizedBox(height: 18),
          _ActionTile(
            palette: palette,
            title: lang.getText('executiveSnapshot'),
            subtitle: lang.getText('executiveSnapshotDesc'),
            icon: Icons.insights_outlined,
          ),
          const SizedBox(height: 12),
          _ActionTile(
            palette: palette,
            title: lang.getText('complianceBundle'),
            subtitle: lang.getText('complianceBundleDesc'),
            icon: Icons.fact_check_outlined,
          ),
          const SizedBox(height: 12),
          _ActionTile(
            palette: palette,
            title: lang.getText('fieldOperationsPack'),
            subtitle: lang.getText('fieldOperationsPackDesc'),
            icon: Icons.route_outlined,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final dynamic palette;
  final String title;
  final String subtitle;
  final IconData icon;

  const _ActionTile({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.innerCardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.innerCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.primaryBlue.withOpacity(0.14),
            ),
            child: Icon(icon, color: palette.primaryBlue2, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: palette.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
