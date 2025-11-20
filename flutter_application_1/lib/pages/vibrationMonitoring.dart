// pages/vibration_monitoring.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../widgets/sidebar.dart';

class VibrationMonitoringPage extends StatefulWidget {
  const VibrationMonitoringPage({super.key});

  @override
  State<VibrationMonitoringPage> createState() =>
      _VibrationMonitoringPageState();
}

class _VibrationMonitoringPageState extends State<VibrationMonitoringPage> {
  // ---------- filters ----------
  String selectedCrane = 'EOT Crane #1 (CRN-001)';
  String selectedDateRange = 'Today';

  final List<String> cranes = const [
    'EOT Crane #1 (CRN-001)',
    'EOT Crane #2 (CRN-002)',
    'Gantry Crane #1 (GCN-003)',
  ];
  final List<String> dateRanges = const ['Today', 'This Week', 'This Month'];

  // Axis → Component name mapping (edit here if you want different labels)
  final Map<String, String> axisNames = const {
    'x': 'Hoist Motor',
    'y': 'Travel Motor',
    'z': 'Gearbox',
  };

  // ---------- data ----------
  List<Map<String, dynamic>> realVibrationData = [];
  bool isLoadingVibrationData = true;
  RealtimeChannel? _channel;

  // ---------- lifecycle ----------
  @override
  void initState() {
    super.initState();
    loadRealVibrationData();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _unsubscribeRealtime();
    super.dispose();
  }

  // ---------- load + realtime ----------
  Future<void> loadRealVibrationData() async {
    try {
      final data = await SupabaseService.getVibrationData();
      if (!mounted) return;
      setState(() {
        realVibrationData = data;
        isLoadingVibrationData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingVibrationData = false);
      _toast(context, 'Failed to load vibration data', isError: true);
      debugPrint('❌ Error loading vibration data: $e');
    }
  }

  void _subscribeRealtime() {
    // one channel for table: vibration_data
    _channel = Supabase.instance.client.channel('vibration_data_changes');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'vibration_data',
          callback: (_) => loadRealVibrationData(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'vibration_data',
          callback: (_) => loadRealVibrationData(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'vibration_data',
          callback: (_) => loadRealVibrationData(),
        )
        .subscribe();
  }

  void _unsubscribeRealtime() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
  }

  // ---------- CRUD ----------
  Future<void> _createVibrationReading() async {
    final form = await _openAddEditDialog();
    if (form == null) return;

    try {
      await SupabaseService.supabase.from('vibration_data').insert({
        'crane_id': form['crane_id'],
        'vibration_level': form['vibration_level'],
        'frequency': form['frequency'],
        'axis': form['axis'],
        'status': form['status'],
        // timestamp defaults to NOW()
      });
      _toast(context, 'Reading added');
      // realtime will update, but refresh immediately for snappier UI
      await loadRealVibrationData();
    } catch (e) {
      _toast(context, 'Failed to add reading', isError: true);
      debugPrint('Insert error: $e');
    }
  }

  Future<void> _editVibrationReading(Map<String, dynamic> row) async {
    final form = await _openAddEditDialog(initial: row);
    if (form == null) return;
    final id = row['id'];
    if (id == null) {
      _toast(context, 'Row id missing', isError: true);
      return;
    }

    try {
      await SupabaseService.supabase
          .from('vibration_data')
          .update({
            'crane_id': form['crane_id'],
            'vibration_level': form['vibration_level'],
            'frequency': form['frequency'],
            'axis': form['axis'],
            'status': form['status'],
          })
          .eq('id', id);
      _toast(context, 'Reading updated');
      await loadRealVibrationData();
    } catch (e) {
      _toast(context, 'Failed to update', isError: true);
      debugPrint('Update error: $e');
    }
  }

  Future<void> _deleteVibrationReading(Map<String, dynamic> row) async {
    final id = row['id'];
    if (id == null) {
      _toast(context, 'Row id missing', isError: true);
      return;
    }

    final confirmed = await _confirmDelete(context);
    if (!confirmed) return;

    try {
      await SupabaseService.supabase
          .from('vibration_data')
          .delete()
          .eq('id', id);
      _toast(context, 'Reading deleted');
      await loadRealVibrationData();
    } catch (e) {
      _toast(context, 'Failed to delete', isError: true);
      debugPrint('Delete error: $e');
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          "Vibration Monitoring",
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
            onPressed: _createVibrationReading,
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
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildFilterSection(),
                    const SizedBox(height: 16),
                    _buildOverviewSection(),
                    const SizedBox(height: 16),
                    _buildComponentsSection(),
                    const SizedBox(height: 16),
                    _buildRealtimeTableCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createVibrationReading,
        backgroundColor: const Color(0xFF1E3A5F),
        icon: const Icon(Icons.add),
        label: const Text('Add Reading'),
      ),
    );
  }

  // ----- Header & Filters -----
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Row(
          children: [
            _HeaderIcon(),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Vibration Analysis",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          "Monitor vibration levels across crane components",
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _labeledDropdown(
                  label: 'Crane',
                  value: selectedCrane,
                  items: cranes,
                  onChanged: (v) => setState(() => selectedCrane = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _labeledDropdown(
                  label: 'Date Range',
                  value: selectedDateRange,
                  items: dateRanges,
                  onChanged: (v) => setState(() => selectedDateRange = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _toast(context, 'Filters applied'),
                  icon: const Icon(Icons.filter_alt, size: 14),
                  label: const Text(
                    "Apply Filters",
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
                      selectedCrane = cranes.first;
                      selectedDateRange = dateRanges.first;
                    });
                    _toast(context, 'Filters reset');
                  },
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text("Reset", style: TextStyle(fontSize: 13)),
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

  // ----- Overview (line chart + metrics) -----
  Widget _buildOverviewSection() {
    double avgVibration = 0;
    double maxVibration = 0;
    int normalReadings = 0;

    if (realVibrationData.isNotEmpty) {
      for (final reading in realVibrationData) {
        final vibration = (reading['vibration_level'] ?? 0).toDouble();
        avgVibration += vibration;
        if (vibration > maxVibration) maxVibration = vibration;
        if ((reading['status'] ?? 'normal').toString().toLowerCase() ==
            'normal') {
          normalReadings++;
        }
      }
      avgVibration /= realVibrationData.length;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Vibration Overview",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const Spacer(),
              if (isLoadingVibrationData)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  onPressed: loadRealVibrationData,
                  tooltip: 'Refresh Data',
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: isLoadingVibrationData
                ? const Center(child: CircularProgressIndicator())
                : realVibrationData.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.vibration, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No vibration data available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
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
                            reservedSize: 35,
                            getTitlesWidget: (value, _) => Text(
                              '${value.toInt()} mm/s',
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
                            getTitlesWidget: (value, _) {
                              if (realVibrationData.isEmpty) {
                                return const Text('');
                              }
                              final idx = value.toInt();
                              if (idx < 0 || idx >= realVibrationData.length) {
                                return const Text('');
                              }
                              final ts = realVibrationData[idx]['timestamp'];
                              String label = '';
                              try {
                                final dt = DateTime.parse(
                                  ts.toString(),
                                ).toLocal();
                                label =
                                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                              } catch (_) {
                                label = 't$idx';
                              }
                              return Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.black54,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _generateChartSpots(),
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
          const SizedBox(height: 12),
          _buildMetricsGrid(avgVibration, maxVibration, normalReadings),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    double avgVibration,
    double maxVibration,
    int normalReadings,
  ) {
    final safetyPercentage = realVibrationData.isNotEmpty
        ? (normalReadings / realVibrationData.length) * 100
        : 100;

    final List<Map<String, dynamic>> metrics = [
      {
        'label': 'Average Vibration',
        'value': '${avgVibration.toStringAsFixed(1)} mm/s',
        'color': Colors.blue,
      },
      {
        'label': 'Peak Vibration',
        'value': '${maxVibration.toStringAsFixed(1)} mm/s',
        'color': Colors.orange,
      },
      {
        'label': 'Normal Readings',
        'value': '$normalReadings',
        'color': Colors.green,
      },
      {
        'label': 'Safety Rate',
        'value': '${safetyPercentage.toStringAsFixed(0)}%',
        'color': Colors.purple,
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
      itemBuilder: (context, index) {
        final metric = metrics[index];
        final color = metric['color'] as Color;
        final value = metric['value'] as String;
        final label = metric['label'] as String;

        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: const TextStyle(fontSize: 9, color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // ----- Components (gauges + small charts) -----
  Widget _buildComponentsSection() {
    // prefer real axes; if none, nothing renders here
    final axes = _getUniqueAxes();
    if (isLoadingVibrationData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (axes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: axes
          .map(
            (axisLabel) =>
                _buildComponentCard(axisLabel, _getAxisSeries(axisLabel)),
          )
          .toList(),
    );
  }

  Widget _buildComponentCard(String axisLabel, List<double> series) {
    final currentValue = series.isNotEmpty ? series.last : 0.0;
    final statusColor = _getStatusColor(currentValue);
    final icon = _getStatusIcon(currentValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(icon, color: statusColor, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  axisLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Text(
                  '${currentValue.toStringAsFixed(1)} mm/s',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildVibrationGauge(currentValue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _buildMiniLine(series)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildVibrationGauge(currentValue),
                    const SizedBox(height: 10),
                    _buildMiniLine(series),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVibrationGauge(double value) {
    return SizedBox(
      height: 90,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: 5,
            ranges: <GaugeRange>[
              GaugeRange(startValue: 0, endValue: 2, color: Colors.green),
              GaugeRange(startValue: 2, endValue: 3.5, color: Colors.orange),
              GaugeRange(startValue: 3.5, endValue: 5, color: Colors.red),
            ],
            pointers: <GaugePointer>[
              NeedlePointer(
                value: value,
                enableAnimation: true,
                needleColor: const Color(0xFF1E3A5F),
              ),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                positionFactor: 0.8,
                angle: 90,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniLine(List<double> values) {
    return SizedBox(
      height: 90,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                values.length,
                (i) => FlSpot(i.toDouble(), values[i]),
              ),
              isCurved: true,
              color: const Color(0xFF1E3A5F),
              barWidth: 2,
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF1E3A5F).withOpacity(0.1),
              ),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  // ----- Realtime Table -----
  Widget _buildRealtimeTableCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Recent Vibration Readings (Realtime)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: loadRealVibrationData,
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoadingVibrationData)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (realVibrationData.isEmpty)
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
                  DataColumn(label: _hdr('Vibration (mm/s)')),
                  DataColumn(label: _hdr('Frequency (Hz)')),
                  DataColumn(label: _hdr('Axis')),
                  DataColumn(label: _hdr('Status')),
                  DataColumn(label: _hdr('Actions')),
                ],
                rows: realVibrationData.take(25).map((r) {
                  final vib = (r['vibration_level'] ?? 0).toDouble();
                  final freq = (r['frequency'] ?? 0).toDouble();
                  final axis = r['axis']?.toString().toLowerCase() ?? '-';
                  final status = r['status']?.toString() ?? '-';
                  final crane = r['crane_id']?.toString() ?? '-';

                  // label: Axis X (Hoist Motor)
                  final axisLabel = axis.isEmpty || axis == '-'
                      ? '-'
                      : 'Axis ${axis.toUpperCase()} (${axisNames[axis] ?? axis.toUpperCase()})';

                  String time = '-';
                  final ts = r['timestamp'];
                  if (ts != null) {
                    try {
                      final dt = DateTime.parse(ts.toString()).toLocal();
                      time =
                          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    } catch (_) {}
                  }

                  final statusColor = _statusChipColor(status);

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(time, style: const TextStyle(fontSize: 11)),
                      ),
                      DataCell(
                        Text(crane, style: const TextStyle(fontSize: 11)),
                      ),
                      DataCell(
                        Text(
                          vib.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      DataCell(
                        Text(
                          freq.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      DataCell(
                        Text(axisLabel, style: const TextStyle(fontSize: 11)),
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
                          child: Text(
                            status.isEmpty
                                ? '-'
                                : status[0].toUpperCase() + status.substring(1),
                            style: TextStyle(
                              color: statusColor,
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
                              onPressed: () => _editVibrationReading(r),
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              onPressed: () => _deleteVibrationReading(r),
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

  // ----- helpers -----
  Widget _hdr(String t) => Text(
    t,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 11,
      color: Color(0xFF1E3A5F),
    ),
  );

  List<FlSpot> _generateChartSpots() {
    if (realVibrationData.isEmpty) return const [FlSpot(0, 0)];
    return List.generate(realVibrationData.length, (i) {
      final v = (realVibrationData[i]['vibration_level'] ?? 0).toDouble();
      return FlSpot(i.toDouble(), v);
    });
  }

  List<String> _getUniqueAxes() {
    final axes = <String>{};
    for (final r in realVibrationData) {
      final a = (r['axis']?.toString() ?? 'x').toLowerCase();
      final comp = axisNames[a] ?? a.toUpperCase();
      axes.add('Axis ${a.toUpperCase()} ($comp)');
    }
    return axes.toList();
  }

  List<double> _getAxisSeries(String axisLabel) {
    // axisLabel example: "Axis X (Hoist Motor)" -> extract 'x'
    final axis = axisLabel
        .split(' ')
        .elementAt(1)
        .replaceAll('(', '')
        .toLowerCase();
    final list = realVibrationData
        .where((r) => (r['axis']?.toString().toLowerCase() ?? 'x') == axis)
        .toList();

    // take last 8 points for compact card chart
    final start = list.length > 8 ? list.length - 8 : 0;
    final slice = list.sublist(start);

    return slice
        .map<double>((r) => (r['vibration_level'] ?? 0).toDouble())
        .toList();
  }

  Color _getStatusColor(double value) {
    if (value < 2) return Colors.green;
    if (value < 3.5) return Colors.orange;
    return Colors.red;
  }

  IconData _getStatusIcon(double value) {
    if (value < 2) return Icons.check_circle;
    if (value < 3.5) return Icons.warning;
    return Icons.error;
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

  Future<Map<String, dynamic>?> _openAddEditDialog({
    Map<String, dynamic>? initial,
  }) async {
    final editing = initial != null;

    final craneCtrl = TextEditingController(
      text: initial?['crane_id']?.toString() ?? '',
    );
    final vibCtrl = TextEditingController(
      text: _numToStr(initial?['vibration_level']),
    );
    final freqCtrl = TextEditingController(
      text: _numToStr(initial?['frequency']),
    );
    String axis = (initial?['axis']?.toString() ?? 'x').toLowerCase();
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
            editing ? 'Edit Vibration Reading' : 'Add Vibration Reading',
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
                            controller: vibCtrl,
                            label: 'Vibration (mm/s)',
                            hint: 'e.g., 3.25',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              final d = double.tryParse(v ?? '');
                              if (d == null) return 'Enter valid number';
                              if (d < 0) return 'Must be >= 0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _tf(
                            controller: freqCtrl,
                            label: 'Frequency (Hz)',
                            hint: 'e.g., 48.5',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              final d = double.tryParse(v ?? '');
                              if (d == null) return 'Enter valid number';
                              if (d < 0) return 'Must be >= 0';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _dd(
                            label: 'Axis',
                            value: axis,
                            items: const ['x', 'y', 'z'],
                            onChanged: (v) => axis = (v ?? 'x').toLowerCase(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dd(
                            label: 'Status',
                            value: status,
                            items: const ['normal', 'warning', 'critical'],
                            onChanged: (v) =>
                                status = (v ?? 'normal').toLowerCase(),
                          ),
                        ),
                      ],
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
                  'vibration_level': double.parse(vibCtrl.text.trim()),
                  'frequency': double.parse(freqCtrl.text.trim()),
                  'axis': axis,
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
    vibCtrl.dispose();
    freqCtrl.dispose();
    return result;
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

  Future<bool> _confirmDelete(BuildContext context) async {
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

  void _toast(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _numToStr(dynamic v) {
    if (v == null) return '';
    if (v is num) return v.toString();
    return v.toString();
  }

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

// small header icon
class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.vibration, color: Color(0xFF1E3A5F), size: 20),
    );
  }
}
