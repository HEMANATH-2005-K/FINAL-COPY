import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFD),
      drawer: const Sidebar(),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF1E3A5F)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Color(0xFF1E3A5F)),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/dashboard', 
                (route) => false
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 20),

              // Settings Categories
              _buildSettingsCategories(context),
              const SizedBox(height: 20),

              // Account Settings
              _buildAccountSettings(),
              const SizedBox(height: 20),

              // Notification Settings
              _buildNotificationSettings(),
              const SizedBox(height: 20),

              // System Settings
              _buildSystemSettings(),
              const SizedBox(height: 20), // Added extra space at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings, color: Color(0xFF1E3A5F), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Settings & Configuration",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)), // Reduced font size
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "Manage your application settings and preferences",
          style: TextStyle(color: Colors.black54, fontSize: 13), // Reduced font size
        ),
      ],
    );
  }

  Widget _buildSettingsCategories(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {
        'icon': Icons.build,
        'title': 'Machine Management',
        'subtitle': 'Configure crane settings and parameters',
        'route': '/machine_management',
        'color': Colors.blue
      },
      {
        'icon': Icons.router,
        'title': 'Gateway Management',
        'subtitle': 'Manage IoT gateways and connections',
        'route': '/gateway_management',
        'color': Colors.green
      },
      {
        'icon': Icons.devices,
        'title': 'Device Management',
        'subtitle': 'Configure sensors and monitoring devices',
        'route': '/device_management',
        'color': Colors.orange
      },
      {
        'icon': Icons.notifications,
        'title': 'Alert Settings',
        'subtitle': 'Configure notification preferences',
        'route': '/alerts',
        'color': Colors.purple
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10, // Reduced spacing
        mainAxisSpacing: 10, // Reduced spacing
        childAspectRatio: 1.3, // Increased aspect ratio for more height
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final icon = category['icon'] as IconData;
        final title = category['title'] as String;
        final subtitle = category['subtitle'] as String;
        final route = category['route'] as String;
        final color = category['color'] as Color;

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, route),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12), // Reduced border radius
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8, // Reduced blur
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6), // Reduced padding
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6), // Reduced border radius
                    ),
                    child: Icon(icon, color: color, size: 18), // Reduced icon size
                  ),
                  const SizedBox(height: 10), // Reduced spacing
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), // Reduced font size
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: Colors.black54), // Reduced font size
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountSettings() {
    return Container(
      padding: const EdgeInsets.all(14), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Reduced border radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, // Reduced blur
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Account Settings",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)), // Reduced font size
          ),
          const SizedBox(height: 14), // Reduced spacing
          _buildSettingItem(
            Icons.person,
            'Profile Information',
            'Update your personal details and contact information',
            Icons.arrow_forward_ios,
            onTap: () {},
          ),
          _buildSettingItem(
            Icons.security,
            'Security & Privacy',
            'Manage password and privacy settings',
            Icons.arrow_forward_ios,
            onTap: () {},
          ),
          _buildSettingItem(
            Icons.workspace_premium,
            'Subscription Plan',
            'Pro Plan - Manage your subscription',
            Icons.arrow_forward_ios,
            onTap: () {},
          ),
          _buildSettingItem(
            Icons.language,
            'Language & Region',
            'English (US) - Change language preferences',
            Icons.arrow_forward_ios,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(14), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Reduced border radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, // Reduced blur
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Notification Settings",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)), // Reduced font size
          ),
          const SizedBox(height: 14), // Reduced spacing
          _buildNotificationToggle('Push Notifications', 'Receive alerts on your device', true),
          _buildNotificationToggle('Email Notifications', 'Get reports and alerts via email', true),
          _buildNotificationToggle('SMS Alerts', 'Critical alerts via text message', false),
          _buildNotificationToggle('Sound Alerts', 'Play sound for important notifications', true),
          _buildNotificationToggle('Vibration Alerts', 'Vibrate for critical alerts', true),
        ],
      ),
    );
  }

  Widget _buildSystemSettings() {
    return Container(
      padding: const EdgeInsets.all(14), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Reduced border radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, // Reduced blur
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "System Settings",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)), // Reduced font size
          ),
          const SizedBox(height: 14), // Reduced spacing
          _buildSettingItem(
            Icons.cloud_download,
            'Data Sync',
            'Auto-sync every 15 minutes - Connected',
            Icons.arrow_forward_ios,
            onTap: () {},
          ),
          _buildSettingItem(
            Icons.storage,
            'Data Retention',
            'Keep data for 12 months - 45GB used',
            Icons.arrow_forward_ios,
            onTap: () {},
          ),
          _buildSettingItem(
            Icons.backup,
            'Backup & Restore',
            'Last backup: Today 02:00 AM',
            Icons.arrow_forward_ios,
            onTap: () {},
          ),
          _buildSettingItem(
            Icons.bug_report,
            'Debug Mode',
            'Enabled - Logging all system events',
            Icons.arrow_forward_ios,
            onTap: () {},
          ),
          const SizedBox(height: 14), // Reduced spacing
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save, size: 16), // Reduced icon size
              label: const Text(
                "Save All Settings",
                style: TextStyle(fontSize: 13), // Reduced font size
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10), // Reduced padding
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Reduced border radius
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData leadingIcon, String title, String subtitle, IconData trailingIcon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6), // Reduced padding
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A5F).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6), // Reduced border radius
        ),
        child: Icon(leadingIcon, color: const Color(0xFF1E3A5F), size: 18), // Reduced icon size
      ),
      title: Text(
        title, 
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500) // Reduced font size
      ),
      subtitle: Text(
        subtitle, 
        style: const TextStyle(fontSize: 11, color: Colors.black54) // Reduced font size
      ),
      trailing: Icon(trailingIcon, color: Colors.grey, size: 14), // Reduced icon size
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 6), // Reduced padding
      minLeadingWidth: 36, // Reduced leading width
      dense: true, // Make list tile more compact
    );
  }

  Widget _buildNotificationToggle(String title, String subtitle, bool value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6), // Reduced padding
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A5F).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6), // Reduced border radius
        ),
        child: const Icon(Icons.notifications, color: Color(0xFF1E3A5F), size: 18), // Reduced icon size
      ),
      title: Text(
        title, 
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500) // Reduced font size
      ),
      subtitle: Text(
        subtitle, 
        style: const TextStyle(fontSize: 11, color: Colors.black54) // Reduced font size
      ),
      trailing: Transform.scale(
        scale: 0.8, // Reduced switch size
        child: Switch(
          value: value,
          onChanged: (newValue) {},
          activeThumbColor: const Color(0xFF1E3A5F),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 6), // Reduced padding
      minLeadingWidth: 36, // Reduced leading width
      dense: true, // Make list tile more compact
    );
  }
}