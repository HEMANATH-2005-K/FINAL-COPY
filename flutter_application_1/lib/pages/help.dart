import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double horizontalPadding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const Sidebar(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF1E90FF), size: 24),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'Help Center',
          style: TextStyle(
            color: const Color(0xFF263244),
            fontWeight: FontWeight.w700,
            fontSize: isMobile ? 18 : 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Color(0xFF1E90FF), size: 22),
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
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search help articles...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF666666), size: 20),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),

              // Quick Actions
              if (isMobile) ...[
                const Text(
                  'Quick Help',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF263244)),
                ),
                const SizedBox(height: 10),
                _buildQuickActions(),
                const SizedBox(height: 20),
              ],

              // Getting Started Section
              _buildSectionHeader(
                title: 'Getting Started',
                icon: Icons.play_arrow_rounded,
                color: const Color(0xFF1E90FF),
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                title: 'System Overview',
                content: 'CraneIQ is an advanced monitoring system designed to provide real-time insights into your crane operations. The system tracks multiple parameters to ensure optimal performance and safety.\n\nKey features include:\n• Real-time monitoring of load, vibration, temperature, and energy\n• Historical data analysis with customizable reports\n• Automated alerts for abnormal conditions\n• Predictive maintenance recommendations\n• Multi-user access with role-based permissions',
                icon: Icons.analytics_outlined,
              ),
              const SizedBox(height: 10),
              _buildSectionCard(
                title: 'Dashboard Guide',
                content: 'The dashboard provides a comprehensive overview of your crane\'s status:\n• Status Cards: Quick view of each crane\'s current state\n• OEE Metrics: Overall Equipment Effectiveness scores\n• Quick Stats: Power consumption, current draw, and utilization\n• Filter Bar: Quickly sort cranes by status (Working, Idle, etc.)\n\nClick on any crane card to view detailed metrics and historical data.',
                icon: Icons.dashboard_outlined,
              ),
              const SizedBox(height: 24),

              // Operations Log Section
              _buildSectionHeader(
                title: 'Operations Log',
                icon: Icons.list_alt,
                color: const Color(0xFFFF6B35),
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                title: 'Overview',
                content: 'The Operations Log provides a complete record of all crane operations, including hoisting, traveling, and switching activities. This feature helps you track equipment usage, analyze operational patterns, and maintain compliance with safety regulations.',
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: 10),
              _buildSectionCard(
                title: 'Key Features',
                content: '• Real-time Tracking: Monitor all crane operations as they happen with timestamped records.\n• Advanced Filtering: Filter by crane, operation type, and date range for focused analysis.\n• Metrics Dashboard: Quick-view summary of operation counts and durations.\n• Load Tracking: Record and analyze load weights for each operation.',
                icon: Icons.featured_play_list_outlined,
              ),
              const SizedBox(height: 10),
              _buildSectionCard(
                title: 'Understanding the Interface',
                content: '• Metrics Dashboard: The compact dashboard at the top provides an overview of recent activity.\n  - Hoist Operations: Total lifts (up/down breakdown)\n  - CT (Cross Travel): Left/right movements\n  - LT (Long Travel): Forward/reverse movements\n  - Switching: Mode changes\n  - Duration: Total operating time\n  - Load: Total weight handled\n• Operations Table: The main table displays detailed records of each operation:\n  Column | Description | Example\n  Timestamp | Exact date and time of operation | 2023-06-15 08:23:45\n  Crane ID | Identifier for the specific crane | CRN-001\n  Operation | Type of movement with color coding | Hoist Up\n  Duration | How long the operation took | 2:15 (minutes:seconds)\n  Load | Weight being handled | 3,250 kg\n• Operation Type Colors:\n  - Hoist Up: Lifting operations (light green)\n  - Hoist Down: Lowering operations (green)\n  - CT Left: Cross travel to left (blue)\n  - CT Right: Cross travel to right (light blue)\n  - LT Forward: Long travel forward (yellow)\n  - LT Reverse: Long travel reverse (light yellow)\n  - Switch: Mode changes (gray)',
                icon: Icons.visibility_outlined,
              ),
              const SizedBox(height: 10),
              _buildSectionCard(
                title: 'Filtering Operations',
                content: 'Use the filter controls to focus on specific data:\n1. Select a Crane: Choose a specific crane or view all cranes. Filter → Crane → Select from dropdown\n2. Choose Operation Type: Filter by hoist, travel, or switching operations. Filter → Operation Type → Select type\n3. Set Date Range: View today\'s operations or historical data. Filter → Date Range → Choose period\n4. Apply Filters: Click "Apply Filters" to update the view',
                icon: Icons.filter_alt_outlined,
              ),
              const SizedBox(height: 10),
              _buildSectionCard(
                title: 'Advanced Features',
                content: '• Data Export: Export operation logs to CSV, Excel, or PDF for reporting. Reports → Export Operations Log\n• Custom Alerts: Set notifications for unusual operation patterns. Alerts → New Alert → Operation Parameters\n• Trend Analysis: View operational trends over time. Reports → Operation Trends\n• Utilization Reports: Calculate equipment utilization rates. Reports → Utilization Analysis',
                icon: Icons.rocket_launch_outlined,
              ),
              const SizedBox(height: 24),

              // Troubleshooting Section
              _buildSectionHeader(
                title: 'Troubleshooting',
                icon: Icons.build_circle_outlined,
                color: const Color(0xFF34C759),
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                title: 'Missing Operation Records',
                content: '• Verify the crane\'s sensors are properly connected\n• Check your date range filters aren\'t too restrictive\n• Confirm the crane was operational during the selected period',
                icon: Icons.warning_amber_outlined,
                isWarning: true,
              ),
              const SizedBox(height: 10),
              _buildSectionCard(
                title: 'Incorrect Operation Types',
                content: '• Check sensor calibration on the crane\n• Verify the crane configuration in Settings\n• Contact support if issues persist',
                icon: Icons.error_outline,
                isWarning: true,
              ),
              const SizedBox(height: 24),

              // FAQ Section
              _buildSectionHeader(
                title: 'Frequently Asked Questions',
                icon: Icons.help_outline,
                color: const Color(0xFFFF9500),
              ),
              const SizedBox(height: 12),
              _buildFAQSection(),
              const SizedBox(height: 24),

              // Contact Support Section
              _buildSectionHeader(
                title: 'Contact Support',
                icon: Icons.support_agent,
                color: const Color(0xFFAF52DE),
              ),
              const SizedBox(height: 12),
              _buildContactSupport(isMobile: isMobile),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF263244),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String content, IconData? icon, bool isWarning = false}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isWarning
                ? [Colors.red.shade50, Colors.orange.shade50]
                : [Colors.white, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isWarning ? Colors.red.shade100 : const Color(0xFF1E90FF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isWarning ? Colors.red : const Color(0xFF1E90FF),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isWarning ? Colors.red.shade700 : const Color(0xFF1E90FF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                content,
                style: const TextStyle(
                  color: Color(0xFF444444),
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final List<Map<String, dynamic>> quickActions = [
      {'icon': Icons.video_library, 'title': 'Video Tutorials', 'color': const Color(0xFF1E90FF)},
      {'icon': Icons.download, 'title': 'Download Guides', 'color': const Color(0xFF34C759)},
      {'icon': Icons.bug_report, 'title': 'Report Issue', 'color': const Color(0xFFFF3B30)},
      {'icon': Icons.update, 'title': 'Check Updates', 'color': const Color(0xFFFF9500)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: quickActions.length,
      itemBuilder: (context, index) {
        final action = quickActions[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [action['color'].withOpacity(0.1), action['color'].withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action['icon'], color: action['color'], size: 22),
                  const SizedBox(height: 6),
                  Text(
                    action['title'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF263244),
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

  Widget _buildFAQSection() {
    return Column(
      children: [
        _buildFAQItem(
          question: 'How do I set up custom alerts for vibration monitoring?',
          answer: 'Go to Alerts > New Alert > Vibration Parameters to configure custom vibration thresholds and notifications.',
        ),
        _buildFAQItem(
          question: 'What do the different vibration status colors mean?',
          answer: 'Green indicates normal operation, Yellow shows warning levels, and Red represents critical vibration that requires immediate attention.',
        ),
        _buildFAQItem(
          question: 'How often is vibration data updated?',
          answer: 'Vibration data updates every 5 seconds in real-time mode, ensuring you have the most current information.',
        ),
        _buildFAQItem(
          question: 'Can I export vibration data for analysis?',
          answer: 'Yes, you can export data in multiple formats including CSV and Excel via Reports > Export Data section.',
        ),
        _buildFAQItem(
          question: 'How far back does the operations log store data?',
          answer: 'The system stores up to 1 year of operational data, with extended storage options available for enterprise plans.',
        ),
        _buildFAQItem(
          question: 'Can I track multiple cranes simultaneously?',
          answer: 'Yes, the dashboard supports multi-crane views and allows you to monitor all your equipment in one centralized interface.',
        ),
        _buildFAQItem(
          question: 'How accurate are the operation duration measurements?',
          answer: 'Duration measurements are accurate to the second, based on precise sensor data and timestamp recording.',
        ),
      ],
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF1E90FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline, color: Color(0xFF1E90FF), size: 18),
          ),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF263244),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(44, 0, 12, 12),
              child: Text(
                answer,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSupport({required bool isMobile}) {
    final List<Map<String, dynamic>> contactMethods = [
      {
        'icon': Icons.email_outlined,
        'title': 'Email Support',
        'details': 'support@craneiq.com',
        'subtitle': 'Typically responds within\n2 business hours',
        'color': const Color(0xFF1E90FF),
      },
      {
        'icon': Icons.phone_outlined,
        'title': 'Phone Support',
        'details': '+1 (800) 555-0199',
        'subtitle': '24/7 for critical issues',
        'color': const Color(0xFF34C759),
      },
      {
        'icon': Icons.chat_bubble_outline,
        'title': 'Live Chat',
        'details': 'Available in-app',
        'subtitle': 'Mon-Fri, 9am-5pm EST',
        'color': const Color(0xFFFF9500),
      },
      {
        'icon': Icons.library_books_outlined,
        'title': 'Knowledge Base',
        'details': 'docs.craneiq.com',
        'subtitle': 'Detailed guides and\ntutorials',
        'color': const Color(0xFFAF52DE),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: isMobile ? 0.85 : 0.9, // Adjusted for mobile
      ),
      itemCount: contactMethods.length,
      itemBuilder: (context, index) {
        final method = contactMethods[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [method['color'].withOpacity(0.1), method['color'].withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14), // Reduced padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8), // Reduced padding
                    decoration: BoxDecoration(
                      color: method['color'].withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(method['icon'], color: method['color'], size: 20), // Reduced icon size
                  ),
                  const SizedBox(height: 8), // Reduced spacing
                  Text(
                    method['title'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12, // Reduced font size
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF263244),
                    ),
                  ),
                  const SizedBox(height: 4), // Reduced spacing
                  Text(
                    method['details'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11, // Reduced font size
                      fontWeight: FontWeight.w500,
                      color: method['color'],
                    ),
                  ),
                  const SizedBox(height: 4), // Reduced spacing
                  Text(
                    method['subtitle'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9, // Reduced font size
                      color: Color(0xFF666666),
                      height: 1.2, // Reduced line height
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
}