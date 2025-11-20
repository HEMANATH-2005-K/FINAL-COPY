// pages/load_lift_log.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../widgets/sidebar.dart';

class LoadLiftLogPage extends StatefulWidget {
  const LoadLiftLogPage({super.key});

  @override
  State<LoadLiftLogPage> createState() => _LoadLiftLogPageState();
}

class _LoadLiftLogPageState extends State<LoadLiftLogPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Filters
  String selectedCrane = 'All Cranes';
  String selectedStatus = 'All Statuses';
  String selectedDate = 'Today';
  bool _showFilters = true;

  final List<String> cranes = [
    'All Cranes',
    'CRANE-001',
    'CRANE-002',
    'CRANE-003',
  ];
  final List<String> statuses = ['All Statuses', 'safe', 'warning', 'critical'];
  final List<String> dates = ['Today', 'This Week', 'This Month'];

  // Realtime + data
  List<Map<String, dynamic>> realLoadReadings = [];
  bool isLoadingLoadData = true;
  RealtimeChannel? _realtimeChannel;

  // Static chart placeholders (you can later bind them to real data if you want)
  final List<double> loadTrend = [3.2, 4.5, 5.2, 6.8, 3.9, 4.8, 5.8];

  @override
  void initState() {
    super.initState();
    _subscribeRealtime();
    loadRealLoadData();
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      SupabaseService.supabase.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  void _subscribeRealtime() {
    // Subscribe to all changes on public.load_readings
    _realtimeChannel = SupabaseService.supabase
        .channel('public:load_readings')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'load_readings',
          callback: (payload) async {
            // Simply reload; small table so it's fine and avoids edge cases
            await loadRealLoadData();
          },
        )
        .subscribe();
  }

  Future<void> loadRealLoadData() async {
    try {
      setState(() => isLoadingLoadData = true);
      var data = await SupabaseService.getLoadReadings();

      // Apply simple in-memory filters for UI (server-side filtering is easy to add later)
      data = _applyInMemoryFilters(data);

      setState(() {
        realLoadReadings = data;
        isLoadingLoadData = false;
      });
      // ignore: avoid_print
      print('✅ Loaded ${realLoadReadings.length} load readings');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error loading load data: $e');
      if (mounted) setState(() => isLoadingLoadData = false);
    }
  }

  List<Map<String, dynamic>> _applyInMemoryFilters(
    List<Map<String, dynamic>> data,
  ) {
    return data.where((row) {
      final craneOk = selectedCrane == 'All Cranes'
          ? true
          : (row['crane_id']?.toString() ?? '') == selectedCrane;

      final statusValue = (row['safety_status'] ?? '').toString();
      final statusOk = selectedStatus == 'All Statuses'
          ? true
          : statusValue == selectedStatus;

      // Simple date filter: we check timestamp vs "today/this week/this month"
      bool dateOk = true;
      final ts = row['timestamp'];
      DateTime? dt;
      if (ts != null) {
        if (ts is String) {
          dt = DateTime.tryParse(ts);
        } else if (ts is DateTime) {
          dt = ts;
        }
      }
      if (dt != null) {
        final now = DateTime.now();
        if (selectedDate == 'Today') {
          dateOk =
              dt.year == now.year && dt.month == now.month && dt.day == now.day;
        } else if (selectedDate == 'This Week') {
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));
          dateOk = dt.isAfter(startOfWeek) && dt.isBefore(endOfWeek);
        } else if (selectedDate == 'This Month') {
          dateOk = dt.year == now.year && dt.month == now.month;
        }
      }

      return craneOk && statusOk && dateOk;
    }).toList();
  }

  // ------------------------
  // CRUD operations (direct)
  // ------------------------

  Future<void> _createReading(Map<String, dynamic> values) async {
    try {
      await SupabaseService.supabase
          .from('load_readings')
          .insert(values)
          .select()
          .single();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reading added')));
    } catch (e) {
      _showError('Failed to add reading: $e');
    }
  }

  Future<void> _updateReading(String id, Map<String, dynamic> values) async {
    try {
      await SupabaseService.supabase
          .from('load_readings')
          .update(values)
          .eq('id', id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reading updated')));
    } catch (e) {
      _showError('Failed to update reading: $e');
    }
  }

  Future<void> _deleteReading(String id) async {
    try {
      await SupabaseService.supabase
          .from('load_readings')
          .delete()
          .eq('id', id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reading deleted')));
    } catch (e) {
      _showError('Failed to delete reading: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ------------------------
  // UI
  // ------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Load Monitoring'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF1E3A5F)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Color(0xFF1E3A5F)),
            onPressed: () => Navigator.pushNamed(context, '/dashboard'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: Sidebar(onItemSelected: (title) {}),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A5F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Reading', style: TextStyle(color: Colors.white)),
        onPressed: () => _openCrudDialog(),
      ),
      body: RefreshIndicator(
        onRefresh: loadRealLoadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),

              // KPIs
              _buildKPICards(),
              const SizedBox(height: 20),

              _buildQuickStats(),
              const SizedBox(height: 20),

              _buildFilterToggle(),
              const SizedBox(height: 12),

              if (_showFilters) _buildFilterSection(),
              if (_showFilters) const SizedBox(height: 20),

              _buildChartSection(),
              const SizedBox(height: 20),

              _buildDataTable(),
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
              child: const Icon(Icons.fitness_center, color: Color(0xFF1E3A5F)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Load Lift Log",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            ),
            // Quick action (you can wire it to create an alert row later)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_alert, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    "Set Alert",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "Records of all load weight measurements",
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildKPICards() {
    double totalLoad = 0;
    double maxLoad = 0;
    int safeOps = 0;

    for (final r in realLoadReadings) {
      final load = _toDouble(r['load_weight']);
      totalLoad += load;
      if (load > maxLoad) maxLoad = load;
      if ((r['safety_status'] ?? 'safe') == 'safe') safeOps++;
    }

    final avgLoad = realLoadReadings.isEmpty
        ? 0
        : (totalLoad / realLoadReadings.length);
    final safetyPct = realLoadReadings.isEmpty
        ? 100
        : (safeOps / realLoadReadings.length) * 100;

    final kpis = [
      {
        'value': '${avgLoad.toStringAsFixed(0)} kg',
        'label': 'Average Load',
        'subtitle': 'Across all cranes',
        'color': Colors.blue,
        'icon': Icons.scale,
      },
      {
        'value': '${realLoadReadings.length}',
        'label': 'Total Readings',
        'subtitle': 'Load measurements',
        'color': Colors.green,
        'icon': Icons.analytics,
      },
      {
        'value': '${maxLoad.toStringAsFixed(0)} kg',
        'label': 'Max Load',
        'subtitle': 'Peak measurement',
        'color': Colors.orange,
        'icon': Icons.trending_up,
      },
      {
        'value': '${safetyPct.toStringAsFixed(0)}%',
        'label': 'Safety Rate',
        'subtitle': 'Safe operations',
        'color': Colors.green,
        'icon': Icons.check_circle,
      },
    ];

    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      child: isLoadingLoadData
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(),
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: kpis.length,
              itemBuilder: (context, index) {
                final k = kpis[index];
                final color = k['color'] as Color;
                return Container(
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
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                k['icon'] as IconData,
                                color: color,
                                size: 14,
                              ),
                            ),
                            Icon(Icons.insights, color: color, size: 14),
                          ],
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            k['value'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        Text(
                          k['label'] as String,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          k['subtitle'] as String,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickItem(
            'Total Rows',
            '${realLoadReadings.length}',
            Icons.list_alt,
            Colors.blue,
          ),
          _quickItem('Avg Load', _avgDisplay(), Icons.analytics, Colors.green),
          _quickItem('Peak', _peakDisplay(), Icons.flag, Colors.orange),
          _quickItem('Safety', _safetyDisplay(), Icons.security, Colors.green),
        ],
      ),
    );
  }

  String _avgDisplay() {
    if (realLoadReadings.isEmpty) return '0 kg';
    final avg =
        realLoadReadings
            .map((e) => _toDouble(e['load_weight']))
            .fold<double>(0, (p, c) => p + c) /
        realLoadReadings.length;
    return '${avg.toStringAsFixed(0)} kg';
  }

  String _peakDisplay() {
    if (realLoadReadings.isEmpty) return '0 kg';
    final peak = realLoadReadings
        .map((e) => _toDouble(e['load_weight']))
        .reduce((a, b) => a > b ? a : b);
    return '${peak.toStringAsFixed(0)} kg';
  }

  String _safetyDisplay() {
    if (realLoadReadings.isEmpty) return '100%';
    final safe = realLoadReadings
        .where((e) => (e['safety_status'] ?? '') == 'safe')
        .length;
    final pct = (safe / realLoadReadings.length) * 100;
    return '${pct.toStringAsFixed(0)}%';
  }

  Widget _quickItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildFilterToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _cardRounded(),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          const Text(
            'Advanced Filters',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Switch(
            value: _showFilters,
            onChanged: (value) => setState(() => _showFilters = value),
            activeThumbColor: const Color(0xFF1E3A5F),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final content = [
                _filterDropdown('Crane', cranes, selectedCrane),
                const SizedBox(width: 12, height: 12),
                _filterDropdown('Load Status', statuses, selectedStatus),
                const SizedBox(width: 12, height: 12),
                _filterDropdown('Date Range', dates, selectedDate),
              ];
              if (constraints.maxWidth > 600) {
                return Row(
                  children: content.map((w) => Expanded(child: w)).toList(),
                );
              }
              return Column(children: content);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await loadRealLoadData();
                    if (!mounted) return;
                    setState(() => _showFilters = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Filters applied')),
                    );
                  },
                  icon: const Icon(Icons.filter_alt, size: 16),
                  label: const Text("Apply Filters"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A5F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    setState(() {
                      selectedCrane = 'All Cranes';
                      selectedStatus = 'All Statuses';
                      selectedDate = 'Today';
                      _showFilters = false;
                    });
                    await loadRealLoadData();
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text("Reset"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown(String label, List<String> items, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 12)),
                  ),
                )
                .toList(),
            onChanged: (newValue) {
              if (newValue == null) return;
              setState(() {
                if (label == 'Crane') selectedCrane = newValue;
                if (label == 'Load Status') selectedStatus = newValue;
                if (label == 'Date Range') selectedDate = newValue;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Load Analytics",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _chartTypePill('Distribution', true),
                const SizedBox(width: 8),
                _chartTypePill('Trend', false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 8,
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          '${value.toInt()}T',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 25,
                      getTitlesWidget: (value, meta) {
                        final labels = [
                          'CRN-001',
                          'CRN-002',
                          'CRN-003',
                          'CRN-004',
                          'CRN-005',
                        ];
                        return value.toInt() < labels.length
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  labels[value.toInt()],
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.black54,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: 3.2,
                        color: _getLoadColor(3.2, 5.0),
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: 4.5,
                        color: _getLoadColor(4.5, 10.0),
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: 5.2,
                        color: _getLoadColor(5.2, 6.0),
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 3,
                    barRods: [
                      BarChartRodData(
                        toY: 6.8,
                        color: _getLoadColor(6.8, 6.8),
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 4,
                    barRods: [
                      BarChartRodData(
                        toY: 3.9,
                        color: _getLoadColor(3.9, 8.0),
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "CRN-004 operating at maximum capacity. Consider load balancing.",
                    style: TextStyle(fontSize: 10, color: Colors.blue.shade800),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartTypePill(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1E3A5F) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : Colors.black54,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getLoadColor(double load, double capacity) {
    final percentage = (load / capacity) * 100;
    if (percentage >= 90) return Colors.red;
    if (percentage >= 75) return Colors.orange;
    return Colors.green;
  }

  Widget _buildDataTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Recent Load Operations",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const Spacer(),
              // Export button placeholder (wire up later if needed)
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export not implemented yet')),
                  );
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoadingLoadData)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (realLoadReadings.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('No data'),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                dataRowMinHeight: 40,
                headingRowHeight: 38,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Time',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Crane ID',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Load (kg)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Capacity (kg)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Utilization',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Actions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
                rows: realLoadReadings.take(50).map((reading) {
                  final id = (reading['id'] ?? '').toString();
                  final load = _toDouble(reading['load_weight']);
                  final capacity = _toDouble(
                    reading['capacity'],
                    fallback: 5000,
                  );
                  final percentage = capacity == 0
                      ? 0
                      : (load / capacity * 100);
                  final statusText = (reading['safety_status'] ?? 'safe')
                      .toString();
                  final statusColor = statusText == 'critical'
                      ? Colors.red
                      : statusText == 'warning'
                      ? Colors.orange
                      : Colors.green;

                  // timestamp
                  String formattedTime = 'Unknown';
                  final ts = reading['timestamp'];
                  DateTime? dt;
                  if (ts != null) {
                    if (ts is String) {
                      dt = DateTime.tryParse(ts);
                    } else if (ts is DateTime) {
                      dt = ts;
                    }
                  }
                  if (dt != null) {
                    formattedTime =
                        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                  }

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          formattedTime,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      DataCell(
                        Text(
                          reading['crane_id']?.toString() ?? 'Unknown',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${load.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${capacity.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () =>
                                  _openCrudDialog(existing: reading),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () async {
                                final ok = await _confirmDelete();
                                if (ok == true) {
                                  await _deleteReading(id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------
  // CRUD Dialog
  // ------------------------
  Future<void> _openCrudDialog({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;

    final craneCtrl = TextEditingController(
      text: existing?['crane_id']?.toString() ?? '',
    );
    final loadCtrl = TextEditingController(
      text: existing?['load_weight']?.toString() ?? '',
    );
    final capacityCtrl = TextEditingController(
      text: existing?['capacity']?.toString() ?? '',
    );
    final percentageCtrl = TextEditingController(
      text: existing?['percentage']?.toString() ?? '',
    );
    String safetyStatus = (existing?['safety_status']?.toString() ?? 'safe')
        .toLowerCase();

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Reading' : 'Add Reading'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: craneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Crane ID (e.g., CRANE-001)',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: loadCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Load (kg)'),
                    validator: (v) => _isNum(v) ? null : 'Enter a valid number',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: capacityCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Capacity (kg)',
                    ),
                    validator: (v) => _isNum(v) ? null : 'Enter a valid number',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: percentageCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Utilization %',
                    ),
                    validator: (v) => _isNum(v) ? null : 'Enter a valid number',
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: safetyStatus,
                    decoration: const InputDecoration(
                      labelText: 'Safety Status',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'safe', child: Text('safe')),
                      DropdownMenuItem(
                        value: 'warning',
                        child: Text('warning'),
                      ),
                      DropdownMenuItem(
                        value: 'critical',
                        child: Text('critical'),
                      ),
                    ],
                    onChanged: (v) => safetyStatus = v ?? 'safe',
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
              foregroundColor: Colors.white,
            ),
            child: Text(isEdit ? 'Update' : 'Create'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final load = double.parse(loadCtrl.text.trim());
              final cap = double.parse(capacityCtrl.text.trim());
              final pct = double.parse(percentageCtrl.text.trim());

              final values = {
                'crane_id': craneCtrl.text.trim(),
                'load_weight': load,
                'capacity': cap,
                'percentage': pct,
                'safety_status': safetyStatus,
                // timestamp defaults in DB (NOW())
              };

              if (isEdit) {
                final id = (existing!['id'] ?? '').toString();
                await _updateReading(id, values);
              } else {
                await _createReading(values);
              }

              if (mounted) Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );

    craneCtrl.dispose();
    loadCtrl.dispose();
    capacityCtrl.dispose();
    percentageCtrl.dispose();
  }

  Future<bool?> _confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reading?'),
        content: const Text(
          'This action cannot be undone. Are you sure you want to delete this reading?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }

  // ------------------------
  // Helpers
  // ------------------------
  double _toDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    final s = v.toString();
    final parsed = double.tryParse(s);
    return parsed ?? fallback;
  }

  bool _isNum(String? v) {
    if (v == null) return false;
    return double.tryParse(v.trim()) != null;
  }

  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  BoxDecoration _cardRounded() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 5,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
