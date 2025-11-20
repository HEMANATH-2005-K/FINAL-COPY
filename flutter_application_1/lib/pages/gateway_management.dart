import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../widgets/sidebar.dart';

class GatewayManagementPage extends StatefulWidget {
  const GatewayManagementPage({super.key});

  @override
  State<GatewayManagementPage> createState() => _GatewayManagementPageState();
}

class _GatewayManagementPageState extends State<GatewayManagementPage> {
  List<Map<String, dynamic>> gateways = [];
  bool loading = true;
  RealtimeChannel? _channel;

  // ---------- Lifecycle ----------
  @override
  void initState() {
    super.initState();
    _loadGateways();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    if (_channel != null) {
      SupabaseService.supabase.removeChannel(_channel!);
    }
    super.dispose();
  }

  // ---------- Realtime ----------
  void _subscribeRealtime() {
    _channel = Supabase.instance.client.channel('iot_gateways_channel');

    _channel!
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'iot_gateways',
        callback: (_) => _loadGateways(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'iot_gateways',
        callback: (_) => _loadGateways(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'iot_gateways',
        callback: (_) => _loadGateways(),
      )
      ..subscribe();
  }

  Future<void> _loadGateways() async {
    setState(() => loading = true);
    final data = await SupabaseService.getIotGateways();
    setState(() {
      gateways = data;
      loading = false;
    });
  }

  // ---------- UI helpers ----------
  static Widget _hdr(String t) => Text(
    t,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: Color(0xFF1E3A5F),
    ),
  );

  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'online':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'offline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final onlineCount = gateways
        .where((g) => (g['status'] ?? '').toString() == 'online')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          'IoT Gateway Management',
          style: TextStyle(color: Color(0xFF1E3A5F)),
        ),
        elevation: 1,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _createGateway,
            icon: const Icon(Icons.add, color: Color(0xFF1E3A5F)),
            tooltip: 'Add Gateway',
          ),
          IconButton(
            onPressed: _loadGateways,
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A5F)),
          ),
        ],
      ),
      drawer: Sidebar(onItemSelected: (t) {}),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildKpis(onlineCount),
                  const SizedBox(height: 14),
                  _buildCharts(),
                  const SizedBox(height: 18),
                  _buildTableCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createGateway,
        backgroundColor: const Color(0xFF1E3A5F),
        icon: const Icon(Icons.add),
        label: const Text('Add Gateway'),
      ),
    );
  }

  // ---------- KPI ----------
  Widget _buildKpis(int onlineCount) {
    return Container(
      decoration: _card(),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _kpi(
              title: 'Total Gateways',
              value: '${gateways.length}',
              icon: Icons.router,
              color: Colors.blue,
            ),
          ),
          Expanded(
            child: _kpi(
              title: 'Online',
              value: '$onlineCount',
              icon: Icons.cloud_done,
              color: Colors.green,
            ),
          ),
          Expanded(
            child: _kpi(
              title: 'Offline',
              value:
                  '${gateways.where((g) => (g['status'] ?? '') == 'offline').length}',
              icon: Icons.cloud_off,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpi({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: _card(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(title),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Charts ----------
  Widget _buildCharts() {
    final statusCounts = <String, int>{};
    final locationCounts = <String, int>{};

    for (final g in gateways) {
      final s = (g['status'] ?? '').toString();
      final loc = (g['location'] ?? '').toString();
      statusCounts[s] = (statusCounts[s] ?? 0) + 1;
      locationCounts[loc] = (locationCounts[loc] ?? 0) + 1;
    }

    return Row(
      children: [
        Expanded(child: _statusPie(statusCounts)),
        const SizedBox(width: 12),
        Expanded(child: _locationBar(locationCounts)),
      ],
    );
  }

  Widget _statusPie(Map<String, int> data) {
    final sections = data.entries.map((e) {
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${e.key}\n${e.value}',
        radius: 50,
      );
    }).toList();

    return Container(
      decoration: _card(),
      padding: const EdgeInsets.all(12),
      height: 200,
      child: sections.isEmpty
          ? const Center(child: Text('No data'))
          : PieChart(PieChartData(sections: sections)),
    );
  }

  Widget _locationBar(Map<String, int> data) {
    final keys = data.keys.toList();
    final bars = <BarChartGroupData>[];

    for (var i = 0; i < keys.length; i++) {
      final k = keys[i];
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: (data[k] ?? 0).toDouble())],
        ),
      );
    }

    return Container(
      decoration: _card(),
      padding: const EdgeInsets.all(12),
      height: 200,
      child: bars.isEmpty
          ? const Center(child: Text('No data'))
          : BarChart(
              BarChartData(
                barGroups: bars,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= keys.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            keys[i],
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
              ),
            ),
    );
  }

  // ---------- Table ----------
  Widget _buildTableCard() {
    return Container(
      decoration: _card(),
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowHeight: 40,
          dataRowMinHeight: 40,
          columns: [
            DataColumn(label: _hdr('Gateway ID')),
            DataColumn(label: _hdr('Name')),
            DataColumn(label: _hdr('Location')),
            DataColumn(label: _hdr('Status')),
            DataColumn(label: _hdr('IP Address')),
            DataColumn(label: _hdr('Last Seen')),
            DataColumn(label: _hdr('Actions')),
          ],
          rows: gateways.map((g) {
            final status = (g['status'] ?? '').toString();
            final color = _statusColor(status);
            String lastSeen = '-';
            final ts = g['last_seen'];
            if (ts != null) {
              try {
                final dt = DateTime.parse(ts.toString()).toLocal();
                lastSeen =
                    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              } catch (_) {}
            }

            return DataRow(
              cells: [
                DataCell(Text(g['gateway_id']?.toString() ?? '')),
                DataCell(Text(g['name']?.toString() ?? '')),
                DataCell(Text(g['location']?.toString() ?? '')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status.isEmpty
                          ? '-'
                          : status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(g['ip_address']?.toString() ?? '')),
                DataCell(Text(lastSeen)),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _openAddEditDialog(initial: g),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _deleteGateway(g),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------- CRUD ----------
  Future<void> _createGateway() async {
    await _openAddEditDialog();
  }

  Future<void> _deleteGateway(Map row) async {
    final ok = await _confirmDelete();
    if (!ok) return;
    try {
      await SupabaseService.supabase
          .from('iot_gateways')
          .delete()
          .eq('id', row['id']);
      _toast('Gateway deleted');
      await _loadGateways();
    } catch (e) {
      _toast('Delete failed', error: true);
    }
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Gateway?'),
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

  Future<void> _openAddEditDialog({Map<String, dynamic>? initial}) async {
    final editing = initial != null;

    final gatewayIdCtrl = TextEditingController(
      text: initial?['gateway_id']?.toString() ?? '',
    );
    final nameCtrl = TextEditingController(
      text: initial?['name']?.toString() ?? '',
    );
    final locationCtrl = TextEditingController(
      text: initial?['location']?.toString() ?? '',
    );
    final ipCtrl = TextEditingController(
      text: initial?['ip_address']?.toString() ?? '',
    );
    String status = (initial?['status']?.toString() ?? 'online').toLowerCase();

    DateTime? lastSeen;
    if (initial?['last_seen'] != null) {
      try {
        lastSeen = DateTime.parse(initial!['last_seen'].toString()).toLocal();
      } catch (_) {}
    }

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(editing ? 'Edit Gateway' : 'Add Gateway'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _tf(
                    controller: gatewayIdCtrl,
                    label: 'Gateway ID',
                    hint: 'e.g., GW-001',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  _tf(
                    controller: nameCtrl,
                    label: 'Name',
                    hint: 'e.g., Main Gateway',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  _tf(
                    controller: locationCtrl,
                    label: 'Location',
                    hint: 'e.g., Control Room',
                  ),
                  const SizedBox(height: 10),
                  _tf(
                    controller: ipCtrl,
                    label: 'IP Address',
                    hint: 'e.g., 192.168.1.100',
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final ok =
                          RegExp(
                                r'^(?:\d{1,3}\.){3}\d{1,3}$',
                              ) // simple IPv4 check
                              .hasMatch(v.trim());
                      if (!ok) return 'Invalid IP format';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'online', child: Text('Online')),
                      DropdownMenuItem(
                        value: 'maintenance',
                        child: Text('Maintenance'),
                      ),
                      DropdownMenuItem(
                        value: 'offline',
                        child: Text('Offline'),
                      ),
                    ],
                    onChanged: (v) => status = v ?? 'online',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Last Seen',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          child: Text(
                            lastSeen == null
                                ? '-'
                                : '${lastSeen!.year}-${lastSeen!.month.toString().padLeft(2, '0')}-${lastSeen!.day.toString().padLeft(2, '0')} '
                                      '${lastSeen!.hour.toString().padLeft(2, '0')}:${lastSeen!.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await _pickDateTime(context, lastSeen);
                          if (picked != null) {
                            setState(() => lastSeen = picked);
                          }
                        },
                        icon: const Icon(Icons.edit_calendar, size: 18),
                        label: const Text('Pick'),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        onPressed: () =>
                            setState(() => lastSeen = DateTime.now()),
                        child: const Text('Now'),
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
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final payload = {
                'gateway_id': gatewayIdCtrl.text.trim(),
                'name': nameCtrl.text.trim(),
                'location': locationCtrl.text.trim(),
                'status': status,
                'ip_address': ipCtrl.text.trim().isEmpty
                    ? null
                    : ipCtrl.text.trim(),
                'last_seen': lastSeen?.toUtc().toIso8601String(),
              };

              try {
                if (editing) {
                  await SupabaseService.supabase
                      .from('iot_gateways')
                      .update(payload)
                      .eq('id', initial!['id']);
                  _toast('Gateway updated');
                } else {
                  await SupabaseService.supabase
                      .from('iot_gateways')
                      .insert(payload);
                  _toast('Gateway added');
                }
                if (mounted) Navigator.pop(ctx);
              } catch (e) {
                _toast('Save failed', error: true);
              }
            },
            child: Text(editing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );

    gatewayIdCtrl.dispose();
    nameCtrl.dispose();
    locationCtrl.dispose();
    ipCtrl.dispose();
  }

  // ---------- Inputs ----------
  static Widget _tf({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime? initial,
  ) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null) return null;
    final t = await showTimePicker(
      context: context,
      initialTime: initial != null
          ? TimeOfDay(hour: initial.hour, minute: initial.minute)
          : TimeOfDay(hour: now.hour, minute: now.minute),
    );
    if (t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }
}
