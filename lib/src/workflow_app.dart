import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'core/models.dart';
import 'core/session_store.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/home_shell.dart';

class WorkflowApp extends StatefulWidget {
  const WorkflowApp({super.key});

  @override
  State<WorkflowApp> createState() => _WorkflowAppState();
}

class _WorkflowAppState extends State<WorkflowApp> {
  late final SessionStore _sessionStore;
  UserSession? _session;
  bool _loading = true;
  bool _showRegister = false;

  @override
  void initState() {
    super.initState();
    _sessionStore = SessionStore();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final session = await _sessionStore.read();
    if (!mounted) return;
    setState(() {
      _session = session;
      _loading = false;
    });
  }

  Future<void> _handleLogin(UserSession session) async {
    await _sessionStore.save(session);
    if (!mounted) return;
    setState(() {
      _session = session;
      _showRegister = false;
    });
    // FCM en background, sin bloquear el flujo de login
    _registerFcmToken(session.accessToken);
  }

  Future<void> _handleLogout() async {
    await _sessionStore.clear();
    if (!mounted) return;
    setState(() {
      _session = null;
      _showRegister = false;
    });
  }

  Future<void> _registerFcmToken(String accessToken) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) {
        await AuthRepository().saveFcmToken(
          accessToken: accessToken,
          fcmToken: token,
        );
      }
    } catch (_) {
      // Firebase no disponible, se omite
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workflow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F6),
        useMaterial3: true,
      ),
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _session != null
              ? HomeShell(
                  session: _session!,
                  sessionStore: _sessionStore,
                  onLogout: _handleLogout,
                )
              : _showRegister
                  ? RegisterScreen(
                      onRegister: _handleLogin,
                      onBack: () => setState(() => _showRegister = false),
                    )
                  : LoginScreen(
                      onLogin: _handleLogin,
                      onRegister: () => setState(() => _showRegister = true),
                    ),
    );
  }
}
