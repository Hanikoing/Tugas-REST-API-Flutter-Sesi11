
import 'package:flutter/material.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String books = '/books';
  static const String bookDetail = '/books/detail';
  static const String profile = '/profile';
}

/// Navigator global agar interceptor Dio bisa
/// mengarahkan user ke halaman login saat token tidak valid.
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

void redirectToLogin() {
  navigatorKey.currentState?.pushNamedAndRemoveUntil(
    AppRoutes.login,
    (_) => false,
  );
}
