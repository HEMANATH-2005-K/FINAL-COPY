// lib/pages/temperature_monitoring.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../widgets/sidebar.dart';

class TemperatureMonitoringPage extends StatefulWidget {
  const TemperatureMonitoringPage({super.key});

  @override
  State<TemperatureMonitoringPage> createState() =>
      _TemperatureMonitoringPageState();
}

class _TemperatureMonitoringPageState extends State<TemperatureMonitoringPage> {
  // -------- Filters --------
  String selectedCrane = 'All Cranes';
  String selectedDateRange = 'Today';
  final List<String> cranes = [
    'All Cranes',
    'CRANE-001',
    'CRANE-002',
    'CRANE-003',
  ];
  final List<String> dateRanges = ['Today', 'This Week', 'This Month'];

  // -------- Data / Realtime --------
  List<Map<String, dynamic>> realTempData = [];
  bool isLoading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _unsubscribeRealtime();
    super.dispose();
  }

  // ---------- Helpers ----------
  static Widget _hdr(String t) => Text(
    t,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: Color(0xFF1E3A5F),
    ),
  );

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Color _statusChipColor(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ---------- Data ----------
  Future<void> _loadData() async {
    try {
      final data = await SupabaseService.getTemperatureData();
      // Optional: client-side filter by crane
      final filtered = (selectedCrane == 'All Cranes')
          ? data
          : data
                .where(
                  (r) => (r['crane_id']?.toString() ?? '') == selectedCrane,
                )
                .toList();

      setState(() {
        realTempData = filtered;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _toast('Failed to load temperature data', isError: true);
    }
  }

  void _subscribeRealtime() {
    final client = Supabase.instance.client;
    _channel = client.channel('temperature_channel');

    _channel!
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'temperature_data',
        callback: (_) => _loadData(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'temperature_data',
        callback: (_) => _loadData(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'temperature_data',
        callback: (_) => _loadData(),
      )
      ..subscribe();
  }

  void _unsubscribeRealtime() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
  }

  // ---------- CRUD ----------
  Future<void> _createRow() async {
    final form = await _openAddEditDialog();
    if (form == null) return;

    try {
      await SupabaseService.supabase.from('temperature_data').insert({
        'crane_id': form['crane_id'],
        'temperature': form['temperature'],
        'humidity': form['humidity'],
        'location': form['location'],
        'status': form['status'],
        // timestamp defaults to NOW() in DB
      });
      _toast('Temperature reading added');
      await _loadData();
    } catch (e) {
      _toast('Failed to add reading', isError: true);
    }
  }

  Future<void> _editRow(Map<String, dynamic> row) async {
    final id = row['id'];
    if (id == null) {
      _toast('Row id missing', isError: true);
      return;
    }

    final form = await _openAddEditDialog(initial: row);
    if (form == null) return;

    try {
      await SupabaseService.supabase
          .from('temperature_data')
          .update({
            'crane_id': form['crane_id'],
            'temperature': form['temperature'],
            'humidity': form['humidity'],
            'location': form['location'],
            'status': form['status'],
          })
          .eq('id', id);
      _toast('Reading updated');
      await _loadData();
    } catch (e) {
      _toast('Failed to update', isError: true);
    }
  }

  Future<void> _deleteRow(Map<String, dynamic> row) async {
    final id = row['id'];
    if (id == null) {
      _toast('Row id missing', isError: true);
      return;
    }

    final ok = await _confirmDelete();
    if (!ok) return;

    try {
      await SupabaseService.supabase
          .from('temperature_data')
          .delete()
          .eq('id', id);
      _toast('Reading deleted');
      await _loadData();
    } catch (e) {
      _toast('Failed to delete', isError: true);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          'Temperature Monitoring',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A5F),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF1E3A5F)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1E3A5F)),
            tooltip: 'Add Reading',
            onPressed: _createRow,
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Color(0xFF1E3A5F)),
            onPressed: () => Navigator.pushNamed(context, '/dashboard'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Sidebar(onItemSelected: (title) {}),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildFilterSection(),
              const SizedBox(height: 12),
              _buildOverviewCard(),
              const SizedBox(height: 12),
              _buildRealtimeTableCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createRow,
        backgroundColor: const Color(0xFF1E3A5F),
        icon: const Icon(Icons.add),
        label: const Text('Add Reading'),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A5F).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.thermostat,
            color: Color(0xFF1E3A5F),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Temperature Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _labeledDropdown(
                  label: 'Crane',
                  value: selectedCrane,
                  items: cranes,
                  onChanged: (v) {
                    setState(() => selectedCrane = v ?? 'All Cranes');
                    _loadData();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _labeledDropdown(
                  label: 'Date Range',
                  value: selectedDateRange,
                  items: dateRanges,
                  onChanged: (v) =>
                      setState(() => selectedDateRange = v ?? 'Today'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _toast('Filters applied'),
                  icon: const Icon(Icons.filter_alt, size: 14),
                  label: const Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A5F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedCrane = 'All Cranes';
                      selectedDateRange = 'Today';
                    });
                    _loadData();
                    _toast('Filters reset');
                  },
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Reset', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black54,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labeledDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            items: items
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(e, style: const TextStyle(fontSize: 13)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard() {
    double avgTemp = 0;
    double maxTemp = 0;
    double avgHumidity = 0;
    int normalCount = 0;

    if (realTempData.isNotEmpty) {
      for (final r in realTempData) {
        final t = (r['temperature'] ?? 0).toDouble();
        final h = (r['humidity'] ?? 0).toDouble();
        avgTemp += t;
        avgHumidity += h;
        if (t > maxTemp) maxTemp = t;
        if ((r['status']?.toString().toLowerCase() ?? 'normal') == 'normal') {
          normalCount++;
        }
      }
      avgTemp /= realTempData.length;
      avgHumidity /= realTempData.length;
    }

    final safetyPct = realTempData.isEmpty
        ? 100
        : (normalCount / realTempData.length) * 100.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Temperature Overview',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const Spacer(),
              isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh, size: 16),
                      onPressed: _loadData,
                    ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : realTempData.isEmpty
                ? const Center(
                    child: Text(
                      'No temperature data available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (v, meta) => Text(
                              '${v.toInt()}°C',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 18,
                            getTitlesWidget: (value, meta) {
                              if (realTempData.isEmpty) return const Text('');
                              final i = value.toInt();
                              if (i < 0 || i >= realTempData.length)
                                return const Text('');
                              final ts = realTempData[i]['timestamp'];
                              try {
                                final dt = DateTime.parse(
                                  ts.toString(),
                                ).toLocal();
                                final label =
                                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                return Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.black54,
                                  ),
                                );
                              } catch (_) {
                                return Text(
                                  't$i',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.black54,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _generateTempSpots(),
                          isCurved: true,
                          color: const Color(0xFF1E3A5F),
                          barWidth: 2.5,
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF1E3A5F).withOpacity(0.1),
                          ),
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
          ),
          SizedBox(height: 10),
          _buildKpiGrid(avgTemp, maxTemp, avgHumidity),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(double avgTemp, double maxTemp, double avgHumidity) {
    final metrics = [
      {
        'label': 'Average Temp',
        'value': '${avgTemp.toStringAsFixed(1)} °C',
        'color': Colors.blue,
      },
      {
        'label': 'Peak Temp',
        'value': '${maxTemp.toStringAsFixed(1)} °C',
        'color': Colors.orange,
      },
      {
        'label': 'Avg Humidity',
        'value': '${avgHumidity.toStringAsFixed(1)} %',
        'color': Colors.teal,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 2.8,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, i) {
        final m = metrics[i];
        final c = m['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: c.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                m['value'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: c,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                m['label'] as String,
                style: const TextStyle(fontSize: 9, color: Colors.black54),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Realtime Table ----------
  Widget _buildRealtimeTableCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Recent Temperature Readings (Realtime)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (realTempData.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No data found'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                dataRowMinHeight: 36,
                headingRowHeight: 36,
                columns: [
                  DataColumn(label: _hdr('Time')),
                  DataColumn(label: _hdr('Crane')),
                  DataColumn(label: _hdr('Location')),
                  DataColumn(label: _hdr('Temp (°C)')),
                  DataColumn(label: _hdr('Humidity (%)')),
                  DataColumn(label: _hdr('Status')),
                  DataColumn(label: _hdr('Actions')),
                ],
                rows: realTempData.take(25).map((r) {
                  final crane = r['crane_id']?.toString() ?? '-';
                  final loc = r['location']?.toString() ?? '-';
                  final temp = (r['temperature'] ?? 0).toDouble();
                  final hum = (r['humidity'] ?? 0).toDouble();
                  final status = r['status']?.toString() ?? '-';

                  String time = '-';
                  final ts = r['timestamp'];
                  if (ts != null) {
                    try {
                      final dt = DateTime.parse(ts.toString()).toLocal();
                      time =
                          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    } catch (_) {}
                  }

                  final color = _statusChipColor(status);

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(time, style: const TextStyle(fontSize: 11)),
                      ),
                      DataCell(
                        Text(crane, style: const TextStyle(fontSize: 11)),
                      ),
                      DataCell(Text(loc, style: const TextStyle(fontSize: 11))),
                      DataCell(
                        Text(
                          temp.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      DataCell(
                        Text(
                          hum.toStringAsFixed(1),
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
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.isEmpty
                                ? '-'
                                : status[0].toUpperCase() + status.substring(1),
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _editRow(r),
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              onPressed: () => _deleteRow(r),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              tooltip: 'Delete',
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

  // ---------- Chart data ----------
  List<FlSpot> _generateTempSpots() {
    if (realTempData.isEmpty) return [const FlSpot(0, 0)];
    return List.generate(realTempData.length, (i) {
      final t = (realTempData[i]['temperature'] ?? 0).toDouble();
      return FlSpot(i.toDouble(), t);
    });
  }

  // ---------- Dialogs ----------
  Future<Map<String, dynamic>?> _openAddEditDialog({
    Map<String, dynamic>? initial,
  }) async {
    final editing = initial != null;

    final craneCtrl = TextEditingController(
      text: initial?['crane_id']?.toString() ?? '',
    );
    final tempCtrl = TextEditingController(
      text: _numToStr(initial?['temperature']),
    );
    final humCtrl = TextEditingController(
      text: _numToStr(initial?['humidity']),
    );
    final locCtrl = TextEditingController(
      text: initial?['location']?.toString() ?? '',
    );

    String status = (initial?['status']?.toString() ?? 'normal').toLowerCase();

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            editing ? 'Edit Temperature Reading' : 'Add Temperature Reading',
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _tf(
                      controller: craneCtrl,
                      label: 'Crane ID',
                      hint: 'e.g., CRANE-001',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Crane ID required'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _tf(
                            controller: tempCtrl,
                            label: 'Temperature (°C)',
                            hint: 'e.g., 45.5',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: _numberValidator,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _tf(
                            controller: humCtrl,
                            label: 'Humidity (%)',
                            hint: 'e.g., 62.0',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: _numberValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _tf(
                      controller: locCtrl,
                      label: 'Location',
                      hint: 'e.g., Motor Area',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Location required'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    _dd(
                      label: 'Status',
                      value: status,
                      items: const ['normal', 'warning', 'critical'],
                      onChanged: (v) => status = v ?? 'normal',
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop<Map<String, dynamic>>(ctx, {
                  'crane_id': craneCtrl.text.trim(),
                  'temperature': double.parse(tempCtrl.text.trim()),
                  'humidity': double.parse(humCtrl.text.trim()),
                  'location': locCtrl.text.trim(),
                  'status': status,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
              ),
              child: Text(editing ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    );

    craneCtrl.dispose();
    tempCtrl.dispose();
    humCtrl.dispose();
    locCtrl.dispose();
    return result;
  }

  String? _numberValidator(String? v) {
    final d = double.tryParse(v ?? '');
    if (d == null) return 'Enter a valid number';
    return null;
    // (Add min/max validation if needed)
  }

  static Widget _tf({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      validator: validator,
    );
  }

  static Widget _dd({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map(
            (e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e.toUpperCase()),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
    );
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Reading?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _numToStr(dynamic v) {
    if (v == null) return '';
    if (v is num) return v.toString();
    return v.toString();
  }
}
