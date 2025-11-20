// lib/pages/energymonitoring.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../widgets/sidebar.dart';

class EnergyMonitoringDashboard extends StatefulWidget {
  const EnergyMonitoringDashboard({super.key});

  @override
  State<EnergyMonitoringDashboard> createState() =>
      _EnergyMonitoringDashboardState();
}

class _EnergyMonitoringDashboardState extends State<EnergyMonitoringDashboard> {
  // Filters (feel free to wire to server later)
  String selectedCrane = 'All Cranes';
  String selectedRange = 'Today';

  final cranes = const ['All Cranes', 'CRANE-001', 'CRANE-002', 'CRANE-003'];
  final ranges = const ['Today', 'This Week', 'This Month'];

  // Data
  List<Map<String, dynamic>> rows = [];
  bool loading = true;

  // Realtime
  RealtimeChannel? _channel;

  // ---------- lifecycle ----------
  @override
  void initState() {
    super.initState();
    _fetch();
    _subscribe();
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  // ---------- realtime ----------
  void _subscribe() {
    _channel = Supabase.instance.client.channel('energy_usage_channel');

    _channel!
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'energy_usage',
        callback: (_) => _fetch(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'energy_usage',
        callback: (_) => _fetch(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'energy_usage',
        callback: (_) => _fetch(),
      )
      ..subscribe();
  }

  void _unsubscribe() {
    if (_channel != null) {
      SupabaseService.supabase.removeChannel(_channel!);
      _channel = null;
    }
  }

  // ---------- data ----------
  Future<void> _fetch() async {
    try {
      final data = await SupabaseService.getEnergyUsage();
      if (!mounted) return;
      setState(() {
        rows = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _toast('Failed to load energy data', isError: true);
    }
  }

  // ---------- CRUD ----------
  Future<void> _add() async {
    final form = await _openForm();
    if (form == null) return;
    try {
      await SupabaseService.supabase.from('energy_usage').insert({
        'crane_id': form['crane_id'],
        'power_consumption': form['power_consumption'],
        'voltage': form['voltage'],
        'current': form['current'],
        'efficiency': form['efficiency'],
      });
      _toast('Reading added');
      await _fetch(); // realtime will also refresh
    } catch (e) {
      _toast('Failed to add reading', isError: true);
    }
  }

  Future<void> _edit(Map<String, dynamic> row) async {
    final id = row['id'];
    if (id == null) {
      _toast('Row id missing', isError: true);
      return;
    }
    final form = await _openForm(initial: row);
    if (form == null) return;

    try {
      await SupabaseService.supabase
          .from('energy_usage')
          .update({
            'crane_id': form['crane_id'],
            'power_consumption': form['power_consumption'],
            'voltage': form['voltage'],
            'current': form['current'],
            'efficiency': form['efficiency'],
          })
          .eq('id', id);
      _toast('Reading updated');
      await _fetch();
    } catch (e) {
      _toast('Failed to update', isError: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final id = row['id'];
    if (id == null) {
      _toast('Row id missing', isError: true);
      return;
    }
    final ok = await _confirmDelete();
    if (!ok) return;

    try {
      await SupabaseService.supabase.from('energy_usage').delete().eq('id', id);
      _toast('Reading deleted');
      await _fetch();
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
          'Energy Monitoring',
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
            onPressed: _add,
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Color(0xFF1E3A5F)),
            onPressed: () => Navigator.pushNamed(context, '/dashboard'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Sidebar(onItemSelected: (title) {}),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: const Color(0xFF1E3A5F),
        icon: const Icon(Icons.add),
        label: const Text('Add Reading'),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 12),
              _filters(),
              const SizedBox(height: 12),
              _overviewSection(),
              const SizedBox(height: 12),
              _tableCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A5F).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bolt, color: Color(0xFF1E3A5F), size: 20),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Electrical Consumption',
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

  Widget _filters() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
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
                  value: selectedRange,
                  items: ranges,
                  onChanged: (v) => setState(() => selectedRange = v!),
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
                  label: const Text('Apply Filters'),
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
                      selectedRange = ranges.first;
                    });
                    _toast('Filters reset');
                  },
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Reset'),
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

  Widget _overviewSection() {
    // Aggregate metrics from current rows
    final total = rows.fold<double>(
      0,
      (sum, r) => sum + _toDouble(r['power_consumption']),
    );
    final avgPower = rows.isNotEmpty ? total / rows.length : 0;
    final maxPower = rows.fold<double>(
      0,
      (m, r) => _toDouble(r['power_consumption']) > m
          ? _toDouble(r['power_consumption'])
          : m,
    );
    final avgEff = rows.isNotEmpty
        ? rows.fold<double>(0, (s, r) => s + _toDouble(r['efficiency'])) /
              rows.length
        : 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Energy Overview',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const Spacer(),
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _fetch,
                  icon: const Icon(Icons.refresh, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: loading || rows.isEmpty
                ? const Center(child: Text('No chart data'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (v, _) => Text(
                              '${v.toInt()} kW',
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
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= rows.length) {
                                return const SizedBox.shrink();
                              }
                              final ts = rows[i]['timestamp'];
                              String label = 't$i';
                              try {
                                final dt = DateTime.parse(
                                  ts.toString(),
                                ).toLocal();
                                label =
                                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                              } catch (_) {}
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
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(rows.length, (i) {
                            final y = _toDouble(rows[i]['power_consumption']);
                            return FlSpot(i.toDouble(), y);
                          }),
                          isCurved: true,
                          color: const Color(0xFF1E3A5F),
                          barWidth: 2.5,
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF1E3A5F).withOpacity(0.12),
                          ),
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            children: [
              _metric(
                'Avg Power',
                '${avgPower.toStringAsFixed(1)} kW',
                Colors.blue,
              ),
              _metric(
                'Peak Power',
                '${maxPower.toStringAsFixed(1)} kW',
                Colors.orange,
              ),
              _metric('Readings', '${rows.length}', Colors.green),
              _metric(
                'Avg Efficiency',
                '${avgEff.toStringAsFixed(1)}%',
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent Energy Readings (Realtime)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _fetch,
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No data found')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                dataRowMinHeight: 36,
                headingRowHeight: 36,
                // IMPORTANT: Do NOT make this list `const` because _hdr() is a function
                columns: [
                  DataColumn(label: _hdr('Time')),
                  DataColumn(label: _hdr('Crane')),
                  DataColumn(label: _hdr('Power (kW)')),
                  DataColumn(label: _hdr('Voltage (V)')),
                  DataColumn(label: _hdr('Current (A)')),
                  DataColumn(label: _hdr('Efficiency (%)')),
                  DataColumn(label: _hdr('Actions')),
                ],
                rows: rows.take(50).map((r) {
                  final power = _toDouble(r['power_consumption']);
                  final volt = _toDouble(r['voltage']);
                  final curr = _toDouble(r['current']);
                  final eff = _toDouble(r['efficiency']);
                  final crane = r['crane_id']?.toString() ?? '-';

                  String time = '-';
                  final ts = r['timestamp'];
                  if (ts != null) {
                    try {
                      final dt = DateTime.parse(ts.toString()).toLocal();
                      time =
                          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    } catch (_) {}
                  }

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
                          power.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      DataCell(
                        Text(
                          volt.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      DataCell(
                        Text(
                          curr.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      DataCell(
                        Text(
                          eff.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _edit(r),
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              onPressed: () => _delete(r),
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

  // ---------- helpers ----------
  static BoxDecoration _card() => BoxDecoration(
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

  static Widget _hdr(String t) => Text(
    t,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
  );

  Widget _metric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
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
                .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<Map<String, dynamic>?> _openForm({
    Map<String, dynamic>? initial,
  }) async {
    final isEdit = initial != null;

    final craneCtrl = TextEditingController(
      text: initial?['crane_id']?.toString() ?? '',
    );
    final powerCtrl = TextEditingController(
      text: _numToStr(initial?['power_consumption']),
    );
    final voltCtrl = TextEditingController(
      text: _numToStr(initial?['voltage']),
    );
    final currCtrl = TextEditingController(
      text: _numToStr(initial?['current']),
    );
    final effCtrl = TextEditingController(
      text: _numToStr(initial?['efficiency']),
    );

    final formKey = GlobalKey<FormState>();

    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(isEdit ? 'Edit Energy Reading' : 'Add Energy Reading'),
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
                            controller: powerCtrl,
                            label: 'Power (kW)',
                            hint: 'e.g., 210.3',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: _numValidator,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _tf(
                            controller: voltCtrl,
                            label: 'Voltage (V)',
                            hint: 'e.g., 415',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: _numValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _tf(
                            controller: currCtrl,
                            label: 'Current (A)',
                            hint: 'e.g., 302.4',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: _numValidator,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _tf(
                            controller: effCtrl,
                            label: 'Efficiency (%)',
                            hint: 'e.g., 88.5',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              final d = double.tryParse((v ?? '').trim());
                              if (d == null) return 'Enter valid number';
                              if (d < 0 || d > 100) {
                                return 'Must be 0–100';
                              }
                              return null;
                            },
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
              ),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop<Map<String, dynamic>>(ctx, {
                  'crane_id': craneCtrl.text.trim(),
                  'power_consumption': double.parse(powerCtrl.text.trim()),
                  'voltage': double.parse(voltCtrl.text.trim()),
                  'current': double.parse(currCtrl.text.trim()),
                  'efficiency': double.parse(effCtrl.text.trim()),
                });
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    );

    craneCtrl.dispose();
    powerCtrl.dispose();
    voltCtrl.dispose();
    currCtrl.dispose();
    effCtrl.dispose();
    return res;
  }

  static String? _numValidator(String? v) {
    final d = double.tryParse((v ?? '').trim());
    if (d == null) return 'Enter valid number';
    if (d < 0) return 'Must be ≥ 0';
    return null;
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

  String _numToStr(dynamic v) {
    if (v == null) return '';
    if (v is num) return v.toString();
    return v.toString();
  }
}
