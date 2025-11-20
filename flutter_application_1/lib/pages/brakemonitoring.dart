// lib/pages/brake_status.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../widgets/sidebar.dart';

class BrakeStatusPage extends StatefulWidget {
  const BrakeStatusPage({super.key});

  @override
  State<BrakeStatusPage> createState() => _BrakeStatusPageState();
}

class _BrakeStatusPageState extends State<BrakeStatusPage> {
  // Filters (optional UI)
  String selectedCrane = 'All';
  String selectedStatus = 'All';

  final cranes = <String>['All']; // will fill from data
  final statuses = const ['All', 'normal', 'maintenance', 'critical'];

  // Data
  List<Map<String, dynamic>> rows = [];
  bool loading = true;

  // Realtime
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _unsubscribeRealtime();
    super.dispose();
  }

  // ---------- DATA ----------
  Future<void> _load() async {
    try {
      final data = await SupabaseService.getBrakeStatus();
      if (!mounted) return;
      setState(() {
        rows = data;
        loading = false;
      });
      _refreshCraneFilterOptions();
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _toast('Failed to load brake status', isError: true);
    }
  }

  void _refreshCraneFilterOptions() {
    final set = <String>{'All'};
    for (final r in rows) {
      final id = r['crane_id']?.toString();
      if (id != null && id.isNotEmpty) set.add(id);
    }
    cranes
      ..clear()
      ..addAll(set);
  }

  void _subscribeRealtime() {
    _channel = Supabase.instance.client.channel('brake_status_ch');

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'brake_status',
      callback: (_) => _load(),
    );
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'brake_status',
      callback: (_) => _load(),
    );
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'brake_status',
      callback: (_) => _load(),
    );

    _channel!.subscribe();
  }

  void _unsubscribeRealtime() {
    if (_channel != null) {
      SupabaseService.supabase.removeChannel(_channel!);
      _channel = null;
    }
  }

  // ---------- CRUD ----------
  Future<void> _create() async {
    final form = await _openAddEditDialog();
    if (form == null) return;
    try {
      await SupabaseService.supabase.from('brake_status').insert({
        'crane_id': form['crane_id'],
        'brake_position': form['brake_position'],
        'wear_level': form['wear_level'],
        'pressure': form['pressure'],
        'status': form['status'],
        'last_maintenance': form['last_maintenance'], // yyyy-mm-dd
      });
      _toast('Brake record added');
      await _load();
    } catch (e) {
      _toast('Failed to add', isError: true);
    }
  }

  Future<void> _edit(Map<String, dynamic> row) async {
    final id = row['id'];
    if (id == null) {
      _toast('Missing id', isError: true);
      return;
    }
    final form = await _openAddEditDialog(initial: row);
    if (form == null) return;

    try {
      await SupabaseService.supabase
          .from('brake_status')
          .update({
            'crane_id': form['crane_id'],
            'brake_position': form['brake_position'],
            'wear_level': form['wear_level'],
            'pressure': form['pressure'],
            'status': form['status'],
            'last_maintenance': form['last_maintenance'],
          })
          .eq('id', id);
      _toast('Updated');
      await _load();
    } catch (e) {
      _toast('Failed to update', isError: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final id = row['id'];
    if (id == null) {
      _toast('Missing id', isError: true);
      return;
    }
    final sure = await _confirmDelete();
    if (!sure) return;
    try {
      await SupabaseService.supabase.from('brake_status').delete().eq('id', id);
      _toast('Deleted');
      await _load();
    } catch (e) {
      _toast('Failed to delete', isError: true);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    // KPIs
    final k = _computeKpis(rows);

    final filtered = rows.where((r) {
      final okCrane = selectedCrane == 'All'
          ? true
          : (r['crane_id']?.toString() == selectedCrane);
      final okStatus = selectedStatus == 'All'
          ? true
          : (r['status']?.toString().toLowerCase() == selectedStatus);
      return okCrane && okStatus;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          'Brake Status',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A5F),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF1E3A5F)),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _create,
            icon: const Icon(Icons.add, color: Color(0xFF1E3A5F)),
            tooltip: 'Add Record',
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A5F)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Sidebar(onItemSelected: (title) {}),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: const Color(0xFF1E3A5F),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 12),
            _kpiRow(k),
            const SizedBox(height: 12),
            _filters(),
            const SizedBox(height: 12),
            _tableCard(filtered),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A5F).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.handyman, color: Color(0xFF1E3A5F), size: 20),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Brake Condition & Wear',
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

  Widget _kpiRow(_Kpis k) {
    Widget _card(String label, String value, Color c) => Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: c,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );

    return Row(
      children: [
        _card('Avg Wear', '${k.avgWear.toStringAsFixed(1)} %', Colors.blue),
        _card(
          'Avg Pressure',
          '${k.avgPressure.toStringAsFixed(1)}',
          Colors.teal,
        ),
        _card('Critical Count', '${k.critical}', Colors.red),
      ],
    );
  }

  Widget _filters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: labeledDropdown(
              label: 'Crane',
              value: selectedCrane,
              items: cranes,
              onChanged: (v) => setState(() => selectedCrane = v ?? 'All'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: labeledDropdown(
              label: 'Status',
              value: selectedStatus,
              items: statuses,
              onChanged: (v) => setState(() => selectedStatus = v ?? 'All'),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Added missing helper to fix “The method 'labeledDropdown' isn't defined” errors
  Widget labeledDropdown({
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

  Widget _tableCard(List<Map<String, dynamic>> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            children: const [
              Text(
                'Brake Records (Realtime)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (data.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Text('No data'))
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
                  DataColumn(label: _hdr('Position')),
                  DataColumn(label: _hdr('Wear %')),
                  DataColumn(label: _hdr('Pressure')),
                  DataColumn(label: _hdr('Status')),
                  DataColumn(label: _hdr('Last Maint.')),
                  DataColumn(label: _hdr('Actions')),
                ],
                rows: data.map((r) {
                  final crane = r['crane_id']?.toString() ?? '-';
                  final posRaw = r['brake_position']?.toString() ?? '-';
                  final pos = posRaw.isEmpty ? '-' : posRaw;
                  final wear = (r['wear_level'] ?? 0).toString();
                  final press = (r['pressure'] ?? 0).toString();
                  final status = (r['status'] ?? '-').toString();
                  final lm = r['last_maintenance']?.toString();

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
                          pos == '-'
                              ? '-'
                              : (pos[0].toUpperCase() + pos.substring(1)),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      DataCell(
                        Text(wear, style: const TextStyle(fontSize: 11)),
                      ),
                      DataCell(
                        Text(press, style: const TextStyle(fontSize: 11)),
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
                                : (status[0].toUpperCase() +
                                      status.substring(1)),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          (lm == null || lm.isEmpty) ? '-' : lm,
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

  // ---------- Small helpers ----------
  static Widget _hdr(String t) => Text(
    t,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: Color(0xFF1E3A5F),
    ),
  );

  _Kpis _computeKpis(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return const _Kpis(0, 0, 0);
    double wear = 0;
    double pressure = 0;
    int critical = 0;
    for (final r in list) {
      wear += (r['wear_level'] ?? 0) is num
          ? (r['wear_level'] as num).toDouble()
          : 0;
      pressure += (r['pressure'] ?? 0) is num
          ? (r['pressure'] as num).toDouble()
          : 0;
      if ((r['status']?.toString().toLowerCase() ?? '') == 'critical') {
        critical++;
      }
    }
    return _Kpis(wear / list.length, pressure / list.length, critical);
  }

  Color _statusChipColor(String s) {
    switch (s.toLowerCase()) {
      case 'normal':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ---------- Dialogs / inputs ----------
  Future<Map<String, dynamic>?> _openAddEditDialog({
    Map<String, dynamic>? initial,
  }) async {
    final editing = initial != null;

    final craneCtrl = TextEditingController(
      text: initial?['crane_id']?.toString() ?? '',
    );
    final wearCtrl = TextEditingController(
      text: initial?['wear_level']?.toString() ?? '',
    );
    final pressCtrl = TextEditingController(
      text: initial?['pressure']?.toString() ?? '',
    );

    String brakePos = (initial?['brake_position']?.toString() ?? 'engaged')
        .toLowerCase();
    String status = (initial?['status']?.toString() ?? 'normal').toLowerCase();
    DateTime? lastMaint;
    try {
      final lm = initial?['last_maintenance'];
      if (lm != null && lm.toString().isNotEmpty) {
        lastMaint = DateTime.parse(lm.toString());
      }
    } catch (_) {}

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(editing ? 'Edit Brake Record' : 'Add Brake Record'),
          content: SizedBox(
            width: 440,
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
                          child: _dd(
                            label: 'Brake Position',
                            value: brakePos,
                            items: const ['engaged', 'disengaged', 'partial'],
                            onChanged: (v) => brakePos = v ?? 'engaged',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dd(
                            label: 'Status',
                            value: status,
                            items: const ['normal', 'maintenance', 'critical'],
                            onChanged: (v) => status = v ?? 'normal',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _tf(
                            controller: wearCtrl,
                            label: 'Wear Level (%)',
                            hint: 'e.g., 25.0',
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
                            controller: pressCtrl,
                            label: 'Pressure',
                            hint: 'e.g., 240.5',
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Text('Last Maintenance:  '),
                          TextButton(
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: ctx,
                                firstDate: DateTime(now.year - 5),
                                lastDate: DateTime(now.year + 1),
                                initialDate: lastMaint ?? now,
                              );
                              if (picked != null) {
                                setState(() {
                                  lastMaint = picked;
                                });
                              }
                            },
                            child: Text(
                              lastMaint == null
                                  ? 'Select Date'
                                  : '${lastMaint!.year}-${lastMaint!.month.toString().padLeft(2, '0')}-${lastMaint!.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ],
                      ),
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
                  'brake_position': brakePos,
                  'wear_level': double.parse(wearCtrl.text.trim()),
                  'pressure': double.parse(pressCtrl.text.trim()),
                  'status': status,
                  'last_maintenance': lastMaint == null
                      ? null
                      : '${lastMaint!.year}-${lastMaint!.month.toString().padLeft(2, '0')}-${lastMaint!.day.toString().padLeft(2, '0')}',
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
    wearCtrl.dispose();
    pressCtrl.dispose();
    return result;
  }

  // inputs
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

  // dialogs, toasts
  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Record?'),
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
}

class _Kpis {
  final double avgWear;
  final double avgPressure;
  final int critical;
  const _Kpis(this.avgWear, this.avgPressure, this.critical);
}
