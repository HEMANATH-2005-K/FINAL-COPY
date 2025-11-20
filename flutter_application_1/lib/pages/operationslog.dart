// pages/operations_log.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../widgets/sidebar.dart';
import '../mqtt_service.dart';

class OperationLogEntry {
  final String timestamp;
  final String craneId;
  final String operation;
  final String description;
  final String operator;
  final double? weight;
  final double? height;
  final double? distance;

  OperationLogEntry({
    required this.timestamp,
    required this.craneId,
    required this.operation,
    required this.description,
    required this.operator,
    this.weight,
    this.height,
    this.distance,
  });
}

class OperationsLogPage extends StatefulWidget {
  const OperationsLogPage({super.key});
  @override
  State<OperationsLogPage> createState() => _OperationsLogPageState();
}

class _OperationsLogPageState extends State<OperationsLogPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MQTTService _mqttService = MQTTService();

  List<OperationLogEntry> _logEntries = [];
  List<Map<String, dynamic>> _databaseOperations = [];

  // Live counters for dashboard boxes
  Map<String, dynamic> _liveCounters = {
    'hoist_up': 0,
    'hoist_down': 0,
    'ct_left': 0,
    'ct_right': 0,
    'lt_forward': 0,
    'lt_reverse': 0,
    'switch': 0,
    'total_duration': '0:00:00',
    'current_load': 0.0,
    'is_powered_on': false, // ✅ NEW
  };

  int _selectedTab = 0;
  Timer? _liveUpdateTimer;
  final Random _random = Random();
  bool _isSaving = false;
  StreamSubscription<String>? _mqttSubscription; // ✅ ADD THIS
  bool _isMQTTConnected = false; // ✅ ADD THIS

  @override
  void initState() {
    super.initState();
    _initializeData();
    _connectMQTT(); // ✅ Call this first
    _startLiveUpdates();
    _loadLastSessionCounts();
  }

  @override
  void dispose() {
    _mqttSubscription?.cancel(); // ✅ ADD THIS
    _liveUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _loadOperationsFromDatabase();
  }

  Future<void> _loadOperationsFromDatabase() async {
    try {
      final operations = await SupabaseService.getOperationsLog();
      setState(() {
        _databaseOperations = operations;
        print('✅ Loaded ${operations.length} operations from database');
      });
    } catch (e) {
      print('❌ Error loading operations: $e');
      setState(() {
        _databaseOperations = _getSampleData();
      });
    }
  }

  Future<void> _loadLastSessionCounts() async {
    try {
      print('🔄 Loading last session counts...');
      final lastCounts = await SupabaseService.getLastSessionCounts();
      setState(() {
        _liveCounters['hoist_up'] = lastCounts['hoist_up'] ?? 0;
        _liveCounters['hoist_down'] = lastCounts['hoist_down'] ?? 0;
        _liveCounters['ct_left'] = lastCounts['ct_left'] ?? 0;
        _liveCounters['ct_right'] = lastCounts['ct_right'] ?? 0;
        _liveCounters['lt_forward'] = lastCounts['lt_forward'] ?? 0;
        _liveCounters['lt_reverse'] = lastCounts['lt_reverse'] ?? 0;
        _liveCounters['switch'] = lastCounts['switch'] ?? 0;
        _liveCounters['current_load'] = lastCounts['current_load'] ?? 0.0;
        _liveCounters['is_powered_on'] = lastCounts['is_powered_on'] ?? false;

        print('✅ Loaded last session counts: $lastCounts');
      });
    } catch (e) {
      print('❌ Error loading last session counts: $e');
    }
  }

  // ✅ UPDATED MQTT CONNECTION WITH PROPER SUBSCRIPTION
  Future<void> _connectMQTT() async {
    try {
      print("🔄 CONNECTING TO: ws://localhost:9001");

      final connected = await _mqttService.connect();

      setState(() {
        _isMQTTConnected = connected;
      });

      if (connected) {
        print("✅ MQTT CONNECTED!");
        _mqttSubscription = _mqttService.messageStream.listen((payload) {
          print("📥 MESSAGE: $payload");
          _processMQTTMessage(payload);
        });
      } else {
        print("❌ MQTT FAILED - Starting Demo Mode");
        // Start demo mode immediately if connection fails
        _startDemoMode();
      }
    } catch (e) {
      print('❌ MQTT ERROR: $e');
      _startDemoMode();
    }
  }

  // ADD THIS METHOD AFTER _connectMQTT
  void _startDemoMode() {
    print("🎮 DEMO MODE STARTED");
    Timer.periodic(Duration(seconds: 3), (timer) {
      final demoData = {
        "hoist_up": 1,
        "hoist_down": 1,
        "ct_left": 1,
        "ct_right": 1,
        "lt_forward": 1,
        "lt_reverse": 1,
        "switch": 1,
        "current_load": 250.0,
        "is_powered_on": 1,
      };
      _processMQTTMessage(jsonEncode(demoData));
    });
  }

  // ✅ UPDATED: AUTO-INCREMENT + AUTO-SAVE WITH SETSTATE
  // ✅ CHANGE THIS PART IN YOUR operations_log.dart
  void _processMQTTMessage(String payload) {
    print("🟢 RAW MQTT PAYLOAD: $payload");

    try {
      final data = jsonDecode(payload);
      print("🟢 PARSED JSON DATA: $data");

      // ✅ USE SETSTATE TO TRIGGER UI UPDATE
      setState(() {
        // ✅ CHANGE FROM += TO = (REPLACE VALUES, DON'T ADD)
        if (data["hoist_up"] != null) {
          _liveCounters['hoist_up'] = data["hoist_up"] as int; // ← CHANGE TO =
          print("✅ SET hoist_up: ${data["hoist_up"]}");
        }
        if (data["hoist_down"] != null) {
          _liveCounters['hoist_down'] =
              data["hoist_down"] as int; // ← CHANGE TO =
          print("✅ SET hoist_down: ${data["hoist_down"]}");
        }
        if (data["ct_left"] != null) {
          _liveCounters['ct_left'] = data["ct_left"] as int; // ← CHANGE TO =
          print("✅ SET ct_left: ${data["ct_left"]}");
        }
        if (data["ct_right"] != null) {
          _liveCounters['ct_right'] = data["ct_right"] as int; // ← CHANGE TO =
          print("✅ SET ct_right: ${data["ct_right"]}");
        }
        if (data["lt_forward"] != null) {
          _liveCounters['lt_forward'] =
              data["lt_forward"] as int; // ← CHANGE TO =
          print("✅ SET lt_forward: ${data["lt_forward"]}");
        }
        if (data["lt_reverse"] != null) {
          _liveCounters['lt_reverse'] =
              data["lt_reverse"] as int; // ← CHANGE TO =
          print("✅ SET lt_reverse: ${data["lt_reverse"]}");
        }
        if (data["switch"] != null) {
          _liveCounters['switch'] = data["switch"] as int; // ← CHANGE TO =
          print("✅ SET switch: ${data["switch"]}");
        }

        // ✅ KEEP THESE AS = (they're not counters)
        if (data["current_load"] != null) {
          _liveCounters['current_load'] = data["current_load"];
          print("✅ UPDATED current_load: ${data["current_load"]}");
        }
        if (data["total_duration"] != null) {
          _liveCounters['total_duration'] = data["total_duration"];
          print("✅ UPDATED total_duration: ${data["total_duration"]}");
        }

        // ✅ HANDLE BOOLEAN VALUES
        if (data["is_powered_on"] != null) {
          _liveCounters['is_powered_on'] =
              data["is_powered_on"] == 1 || data["is_powered_on"] == true;
          print(
            "✅ UPDATED is_powered_on: ${_liveCounters['is_powered_on'] ? 'ON 🔌' : 'OFF 🔋'}",
          );
        }
      });

      print("🎯 COUNTERS UPDATED - UI SHOULD SHOW EXACT VALUES!");

      // ✅ AUTO-SAVE TO DATABASE
      _autoSaveToDatabase();
    } catch (e) {
      print("❌ JSON ERROR: $e");
    }
  }

  // ✅ NEW: ADD OPERATION FROM MQTT DATA
  void _addOperationFromMQTT(Map<String, dynamic> data) {
    try {
      String operationType = "UNKNOWN";

      // Determine operation type from received data
      if (data["hoist_up"] != null && data["hoist_up"] > 0)
        operationType = "HOIST UP";
      else if (data["hoist_down"] != null && data["hoist_down"] > 0)
        operationType = "HOIST DOWN";
      else if (data["ct_left"] != null && data["ct_left"] > 0)
        operationType = "CT LEFT";
      else if (data["ct_right"] != null && data["ct_right"] > 0)
        operationType = "CT RIGHT";
      else if (data["lt_forward"] != null && data["lt_forward"] > 0)
        operationType = "LT FORWARD";
      else if (data["lt_reverse"] != null && data["lt_reverse"] > 0)
        operationType = "LT REVERSE";
      else if (data["switch"] != null && data["switch"] > 0)
        operationType = "SWITCH";

      if (operationType != "UNKNOWN") {
        final newEntry = OperationLogEntry(
          timestamp: DateTime.now().toIso8601String(),
          craneId: data["crane_id"]?.toString() ?? "CRANE-001",
          operation: operationType,
          description: "MQTT Live Update",
          operator: "Auto-System",
          weight: data["current_load"]?.toDouble(),
        );

        _logEntries.insert(0, newEntry); // Add to beginning of list
        print("✅ Added new operation from MQTT: $operationType");
      }
    } catch (e) {
      print("❌ Error adding operation from MQTT: $e");
    }
  }

  // ✅ NEW: AUTO-SAVE METHOD
  Future<void> _autoSaveToDatabase() async {
    try {
      print('💾 AUTO-SAVING to Supabase...');

      // ✅ PREPARE DATA THAT MATCHES YOUR TABLE STRUCTURE
      final Map<String, dynamic> saveData = {
        'hoist_up': _liveCounters['hoist_up'],
        'hoist_down': _liveCounters['hoist_down'],
        'ct_left': _liveCounters['ct_left'],
        'ct_right': _liveCounters['ct_right'],
        'lt_forward': _liveCounters['lt_forward'],
        'lt_reverse': _liveCounters['lt_reverse'],
        'switch': _liveCounters['switch'],
        'current_load': _liveCounters['current_load'],
        'total_duration': _liveCounters['total_duration'],
        'is_powered_on': _liveCounters['is_powered_on'],
        'last_updated': DateTime.now().toIso8601String(),
      };

      print('📊 SAVING DATA: $saveData');

      final success = await SupabaseService.saveCounterSession(saveData);

      if (success) {
        print('✅ AUTO-SAVE SUCCESSFUL to Supabase!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Data saved to database!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('❌ AUTO-SAVE FAILED');
      }
    } catch (e) {
      print('❌ AUTO-SAVE ERROR: $e');
    }
  }

  void _updateLiveCounters(String operation) {
    switch (operation) {
      case 'HOIST UP':
        _liveCounters['hoist_up'] = (_liveCounters['hoist_up'] as int) + 1;
        break;
      case 'HOIST DOWN':
        _liveCounters['hoist_down'] = (_liveCounters['hoist_down'] as int) + 1;
        break;
      case 'CT LEFT':
        _liveCounters['ct_left'] = (_liveCounters['ct_left'] as int) + 1;
        break;
      case 'CT RIGHT':
        _liveCounters['ct_right'] = (_liveCounters['ct_right'] as int) + 1;
        break;
      case 'LT FORWARD':
        _liveCounters['lt_forward'] = (_liveCounters['lt_forward'] as int) + 1;
        break;
      case 'LT REVERSE':
        _liveCounters['lt_reverse'] = (_liveCounters['lt_reverse'] as int) + 1;
        break;
      case 'SWITCH':
        _liveCounters['switch'] = (_liveCounters['switch'] as int) + 1;
        break;
    }
  }

  void _startLiveUpdates() {
    _liveUpdateTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _simulateLiveData();
        });
      }
    });
  }

  void _simulateLiveData() {
    if (_random.nextDouble() < 0.3) {
      _liveCounters['current_load'] = (280 + _random.nextDouble() * 20)
          .toStringAsFixed(2);
    }

    if (_random.nextDouble() < 0.5) {
      _updateDuration();
    }
  }

  void _updateDuration() {
    final parts = _liveCounters['total_duration'].toString().split(':');
    if (parts.length == 3) {
      int hours = int.tryParse(parts[0]) ?? 0;
      int minutes = int.tryParse(parts[1]) ?? 0;
      int seconds = int.tryParse(parts[2]) ?? 0;

      seconds += 1;
      if (seconds >= 60) {
        seconds = 0;
        minutes += 1;
      }
      if (minutes >= 60) {
        minutes = 0;
        hours += 1;
      }

      _liveCounters['total_duration'] =
          '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: Sidebar(onItemSelected: (title) {}),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeaderSection(),
          Expanded(
            child: _selectedTab == 0
                ? _buildOverviewTab()
                : _buildOperationsTab(),
          ),
        ],
      ),
      // ✅ REMOVED manual save button - AUTO-SAVE ONLY
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.blue),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: const Text(
        "CraneIQ",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      actions: [
        // ✅ ADD MQTT STATUS INDICATOR
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(
                _isMQTTConnected ? Icons.cloud : Icons.cloud_off,
                color: _isMQTTConnected ? Colors.green : Colors.red,
                size: 20,
              ),
              SizedBox(width: 4),
              Text(
                _isMQTTConnected ? 'MQTT' : 'OFFLINE',
                style: TextStyle(
                  color: _isMQTTConnected ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.home, color: Colors.blue),
          onPressed: () => Navigator.pushNamed(context, '/dashboard'),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Operations Log",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 8),
                    SizedBox(width: 6),
                    Text(
                      "LIVE",
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Real-time monitoring of all crane operations",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildTabs(),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [_tabButton("Overview", 0), _tabButton("Operations", 1)],
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    bool active = _selectedTab == index;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: TextButton(
          onPressed: () => setState(() => _selectedTab = index),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.blue : Colors.grey,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDashboardBoxes(),
          const SizedBox(height: 20),
          _buildOperationsTable(),
        ],
      ),
    );
  }

  Widget _buildDashboardBoxes() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _dashboardBox(
          "HOIST",
          Icons.vertical_align_center,
          Colors.blue,
          "UP: ${_liveCounters['hoist_up']}",
          "DOWN: ${_liveCounters['hoist_down']}",
          50,
        ),
        _dashboardBox(
          "CT",
          Icons.horizontal_rule,
          Colors.green,
          "LEFT: ${_liveCounters['ct_left']}",
          "RIGHT: ${_liveCounters['ct_right']}",
          100,
        ),
        _dashboardBox(
          "LT",
          Icons.arrow_forward,
          Colors.orange,
          "FORWARD: ${_liveCounters['lt_forward']}",
          "REVERSE: ${_liveCounters['lt_reverse']}",
          100,
        ),
        _dashboardBox(
          "SWITCH",
          Icons.swap_horiz,
          Colors.purple,
          "COUNT: ${_liveCounters['switch']}",
          "Status: Active",
          25,
        ),
        _dashboardBox(
          "DURATION",
          Icons.access_time,
          Colors.red,
          _liveCounters['total_duration'].toString(),
          "Total Runtime",
          100,
        ),
        _dashboardBox(
          "LOAD",
          Icons.inventory,
          Colors.teal,
          "${_liveCounters['current_load']} T",
          "Current Load",
          75,
        ),
      ],
    );
  }

  Widget _dashboardBox(
    String title,
    IconData icon,
    Color color,
    String value1,
    String value2,
    int percentage,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPercentageColor(percentage),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value1,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value2,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPercentageColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildOperationsTable() {
    final displayData = _databaseOperations.isNotEmpty
        ? _databaseOperations
        : _getSampleData();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Table Header - FIXED
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "Timestamp",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Crane ID",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Operation",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Duration",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Load (kg)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Body
          ...displayData
              .take(10)
              .map(
                (operation) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[100]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          operation['timestamp']?.toString().substring(
                                11,
                                19,
                              ) ??
                              '--:--:--',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          operation['crane_id']?.toString() ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          operation['operation_type']?.toString() ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          operation['duration']?.toString() ?? '0:00',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          operation['weight_kg']?.toString() ?? '0',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getSampleData() {
    return [
      {
        'timestamp': '2024-01-15 08:23:45',
        'crane_id': 'CRANE-001',
        'operation_type': 'HOIST UP',
        'duration': '2:15',
        'weight_kg': '3,250',
      },
      {
        'timestamp': '2024-01-15 08:45:12',
        'crane_id': 'CRANE-002',
        'operation_type': 'LT FORWARD',
        'duration': '1:42',
        'weight_kg': '4,800',
      },
      {
        'timestamp': '2024-01-15 09:12:33',
        'crane_id': 'CRANE-001',
        'operation_type': 'HOIST DOWN',
        'duration': '1:56',
        'weight_kg': '3,250',
      },
      {
        'timestamp': '2024-01-15 09:30:18',
        'crane_id': 'CRANE-003',
        'operation_type': 'SWITCH',
        'duration': '0:45',
        'weight_kg': '1,200',
      },
      {
        'timestamp': '2024-01-15 10:05:27',
        'crane_id': 'CRANE-004',
        'operation_type': 'HOIST UP',
        'duration': '3:22',
        'weight_kg': '5,700',
      },
    ];
  }

  Widget _buildOperationsTab() {
    final allOperations = [
      ..._logEntries,
      ..._getSampleOperations(),
    ].take(20).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.list_alt, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                "Live Operations Stream",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${allOperations.length} operations",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: allOperations.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: allOperations.length,
                  itemBuilder: (context, index) =>
                      _operationTile(allOperations[index], index),
                ),
        ),
      ],
    );
  }

  List<OperationLogEntry> _getSampleOperations() {
    return [
      OperationLogEntry(
        timestamp: '2024-01-15T08:23:45Z',
        craneId: 'CRANE-001',
        operation: 'HOIST UP',
        description: 'Concrete panel placement',
        operator: 'Operator John',
        weight: 3250.0,
      ),
      OperationLogEntry(
        timestamp: '2024-01-15T08:45:12Z',
        craneId: 'CRANE-002',
        operation: 'LT FORWARD',
        description: 'Steel beam relocation',
        operator: 'Operator Sarah',
        weight: 4800.0,
      ),
      OperationLogEntry(
        timestamp: '2024-01-15T09:12:33Z',
        craneId: 'CRANE-001',
        operation: 'HOIST DOWN',
        description: 'Lowering equipment',
        operator: 'Operator John',
        weight: 3250.0,
      ),
    ];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            "No operations yet",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            "Operations will appear here in real-time",
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _operationTile(OperationLogEntry entry, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getOperationColor(entry.operation).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getOperationIcon(entry.operation),
            color: _getOperationColor(entry.operation),
            size: 20,
          ),
        ),
        title: Text(
          entry.operation,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _getOperationColor(entry.operation),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Crane: ${entry.craneId} • Operator: ${entry.operator}"),
            if (entry.description.isNotEmpty)
              Text("Desc: ${entry.description}"),
            Text("Time: ${_formatTimestamp(entry.timestamp)}"),
            if (entry.weight != null) Text("Load: ${entry.weight} kg"),
          ],
        ),
        trailing: Text(
          "#${index + 1}",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }

  Color _getOperationColor(String operation) {
    switch (operation) {
      case 'HOIST UP':
        return Colors.green;
      case 'HOIST DOWN':
        return Colors.orange;
      case 'CT LEFT':
      case 'CT RIGHT':
        return Colors.blue;
      case 'LT FORWARD':
      case 'LT REVERSE':
        return Colors.purple;
      case 'SWITCH':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getOperationIcon(String operation) {
    switch (operation) {
      case 'HOIST UP':
        return Icons.arrow_upward;
      case 'HOIST DOWN':
        return Icons.arrow_downward;
      case 'CT LEFT':
        return Icons.arrow_back;
      case 'CT RIGHT':
        return Icons.arrow_forward;
      case 'LT FORWARD':
        return Icons.arrow_forward;
      case 'LT REVERSE':
        return Icons.arrow_back;
      case 'SWITCH':
        return Icons.swap_horiz;
      default:
        return Icons.build;
    }
  }
}
