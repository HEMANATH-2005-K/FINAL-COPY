import 'package:flutter/material.dart';
import '../professional_bot.dart';
import '../widgets/sidebar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../mqtt_service.dart'; // ✅ IMPORT MQTT SERVICE

// ✅ MOCK DATA - Add before class
class CraneModel {
  final String id;
  final String name;
  final String status;
  final int health;
  final double currentLoad;
  final double capacity;
  final List<String> deviceIds;
  final DateTime updatedAt;

  CraneModel({
    required this.id,
    required this.name,
    required this.status,
    required this.health,
    required this.currentLoad,
    required this.capacity,
    required this.deviceIds,
    required this.updatedAt,
  });
}

class OeeModel {
  final double oee;
  final double availability;
  final double performance;
  final double quality;

  OeeModel({
    required this.oee,
    required this.availability,
    required this.performance,
    required this.quality,
  });
}

// ✅ MOCK CRANES DATA
final List<CraneModel> mockCranes = [
  CraneModel(
    id: 'CRANE001',
    name: 'Tower Crane A',
    status: 'Working',
    health: 95,
    currentLoad: 1250,
    capacity: 5000,
    deviceIds: ['SENSOR01', 'SENSOR02'],
    updatedAt: DateTime.now().subtract(Duration(minutes: 5)),
  ),
  CraneModel(
    id: 'CRANE002',
    name: 'Mobile Crane B',
    status: 'Idle',
    health: 87,
    currentLoad: 0,
    capacity: 3000,
    deviceIds: ['SENSOR03'],
    updatedAt: DateTime.now().subtract(Duration(hours: 2)),
  ),
  CraneModel(
    id: 'CRANE003',
    name: 'Gantry Crane C',
    status: 'Overload',
    health: 45,
    currentLoad: 4800,
    capacity: 4500,
    deviceIds: ['SENSOR04', 'SENSOR05'],
    updatedAt: DateTime.now().subtract(Duration(minutes: 30)),
  ),
];

// ✅ MOCK OEE DATA
final OeeModel mockOee = OeeModel(
  oee: 0.85,
  availability: 0.92,
  performance: 0.88,
  quality: 0.95,
);

// ✅ CALCULATE TOTAL POWER AND CURRENT DRAW
double get totalPower {
  return mockCranes.fold(0, (sum, crane) {
    double power = 0;
    if (crane.status == 'Working')
      power = 8.5;
    else if (crane.status == 'Idle')
      power = 2.0;
    else if (crane.status == 'Overload')
      power = 12.0;
    return sum + power;
  });
}

double get currentDraw {
  return mockCranes.fold(0, (sum, crane) {
    double current = 0;
    if (crane.status == 'Working')
      current = 15.5;
    else if (crane.status == 'Idle')
      current = 5.0;
    else if (crane.status == 'Overload')
      current = 20.0;
    return sum + current;
  });
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MQTTService _mqttService = MQTTService();
  String? filterStatus;
  List<Map<String, dynamic>> craneData = [];
  bool isLoading = true;
  bool _isMQTTConnected = false;
  bool _showMQTTDialog = false; // ✅ ADD THIS FOR MQTT DIALOG

  @override
  void initState() {
    super.initState();
    _initializeData();
    _connectMQTT();
  }

  // ✅ INITIALIZE DATA METHOD
  void _initializeData() {
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _connectMQTT() async {
    try {
      final connected = await _mqttService.connect();
      setState(() {
        _isMQTTConnected = connected;
      });

      if (connected) {
        _mqttService.messageStream.listen((message) {
          print('📨 DASHBOARD RECEIVED: $message');
          // You can process MQTT messages here for real-time updates
        });
      }
    } catch (e) {
      print('❌ MQTT Connection error: $e');
    }
  }

  // ✅ SHOW MQTT STATUS DIALOG
  void _showMQTTStatusDialog() {
    setState(() {
      _showMQTTDialog = true;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _isMQTTConnected ? Icons.cloud_done : Icons.cloud_off,
                color: _isMQTTConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                'MQTT Connection Status',
                style: TextStyle(
                  color: const Color(0xFF1E3A5F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isMQTTConnected ? 'CONNECTED' : 'DISCONNECTED',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isMQTTConnected ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              if (_isMQTTConnected) ...[
                _buildMQTTStatusItem('Status', 'Connected to MQTT Broker'),
                _buildMQTTStatusItem('Server', 'ws://YOUR DEVICE IP:9001'),
                _buildMQTTStatusItem('Topic', 'crane/operations'),
                _buildMQTTStatusItem('Client', 'Web Client Active'),
              ] else ...[
                _buildMQTTStatusItem('Status', 'Disconnected from Broker'),
                _buildMQTTStatusItem('Server', 'ws://YOUR DEVICE IP:9001'),
                _buildMQTTStatusItem('Error', 'Unable to establish connection'),
                _buildMQTTStatusItem('Action', 'Check broker availability'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showMQTTDialog = false;
                });
              },
              child: const Text('CLOSE'),
            ),
            if (!_isMQTTConnected)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _reconnectMQTT();
                },
                child: const Text('RECONNECT'),
              ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        _showMQTTDialog = false;
      });
    });
  }

  Widget _buildMQTTStatusItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$title:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  // ✅ RECONNECT MQTT
  Future<void> _reconnectMQTT() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reconnecting to MQTT Broker...'),
        duration: Duration(seconds: 2),
      ),
    );

    final connected = await _mqttService.connect();
    setState(() {
      _isMQTTConnected = connected;
    });

    if (connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully reconnected to MQTT!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reconnect to MQTT'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listedCranes = filterStatus == null
        ? mockCranes
        : mockCranes.where((c) => c.status == filterStatus).toList();

    return Scaffold(
      key: _scaffoldKey,
      drawer: Sidebar(
        onItemSelected: (title) {
          switch (title) {
            case 'Dashboard':
              break;
            case 'Operations Log':
              Navigator.of(context).pushNamed('/operations');
              break;
            case 'Help':
              Navigator.of(context).pushNamed('/help');
              break;
            default:
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Coming soon: $title')));
          }
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A5F),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF1E3A5F)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'CraneIQ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // ✅ ADD CLOUD ICON TO TOP RIGHT CORNER
        actions: [
          IconButton(
            onPressed: _showMQTTStatusDialog,
            icon: Icon(
              _isMQTTConnected ? Icons.cloud : Icons.cloud_off,
              color: _isMQTTConnected ? Colors.green : Colors.red,
            ),
            tooltip: 'MQTT Connection Status',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewCrane,
        backgroundColor: const Color(0xFF1E3A5F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ HEADER SECTION
                  _buildHeaderSection(),

                  const SizedBox(height: 20),

                  // ✅ QUICK STATS SECTION
                  _buildQuickStatsSection(),

                  const SizedBox(height: 20),

                  // ✅ OEE SECTION
                  _buildOEESection(),

                  const SizedBox(height: 20),

                  // ✅ FILTER CHIPS
                  _buildFilterChips(),

                  const SizedBox(height: 20),

                  // ✅ CRANE CARDS
                  _buildCraneCards(listedCranes),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ✅ FLOATING BOT
          ProfessionalBot(),
        ],
      ),
    );
  }

  // ✅ HEADER SECTION
  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A5F),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Real-time view of all crane operations',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      ],
    );
  }

  // ✅ QUICK STATS SECTION WITH REFRESH
  Widget _buildQuickStatsSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Quick Stats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              ),
              // ✅ REFRESH BUTTON
              IconButton(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh, color: Color(0xFF1E3A5F)),
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatCard(
                'Total Power',
                '${totalPower.toStringAsFixed(1)} kW',
                Icons.bolt,
                Colors.blue,
              ),
              _buildStatCard(
                'Current Draw',
                '${currentDraw.toStringAsFixed(1)} A',
                Icons.offline_bolt,
                Colors.orange,
              ),
              _buildStatCard(
                'Active Cranes',
                '${mockCranes.where((c) => c.status == 'Working').length}',
                Icons.build,
                Colors.green,
              ),
              _buildStatCard(
                'MQTT Status',
                _isMQTTConnected ? 'Connected' : 'Offline',
                Icons.cloud,
                _isMQTTConnected ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ ADD REFRESH METHOD
  void _refreshData() {
    setState(() {
      // Refresh your data here
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data refreshed'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // ✅ STAT CARD WIDGET
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ✅ OEE SECTION
  Widget _buildOEESection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Equipment Effectiveness',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              ),
              Text(
                'Updated today',
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildOEECard(
                  'OEE',
                  '${(mockOee.oee * 100).toInt()}%',
                  mockOee.oee,
                  Colors.indigo,
                ),
                const SizedBox(width: 12),
                _buildOEECard(
                  'Availability',
                  '${(mockOee.availability * 100).toInt()}%',
                  mockOee.availability,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildOEECard(
                  'Performance',
                  '${(mockOee.performance * 100).toInt()}%',
                  mockOee.performance,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildOEECard(
                  'Quality',
                  '${(mockOee.quality * 100).toInt()}%',
                  mockOee.quality,
                  Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ OEE CARD WIDGET
  Widget _buildOEECard(
    String title,
    String value,
    double percent,
    Color color,
  ) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ✅ FILTER CHIPS
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', null, const Color(0xFF1E3A5F)),
          const SizedBox(width: 8),
          _buildFilterChip('Working', 'Working', Colors.green),
          const SizedBox(width: 8),
          _buildFilterChip('Idle', 'Idle', Colors.orange),
          const SizedBox(width: 8),
          _buildFilterChip('Off', 'Off', Colors.grey),
          const SizedBox(width: 8),
          _buildFilterChip('Overload', 'Overload', Colors.red),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status, Color color) {
    final selected = filterStatus == status;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(color: selected ? Colors.white : color),
      ),
      selected: selected,
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color,
      checkmarkColor: Colors.white,
      onSelected: (_) => setState(() => filterStatus = status),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  // ✅ CRANE CARDS
  Widget _buildCraneCards(List<CraneModel> cranes) {
    return Column(
      children: cranes.map((crane) => _buildCraneCard(crane)).toList(),
    );
  }

  Widget _buildCraneCard(CraneModel crane) {
    Color getStatusColor(String status) {
      switch (status) {
        case 'Working':
          return Colors.green;
        case 'Idle':
          return Colors.orange;
        case 'Overload':
          return Colors.red;
        case 'Off':
          return Colors.grey;
        default:
          return Colors.blue;
      }
    }

    IconData getStatusIcon(String status) {
      switch (status) {
        case 'Working':
          return Icons.play_arrow;
        case 'Idle':
          return Icons.pause;
        case 'Overload':
          return Icons.warning;
        case 'Off':
          return Icons.power_off;
        default:
          return Icons.build;
      }
    }

    final color = getStatusColor(crane.status);
    final icon = getStatusIcon(crane.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crane.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ID: ${crane.id}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  crane.status.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCraneMetric(
                'Health',
                '${crane.health}%',
                Icons.health_and_safety,
              ),
              _buildCraneMetric(
                'Load',
                '${crane.currentLoad}kg',
                Icons.fitness_center,
              ),
              _buildCraneMetric(
                'Capacity',
                '${crane.capacity}kg',
                Icons.layers,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.devices, size: 14, color: Colors.black54),
              const SizedBox(width: 4),
              Text(
                'Devices: ${crane.deviceIds.join(', ')}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const Spacer(),
              Text(
                _timeAgo(crane.updatedAt),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCraneMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.black54),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  // ✅ ADD NEW CRANE (Basic implementation)
  void _addNewCrane() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Crane functionality - Coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
