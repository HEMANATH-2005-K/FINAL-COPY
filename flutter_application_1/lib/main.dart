// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

// Pages imports
import 'pages/dashboard_page.dart';
import 'theme/app_theme.dart';
import 'pages/help.dart';
import 'pages/ruleengine.dart';
import 'pages/errorlog.dart';
import 'pages/vibrationmonitoring.dart';
import 'pages/load.dart';
import 'pages/datahub.dart';
import 'pages/reports.dart';
import 'pages/alerts.dart';
import 'pages/settings.dart';
import 'pages/machine_management.dart';
import 'pages/gateway_management.dart';
import 'pages/device_management.dart';
import 'pages/operationslog.dart';
import 'pages/cranemonitoring.dart';
import 'pages/brakemonitoring.dart';
import 'pages/temperaturemonitor.dart';
import 'pages/energymonitoring.dart';

import 'auth_screen_manager.dart';
import 'widgets/sidebar.dart';
import 'professional_bot.dart';
import 'mqtt_demo_page.dart';
import '../live_stream.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  developer.log("🚀 Initializing Supabase...");

  try {
    await Supabase.initialize(
      url: "https://lfystyacxejezdsvpkhg.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxmeXN0eWFjeGVqZXpkc3Zwa2hnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MzM5NzAsImV4cCI6MjA3NzMwOTk3MH0.PrFlVBg9vQoK1X1aFbuaOmNHavCFsvzy2g76_oSo7Tc",
    );

    developer.log("✅ Supabase initialized");

    final supabase = Supabase.instance.client;
    await supabase.from("load_readings").select().limit(1);
  } catch (e, st) {
    developer.log("❌ Supabase initialization failed: $e", stackTrace: st);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      return Scaffold(
        body: Center(
          child: Text(
            "⚠️ Error Occurred\n${errorDetails.exception}",
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    };

    return MaterialApp(
      title: "CraneIQ",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthScreenManagerWrapper(),

      /// ✅ Fixed Route Table
      routes: {
        '/dashboard': (context) => const DashboardWrapper(),
        '/mqtt': (context) => MQTTDemoPage(),
        '/help': (context) => const HelpPage(),
        '/ruleengine': (context) => const RulesEnginePage(),

        /// ❌ Removed const (these pages don't have const constructors)
        '/errorlog': (context) => const ErrorLogsPage(),
        '/brakemonitoring': (context) => const BrakeStatusPage(),

        '/vibration': (context) => const VibrationMonitoringPage(),
        '/load': (context) => const LoadLiftLogPage(),
        '/datahub': (context) => const DataHubPage(),
        '/reports': (context) => ReportsPage(),
        '/alerts': (context) => const AlertsDashboardPage(),
        '/settings': (context) => const SettingsPage(),
        '/machine_management': (context) => const MachineManagementPage(),
        '/gateway_management': (context) => const GatewayManagementPage(),
        '/device_management': (context) => const DeviceManagementPage(),
        '/operations_log': (context) => const OperationsLogPage(),
        '/zonecontrol': (context) => const CraneMonitoringScreen(),
        '/temperature': (context) => const TemperatureMonitoringPage(),
        '/energy_monitoring': (context) => const EnergyMonitoringDashboard(),
        '/livestream': (context) => LiveStreamWithGraph(),
      },

      /// ✅ FIXED — No compiler crash
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text("Page Not Found")),
            drawer: Sidebar(onItemSelected: (_) {}),
            body: Center(
              child: Text(
                "❌ Route not found:\n${settings.name}",
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Adds bot floating to ALL auth screens
class AuthScreenManagerWrapper extends StatelessWidget {
  const AuthScreenManagerWrapper({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(children: const [AuthScreenManager(), ProfessionalBot()]),
  );
}

/// Adds bot to main dashboard
class DashboardWrapper extends StatelessWidget {
  const DashboardWrapper({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(children: const [DashboardPage(), ProfessionalBot()]),
  );
}
