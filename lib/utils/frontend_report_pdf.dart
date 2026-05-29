import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:smf_main/models/device_record.dart';
import 'package:smf_main/models/user.dart';
import 'package:smf_main/services/frontend_report_snapshot.dart';

Future<Uint8List> buildFrontendSnapshotPdf({String? generatedBy}) async {
  final snapshot = FrontendReportSnapshot.instance;
  final data = _ReportData.fromSnapshot(snapshot);
  final logo = await _loadPdfImage('assets/images/logo_smf_clear.png');
  return _EnterprisePdf(data, logo: logo).build();
}

String frontendSnapshotFilename() {
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  return 'smf-admin-frontend-report-${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}.pdf';
}

Future<_PdfImage?> _loadPdfImage(String assetPath) async {
  try {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 96,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (rgba == null) return null;

    final source = rgba.buffer.asUint8List();
    final rgb = Uint8List(image.width * image.height * 3);
    var target = 0;
    for (var i = 0; i < source.length; i += 4) {
      final alpha = source[i + 3] / 255;
      rgb[target++] = (source[i] * alpha + 255 * (1 - alpha)).round();
      rgb[target++] = (source[i + 1] * alpha + 255 * (1 - alpha)).round();
      rgb[target++] = (source[i + 2] * alpha + 255 * (1 - alpha)).round();
    }

    return _PdfImage(
      name: 'ImLogo',
      width: image.width,
      height: image.height,
      bytes: rgb,
    );
  } catch (_) {
    return null;
  }
}

class _ReportData {
  final FrontendReportSnapshot snapshot;
  final DateTime generatedAt;
  final List<User> users;
  final List<DeviceRecord> devices;
  final List<User> usersWithoutDevices;
  final List<DeviceRecord> offlineDevices;
  final List<DeviceRecord> sosDevices;
  final List<DeviceRecord> violationDevices;

  _ReportData({
    required this.snapshot,
    required this.generatedAt,
    required this.users,
    required this.devices,
    required this.usersWithoutDevices,
    required this.offlineDevices,
    required this.sosDevices,
    required this.violationDevices,
  });

  factory _ReportData.fromSnapshot(FrontendReportSnapshot snapshot) {
    final users = List<User>.from(snapshot.users);
    final devices = List<DeviceRecord>.from(snapshot.assignedDevices);
    final assignedOwnerIds = devices
        .where((device) => device.ownerId.trim().isNotEmpty)
        .map((device) => device.ownerId)
        .toSet();

    return _ReportData(
      snapshot: snapshot,
      generatedAt: DateTime.now(),
      users: users,
      devices: devices,
      usersWithoutDevices:
          users.where((user) => !assignedOwnerIds.contains(user.id)).toList(),
      offlineDevices: devices
          .where((device) => device.status.toUpperCase().contains('OFFLINE'))
          .toList(),
      sosDevices: devices
          .where((device) => device.status.toUpperCase().contains('SOS'))
          .toList(),
      violationDevices:
          devices.where((device) => device.violationCount > 0).toList(),
    );
  }
}

class _EnterprisePdf {
  final _ReportData data;
  final _PdfImage? logo;
  static const double pageWidth = 595;
  static const double pageHeight = 842;
  static const double margin = 20;
  static const double footerHeight = 34;

  final List<_PdfPage> _pages = [];
  late _PdfPage _page;
  double _y = pageHeight - margin;

  _EnterprisePdf(this.data, {this.logo});

  Uint8List build() {
    _newPage();
    _drawHeader();
    _drawSummaryCards();
    _drawUsersTable();
    _drawDeviceTable();
    _drawOperationsCards();
    _drawFooters();
    return _PdfDocument(_pages, images: [
      if (logo != null) logo!,
    ]).build();
  }

  void _newPage() {
    _page = _PdfPage(pageWidth, pageHeight);
    _pages.add(_page);
    _page.rect(0, 0, pageWidth, pageHeight, fill: _PdfColor.bg);
    _y = pageHeight - margin;
  }

  void _ensure(double height) {
    if (_y - height < margin + footerHeight) {
      _newPage();
    }
  }

  void _drawHeader() {
    _page.rect(
      margin + 2,
      _y - 74,
      pageWidth - margin * 2,
      70,
      fill: _PdfColor.shadow,
    );
    _page.rect(
      margin,
      _y - 72,
      pageWidth - margin * 2,
      70,
      fill: _PdfColor.surface,
      stroke: _PdfColor.border,
    );

    if (logo != null) {
      _page.image(logo!.name, margin + 10, _y - 56, 50, 42);
    } else {
      _page.rect(margin + 13, _y - 46, 32, 32, fill: _PdfColor.blueSoft);
      _page.text('SMF', margin + 19, _y - 27,
          size: 12, color: _PdfColor.blue, bold: true);
    }
    _page.line(margin + 68, _y - 62, margin + 68, _y - 11, _PdfColor.divider);

    _page.text('SMF Admin Operations Report', margin + 86, _y - 23,
        size: 16.4, color: _PdfColor.text, bold: true);
    const metaX = pageWidth - margin - 184;
    _page.rect(metaX + 1.5, _y - 60.5, 172, 48, fill: _PdfColor.shadow);
    _page.rect(metaX, _y - 59, 172, 48,
        fill: _PdfColor.surfaceAlt, stroke: _PdfColor.softBorder);
    _metaLine(metaX + 10, _y - 25, 'Generated At', _dateTime(data.generatedAt));
    _metaLine(metaX + 10, _y - 43, 'Scope', 'Current session');
    _y -= 88;
  }

  void _drawSummaryCards() {
    _sectionTitle('Executive Summary');
    final cards = [
      _Metric('Loaded Users', '${data.users.length}', 'US', _PdfColor.blue),
      _Metric('Assigned Devices', '${data.devices.length}', 'DV',
          _PdfColor.green),
      _Metric('Unassigned Users', '${data.usersWithoutDevices.length}', 'UN',
          _PdfColor.orange),
      _Metric('Offline Devices', '${data.offlineDevices.length}', 'OF',
          _PdfColor.purple),
      _Metric('SOS Devices', '${data.sosDevices.length}', 'SOS',
          _PdfColor.red),
      _Metric('Devices With Violations', '${data.violationDevices.length}', '!',
          _PdfColor.amber),
    ];
    const gap = 5.0;
    const cardW = (pageWidth - margin * 2 - gap * 5) / 6;
    const cardH = 48.0;
    for (var i = 0; i < cards.length; i++) {
      final x = margin + i * (cardW + gap);
      final card = cards[i];
      _page.rect(x + 1.5, _y - cardH - 1.5, cardW, cardH,
          fill: _PdfColor.shadow);
      _page.rect(x, _y - cardH, cardW, cardH,
          fill: _PdfColor.surface, stroke: _PdfColor.softBorder);
      _page.rect(x + 8, _y - 30, 20, 20, fill: _soft(card.color));
      _page.text(card.icon, x + 12, _y - 22.5,
          size: 6.2, color: card.color, bold: true);
      _page.text(card.value, x + 36, _y - 19,
          size: 15.5, color: _PdfColor.text, bold: true);
      _page.text(_truncate(card.label, 18), x + 36, _y - 34.5,
          size: 6.1, color: _PdfColor.textMuted);
    }
    _y -= cardH + 18;
  }

  void _drawUsersTable() {
    _sectionTitle(
      'Users & Workforce',
      right: 'Total Users Loaded: ${data.users.length}',
    );
    if (data.users.isEmpty) {
      _emptyCard('Users & Workforce data is not available in the current session.');
      return;
    }

    final headers = [
      '#',
      'User / Email',
      'Roles',
      'Assigned Device(s)',
      'Account Status',
      'Last Seen',
    ];
    final widths = [22.0, 126.0, 88.0, 136.0, 76.0, 107.0];
    _tableHeader(headers, widths);
    for (var i = 0; i < data.users.length; i++) {
      final user = data.users[i];
      final devices =
          data.devices.where((device) => device.ownerId == user.id).toList();
      _tableRow(
        [
          '${i + 1}',
          '${_value(user.name)} / ${_value(user.email)}',
          _roles(user),
          devices.isEmpty ? 'Unassigned' : devices.map(_deviceLabel).join('; '),
          'Active',
          _lastSeenFor(devices),
        ],
        widths,
        i,
        badges: {2: true, 4: true},
      );
    }
    _y -= 12;
  }

  void _drawDeviceTable() {
    _sectionTitle('Device Assignments');
    if (data.devices.isEmpty) {
      _emptyCard('Device assignment data is not available in the current session.');
      return;
    }

    final headers = [
      '#',
      'MAC Address',
      'Owner',
      'Status',
      'Last Seen',
      'Zone',
      'Violations',
    ];
    final widths = [22.0, 106.0, 92.0, 68.0, 86.0, 118.0, 55.0];
    _tableHeader(headers, widths);
    for (var i = 0; i < data.devices.length; i++) {
      final device = data.devices[i];
      _tableRow(
        [
          '${i + 1}',
          _value(device.macAddress),
          _value(_ownerName(data.users, device.ownerId)),
          _value(device.status),
          _dateTime(device.lastSeenTimestamp),
          _value(device.zoneName ?? device.zoneId),
          '${device.violationCount}',
        ],
        widths,
        i,
        badges: {3: _deviceIsGood(device)},
      );
    }
    _y -= 12;
  }

  void _drawOperationsCards() {
    _sectionTitle('Registry / Available Devices / Risk Flags');
    _ensure(136);
    const gap = 7.0;
    const leftW = 162.0;
    const midW = 162.0;
    const cardH = 124.0;
    const rightW = pageWidth - margin * 2 - leftW - midW - gap * 2;
    final top = _y;

    _dashboardCard(
      margin,
      top,
      leftW,
      cardH,
      'SMF Device Registry',
      '${data.snapshot.smfDevices.length}',
      'Registered Device(s)',
      _PdfColor.blue,
    );
    _dashboardList(
      margin + 12,
      top - 68,
      leftW - 24,
      data.snapshot.smfDevices
          .take(3)
          .map((device) => '${_value(device.label)}  ${_value(device.macAddress)}')
          .toList(),
    );

    const midX = margin + leftW + gap;
    _dashboardCard(
      midX,
      top,
      midW,
      cardH,
      'Available / Unregistered',
      '${data.snapshot.availableSmfDevices.length}',
      'Available Device(s)',
      _PdfColor.green,
    );
    _dashboardList(
      midX + 12,
      top - 68,
      midW - 24,
      data.snapshot.availableSmfDevices
          .take(3)
          .map((device) => '${_value(device.label)}  ${_value(device.macAddress)}')
          .toList(),
    );

    final risks = [
      _Risk(
        'Users without assigned devices',
        data.usersWithoutDevices.map((u) => _value(u.name)).join(', ').ifEmpty('None'),
        data.usersWithoutDevices.isEmpty ? _PdfColor.green : _PdfColor.orange,
      ),
      _Risk(
        'Offline devices',
        data.offlineDevices.map(_deviceLabel).join(', ').ifEmpty('None'),
        data.offlineDevices.isEmpty ? _PdfColor.green : _PdfColor.purple,
      ),
      _Risk(
        'SOS devices',
        data.sosDevices.map(_deviceLabel).join(', ').ifEmpty('None'),
        data.sosDevices.isEmpty ? _PdfColor.green : _PdfColor.red,
      ),
      _Risk(
        'Devices with violations',
        data.violationDevices.map(_deviceLabel).join(', ').ifEmpty('None'),
        data.violationDevices.isEmpty ? _PdfColor.green : _PdfColor.amber,
      ),
    ];

    const riskX = midX + midW + gap;
    _page.rect(riskX + 1.5, top - cardH - 1.5, rightW, cardH,
        fill: _PdfColor.shadow);
    _page.rect(riskX, top - cardH, rightW, cardH,
        fill: _PdfColor.surface, stroke: _PdfColor.softBorder);
    _page.text('Risk Flags'.toUpperCase(), riskX + 12, top - 18,
        size: 8.1, color: _PdfColor.blue, bold: true);
    var riskY = top - 36;
    for (final risk in risks) {
      _page.rect(riskX + 10, riskY - 17, rightW - 20, 20,
          fill: _PdfColor.surfaceAlt);
      _page.rect(riskX + 12, riskY - 11, 13, 13, fill: _soft(risk.color));
      _page.text('!', riskX + 16.5, riskY - 6.2,
          size: 6.2, color: risk.color, bold: true);
      _page.text(risk.title, riskX + 31, riskY - 2.5,
          size: 6.4, color: _PdfColor.text, bold: true);
      _page.text(_truncate(risk.detail, 48), riskX + 31, riskY - 12.2,
          size: 5.7, color: _PdfColor.textMuted);
      riskY -= 24;
    }
    _y -= cardH + 18;
  }

  void _sectionTitle(String title, {String? right}) {
    _ensure(28);
    _page.text(title.toUpperCase(), margin, _y,
        size: 9.6, color: _PdfColor.blue, bold: true);
    if (right != null) {
      _page.text(right, pageWidth - margin - 118, _y,
          size: 7.0, color: _PdfColor.textMuted);
    }
    _y -= 13;
  }

  void _emptyCard(String message) {
    _ensure(38);
    _page.rect(margin, _y - 30, pageWidth - margin * 2, 30,
        fill: _PdfColor.surfaceAlt, stroke: _PdfColor.softBorder);
    _page.rect(margin + 12, _y - 21, 13, 13, fill: _PdfColor.blueSoft);
    _page.text('i', margin + 17, _y - 16.2,
        size: 5.6, color: _PdfColor.blue, bold: true);
    _page.text(message, margin + 34, _y - 17,
        size: 7.6, color: _PdfColor.textMuted);
    _y -= 40;
  }

  void _tableHeader(List<String> headers, List<double> widths) {
    _ensure(28);
    var x = margin;
    _page.rect(margin, _y - 18, widths.reduce((a, b) => a + b), 18,
        fill: _PdfColor.tableHeader, stroke: _PdfColor.border);
    for (var i = 0; i < headers.length; i++) {
      _page.text(headers[i], x + 5, _y - 11.5,
          size: 6.7, color: _PdfColor.textMuted, bold: true);
      x += widths[i];
    }
    _y -= 18;
  }

  void _tableRow(
    List<String> cells,
    List<double> widths,
    int index, {
    Map<int, bool> badges = const {},
  }) {
    const rowH = 25.0;
    _ensure(rowH + 6);
    var x = margin;
    _page.rect(
      margin,
      _y - rowH,
      widths.reduce((a, b) => a + b),
      rowH,
      fill: index.isEven ? _PdfColor.rowA : _PdfColor.rowB,
      stroke: _PdfColor.softBorder,
    );
    for (var i = 0; i < cells.length; i++) {
      final value = _truncate(cells[i], math.max(7, (widths[i] / 5.0).floor()));
      if (badges.containsKey(i)) {
        final color = _badgeColor(value, badges[i] == true);
        final badgeW =
            math.min(widths[i] - 8, math.max(32, value.length * 4.8)).toDouble();
        _page.rect(x + 4, _y - 18.5, badgeW, 12,
            fill: _soft(color), stroke: _soft(color));
        _page.text(value, x + 8, _y - 14.2,
            size: 5.9, color: color, bold: true);
      } else {
        _page.text(value, x + 5, _y - 15,
            size: 6.6, color: _PdfColor.text);
      }
      x += widths[i];
    }
    _y -= rowH;
  }

  _PdfColor _badgeColor(String value, bool good) {
    final upper = value.toUpperCase();
    if (upper.contains('SOS')) return _PdfColor.red;
    if (upper.contains('OFFLINE') || upper.contains('NO') || upper.contains('NOT')) {
      return _PdfColor.red;
    }
    if (upper.contains('WORKER') || upper.contains('ORANGE')) return _PdfColor.orange;
    if (upper.contains('MANAGER')) return _PdfColor.green;
    if (upper.contains('ADMIN')) return _PdfColor.red;
    if (upper.contains('ENGINEER')) return _PdfColor.blue;
    if (good) return _PdfColor.green;
    return _PdfColor.orange;
  }

  bool _deviceIsGood(DeviceRecord device) {
    final status = device.status.toUpperCase();
    return status.contains('ONLINE') || status.contains('ACTIVE');
  }

  void _drawFooters() {
    for (var i = 0; i < _pages.length; i++) {
      final page = _pages[i];
    page.line(margin, 34, pageWidth - margin, 34, _PdfColor.divider);
      page.text('SMF Industrial Safety System', margin, 20,
          size: 8, color: _PdfColor.textMuted);
      page.text('Generated: ${_dateTime(data.generatedAt)}', 232, 20,
          size: 8, color: _PdfColor.textMuted);
      page.text('Page ${i + 1} / ${_pages.length}', pageWidth - margin - 58, 20,
          size: 8, color: _PdfColor.textMuted);
    }
  }

  void _metaLine(double x, double y, String label, String value) {
    _page.text(label, x, y, size: 6.6, color: _PdfColor.textMuted, bold: true);
    _page.text(_truncate(value, 31), x + 68, y,
        size: 6.6, color: _PdfColor.text);
  }

  void _dashboardCard(
    double x,
    double top,
    double width,
    double height,
    String title,
    String value,
    String label,
    _PdfColor accent,
  ) {
    _page.rect(x + 1.5, top - height - 1.5, width, height,
        fill: _PdfColor.shadow);
    _page.rect(x, top - height, width, height,
        fill: _PdfColor.surface, stroke: _PdfColor.softBorder);
    _page.text(title.toUpperCase(), x + 12, top - 18,
        size: 7.5, color: _PdfColor.blue, bold: true);
    _page.rect(x + 12, top - 49, 23, 23, fill: _soft(accent));
    _page.text(value, x + 52, top - 41,
        size: 15, color: _PdfColor.text, bold: true);
    _page.text(label, x + 52, top - 54, size: 6.5, color: _PdfColor.textMuted);
  }

  void _dashboardList(double x, double y, double width, List<String> items) {
    if (items.isEmpty) {
      _page.rect(x, y - 30, width, 30,
          fill: _PdfColor.surfaceAlt, stroke: _PdfColor.softBorder);
      _page.text('Not available', x + 34, y - 18,
          size: 7.2, color: _PdfColor.textMuted);
      return;
    }
    var itemY = y;
    for (final item in items) {
      _page.rect(x, itemY - 19, width, 19,
          fill: _PdfColor.surfaceAlt, stroke: _PdfColor.softBorder);
      _page.text(_truncate(item, 31), x + 8, itemY - 11.8,
          size: 6.3, color: _PdfColor.text);
      itemY -= 22;
    }
  }

  _PdfColor _soft(_PdfColor color) {
    return _PdfColor(
      1 - (1 - color.r) * 0.12,
      1 - (1 - color.g) * 0.12,
      1 - (1 - color.b) * 0.12,
    );
  }
}

class _Metric {
  final String label;
  final String value;
  final String icon;
  final _PdfColor color;

  const _Metric(this.label, this.value, this.icon, this.color);
}

class _Risk {
  final String title;
  final String detail;
  final _PdfColor color;

  const _Risk(this.title, this.detail, this.color);
}

class _PdfImage {
  final String name;
  final int width;
  final int height;
  final Uint8List bytes;

  const _PdfImage({
    required this.name,
    required this.width,
    required this.height,
    required this.bytes,
  });
}

String _roles(User user) {
  final roles = user.roles.isNotEmpty
      ? user.roles
      : [
          if (user.role?.trim().isNotEmpty == true) user.role!.trim(),
        ];
  return roles.isEmpty ? 'Not available' : roles.join(', ');
}

String _ownerName(List<User> users, String ownerId) {
  for (final user in users) {
    if (user.id == ownerId) return user.name.isEmpty ? user.email : user.name;
  }
  return ownerId;
}

String _deviceLabel(DeviceRecord device) {
  final label = device.displayLabel.trim().isNotEmpty
      ? device.displayLabel.trim()
      : device.label.trim();
  final mac = device.macAddress.trim();
  if (label.isNotEmpty && mac.isNotEmpty) return '$label ($mac)';
  if (label.isNotEmpty) return label;
  if (mac.isNotEmpty) return mac;
  return _value(device.id);
}

String _lastSeenFor(List<DeviceRecord> devices) {
  final timestamps = devices
      .map((device) => device.lastSeenTimestamp)
      .whereType<DateTime>()
      .toList();
  if (timestamps.isEmpty) return 'Not available';
  timestamps.sort();
  return _dateTime(timestamps.last);
}

String _value(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? 'Not available' : trimmed;
}

String _dateTime(DateTime? value) {
  if (value == null) return 'Not available';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}';
}

String _truncate(String value, int max) {
  if (value.length <= max) return value;
  if (max <= 3) return value.substring(0, max);
  return '${value.substring(0, max - 3)}...';
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _PdfColor {
  final double r;
  final double g;
  final double b;

  const _PdfColor(this.r, this.g, this.b);

  static const bg = _PdfColor(0.972, 0.978, 0.986);
  static const surface = _PdfColor(1, 1, 1);
  static const surfaceAlt = _PdfColor(0.982, 0.986, 0.992);
  static const shadow = _PdfColor(0.90, 0.92, 0.95);
  static const tableHeader = _PdfColor(0.938, 0.958, 0.982);
  static const rowA = _PdfColor(1, 1, 1);
  static const rowB = _PdfColor(0.982, 0.987, 0.994);
  static const border = _PdfColor(0.86, 0.89, 0.94);
  static const softBorder = _PdfColor(0.91, 0.93, 0.96);
  static const divider = _PdfColor(0.82, 0.86, 0.91);
  static const text = _PdfColor(0.06, 0.10, 0.18);
  static const textMuted = _PdfColor(0.39, 0.46, 0.57);
  static const blue = _PdfColor(0.12, 0.33, 0.62);
  static const blueSoft = _PdfColor(0.91, 0.95, 0.99);
  static const green = _PdfColor(0.18, 0.52, 0.29);
  static const orange = _PdfColor(0.82, 0.36, 0.06);
  static const amber = _PdfColor(0.76, 0.49, 0.08);
  static const red = _PdfColor(0.72, 0.16, 0.18);
  static const purple = _PdfColor(0.42, 0.35, 0.72);
}

class _PdfPage {
  final double width;
  final double height;
  final List<String> ops = [];

  _PdfPage(this.width, this.height);

  void rect(
    double x,
    double y,
    double w,
    double h, {
    required _PdfColor fill,
    _PdfColor? stroke,
  }) {
    ops.add('${_rgb(fill)} rg ${_num(x)} ${_num(y)} ${_num(w)} ${_num(h)} re f');
    if (stroke != null) {
      ops.add('${_rgb(stroke)} RG ${_num(x)} ${_num(y)} ${_num(w)} ${_num(h)} re S');
    }
  }

  void line(double x1, double y1, double x2, double y2, _PdfColor color) {
    ops.add('${_rgb(color)} RG ${_num(x1)} ${_num(y1)} m ${_num(x2)} ${_num(y2)} l S');
  }

  void image(String name, double x, double y, double w, double h) {
    ops.add('q ${_num(w)} 0 0 ${_num(h)} ${_num(x)} ${_num(y)} cm /$name Do Q');
  }

  void text(
    String value,
    double x,
    double y, {
    double size = 10,
    _PdfColor color = _PdfColor.text,
    bool bold = false,
  }) {
    final font = bold ? 'F2' : 'F1';
    ops.add(
      'BT /$font ${_num(size)} Tf ${_rgb(color)} rg 1 0 0 1 ${_num(x)} ${_num(y)} Tm (${_escape(_pdfSafe(value))}) Tj ET',
    );
  }

  String content() => ops.join('\n');

  String _rgb(_PdfColor color) => '${_num(color.r)} ${_num(color.g)} ${_num(color.b)}';

  String _num(num value) => value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');

  String _escape(String value) {
    return value
        .replaceAll('\\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
  }

  String _pdfSafe(String value) {
    final buffer = StringBuffer();
    for (final codeUnit in value.codeUnits) {
      buffer.write(codeUnit <= 255 ? String.fromCharCode(codeUnit) : '?');
    }
    return buffer.toString();
  }
}

class _PdfDocument {
  final List<_PdfPage> pages;
  final List<_PdfImage> images;

  _PdfDocument(this.pages, {this.images = const []});

  Uint8List build() {
    final objects = <String>[];
    objects.add('<< /Type /Catalog /Pages 2 0 R >>');
    final pageKids = [
      for (var i = 0; i < pages.length; i++) '${3 + i * 2} 0 R',
    ].join(' ');
    objects.add('<< /Type /Pages /Kids [$pageKids] /Count ${pages.length} >>');

    final imageObject = 3 + pages.length * 2;
    final fontObject = imageObject + images.length;
    final boldFontObject = fontObject + 1;
    final xObjects = images.isEmpty
        ? ''
        : '/XObject << ${[
            for (var i = 0; i < images.length; i++)
              '/${images[i].name} ${imageObject + i} 0 R',
          ].join(' ')} >>';
    for (var i = 0; i < pages.length; i++) {
      final pageObject = 3 + i * 2;
      final contentObject = pageObject + 1;
      final page = pages[i];
      objects.add(
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${page.width.toInt()} ${page.height.toInt()}] /Resources << /Font << /F1 $fontObject 0 R /F2 $boldFontObject 0 R >> $xObjects >> /Contents $contentObject 0 R >>',
      );
      final content = page.content();
      objects.add(
        '<< /Length ${latin1.encode(content).length} >>\nstream\n$content\nendstream',
      );
    }

    for (final image in images) {
      final content = latin1.decode(image.bytes);
      objects.add(
        '<< /Type /XObject /Subtype /Image /Width ${image.width} /Height ${image.height} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Length ${image.bytes.length} >>\nstream\n$content\nendstream',
      );
    }

    objects.add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');
    objects.add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>');

    final buffer = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[0];
    var byteOffset = latin1.encode(buffer.toString()).length;
    for (var i = 0; i < objects.length; i++) {
      offsets.add(byteOffset);
      final objectText = '${i + 1} 0 obj\n${objects[i]}\nendobj\n';
      buffer.write(objectText);
      byteOffset += latin1.encode(objectText).length;
    }
    final xrefOffset = byteOffset;
    buffer.write('xref\n0 ${objects.length + 1}\n');
    buffer.write('0000000000 65535 f \n');
    for (final offset in offsets.skip(1)) {
      buffer.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }
    buffer.write(
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF',
    );
    return Uint8List.fromList(latin1.encode(buffer.toString()));
  }
}
