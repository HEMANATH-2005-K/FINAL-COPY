import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class TestConnectionPage extends StatelessWidget {
  const TestConnectionPage({super.key});

  Future<Map<String, dynamic>> _testAllConnections() async {
    try {
      // Use only methods available in SupabaseService
      final load = await SupabaseService.getLoadReadings();
      final vib = await SupabaseService.getVibrationData();
      final energy = await SupabaseService.getEnergyUsage();
      final temp = await SupabaseService.getTemperatureData();
      final brake = await SupabaseService.getBrakeStatus();
      final zones = await SupabaseService.getZoneLocations();

      final errors = await SupabaseService.getErrorLogs();
      final reports = await SupabaseService.getReports();
      final exports = await SupabaseService.getDataExports();

      final machines = await SupabaseService.getMachines();
      final gateways = await SupabaseService.getIotGateways();
      final devices = await SupabaseService.getDevices();
      final users = await SupabaseService.getAppUsers();

      return {
        'status': '✅ CONNECTED',
        'tables': {
          'load_readings': load.length,
          'vibration_data': vib.length,
          'energy_usage': energy.length,
          'temperature_data': temp.length,
          'brake_status': brake.length,
          'zone_locations': zones.length,
          'error_logs': errors.length,
          'reports': reports.length,
          'data_exports': exports.length,
          'machines': machines.length,
          'iot_gateways': gateways.length,
          'devices': devices.length,
          'app_users': users.length,
        },
        'error': null,
      };
    } catch (e) {
      return {
        'status': '❌ DISCONNECTED',
        'tables': <String, int>{},
        'error': e.toString(),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Connection Test')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _testAllConnections(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data'));
          }

          final data = snapshot.data!;
          final status = data['status'] as String? ?? '❌ DISCONNECTED';
          final Map<String, int> tables =
              (data['tables'] as Map?)?.cast<String, int>() ?? {};

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Card(
                  color: status.contains('✅') ? Colors.green : Colors.red,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...tables.entries.map(
                  (e) =>
                      _buildTestResult(_humanize(e.key), '${e.value} records'),
                ),
                if (data['error'] != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Error: ${data['error']}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTestResult(String title, String result) {
    final zero = result.startsWith('0 ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        zero ? Icons.error : Icons.check_circle,
        color: zero ? Colors.orange : Colors.green,
      ),
      title: Text(title),
      subtitle: Text(result),
    );
  }

  String _humanize(String table) {
    // simple prettifier for table keys
    return table
        .replaceAll('_', ' ')
        .replaceAll('iot', 'IoT')
        .split(' ')
        .map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}')
        .join(' ');
  }
}
