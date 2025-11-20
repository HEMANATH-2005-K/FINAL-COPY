import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final Function(String)? onItemSelected;

  const Sidebar({super.key, this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1E3A5F),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF152642),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.apartment, color: Color(0xFF1E3A5F)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CraneIQ Pro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Industrial Monitoring',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildSectionHeader('MONITORING'),
                  _drawerItem(Icons.dashboard, 'Dashboard', '/dashboard', context),
                  _drawerItem(Icons.history, 'Operations Log', '/operations_log', context),
                  _drawerItem(Icons.monitor_weight, 'Load Monitoring', '/load', context),
                  _drawerItem(Icons.vibration, 'Vibration', '/vibration', context),
                  _drawerItem(Icons.flash_on, 'Energy', '/energy_monitoring', context),
                  _drawerItem(Icons.thermostat, 'Temperature', '/temperature', context),
                  _drawerItem(Icons.warning_amber, 'Brake Monitoring', '/brakemonitoring', context),
                  _drawerItem(Icons.map, 'Zone Control', '/zonecontrol', context),

                  _buildSectionHeader('MANAGEMENT'),
                  _drawerItem(Icons.rule, 'Rule Engine', '/ruleengine', context),
                  _drawerItem(Icons.storage, 'Data Hub', '/datahub', context),
                  _drawerItem(Icons.error, 'Error Log', '/errorlog', context),
                  _drawerItem(Icons.description, 'Reports', '/reports', context),
                  _drawerItem(Icons.notifications, 'Alerts', '/alerts', context),

                  _buildSectionHeader('SETTINGS'),
                  _drawerItem(Icons.settings, 'Settings', '/settings', context),
                  _drawerItem(Icons.build, 'Machine Management', '/machine_management', context),
                  _drawerItem(Icons.router, 'IOT-Gateway Management', '/gateway_management', context),
                  _drawerItem(Icons.devices, 'Device Management', '/device_management', context),
                  _drawerItem(Icons.help_outline, 'Help', '/help', context),
                ],
              ),
            ),

            // User Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF152642),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Pro Plan',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, String route, BuildContext context) {
    final bool isActive = ModalRoute.of(context)?.settings.name == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2D4A7C) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 20),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        minLeadingWidth: 0,
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (!isActive) {
            Navigator.pushNamed(context, route);
          }
          onItemSelected?.call(title);
        },
      ),
    );
  }
}