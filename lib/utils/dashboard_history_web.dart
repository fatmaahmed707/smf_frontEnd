// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

class DashboardHistory {
  static const _topLevelRoutes = {
    '/dashboard',
    '/profile',
    '/announcements',
    '/login',
    '/register',
  };

  static String currentSlug() {
    final hash = html.window.location.hash;
    var value = hash.startsWith('#') ? hash.substring(1) : hash;
    if (value.isEmpty) return '';

    final uri = Uri.tryParse(value.startsWith('/') ? value : '/$value');
    final tab = uri?.queryParameters['tab'];
    if (tab != null && tab.trim().isNotEmpty) {
      return tab.trim();
    }

    if (value.startsWith('/')) value = value.substring(1);
    if (value.startsWith('dashboard/')) {
      value = value.substring('dashboard/'.length);
    }
    if (value.startsWith('dashboard?')) return 'dashboard';
    return value.trim();
  }

  static String currentRoute(bool authenticated) {
    final hashRoute = _routeFromHash();
    final pathRoute = _routeFromPath();
    final route = hashRoute ?? pathRoute;

    if (!authenticated) {
      return route == '/register' ? '/register' : '/login';
    }

    if (route == '/login' || route == '/register') return '/dashboard';
    return route ?? '/dashboard';
  }

  static void replace(String slug) {
    html.window.history.replaceState(null, '', _urlFor(slug));
  }

  static void push(String slug) {
    if (currentSlug() == slug) return;
    html.window.history.replaceState(null, '', _urlFor(slug));
  }

  static Stream<String> get changes =>
      html.window.onPopState.map((_) => currentSlug());

  static String _urlFor(String slug) {
    return '#/dashboard?tab=${Uri.encodeQueryComponent(slug)}';
  }

  static String? _routeFromHash() {
    final hash = html.window.location.hash;
    if (hash.isEmpty) return null;

    final raw = hash.startsWith('#') ? hash.substring(1) : hash;
    if (raw.trim().isEmpty) return null;

    final uri = Uri.tryParse(raw.startsWith('/') ? raw : '/$raw');
    return _normalizeRoute(uri?.path);
  }

  static String? _routeFromPath() {
    final path = html.window.location.pathname;
    return _normalizeRoute(path);
  }

  static String? _normalizeRoute(String? path) {
    if (path == null || path.trim().isEmpty || path == '/') return null;
    final normalized = path.startsWith('/') ? path : '/$path';
    if (_topLevelRoutes.contains(normalized)) return normalized;

    final segments = normalized.split('/').where((part) => part.isNotEmpty);
    if (segments.isEmpty) return null;
    final firstSegment = segments.first;
    final topLevel = '/$firstSegment';
    return _topLevelRoutes.contains(topLevel) ? topLevel : null;
  }
}
