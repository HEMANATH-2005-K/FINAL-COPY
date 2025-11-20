// pages/error_logs.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/sidebar.dart';

class ErrorLogsPage extends StatefulWidget {
  const ErrorLogsPage({super.key});

  @override
  State<ErrorLogsPage> createState() => _ErrorLogsPageState();
}

class _ErrorLogsPageState extends State<ErrorLogsPage> {
  final _sb = Supabase.instance.client;

  // filters
  String selectedSeverity = 'All';
  String selectedResolved = 'All'; // All / Resolved / Unresolved

  // data
  List<Map<String, dynamic>> rows = [];
  bool loading = true;

  // realtime
  RealtimeChannel? _chan;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRt();
  }

  @override
  void dispose() {
    if (_chan != null) _sb.removeChannel(_chan!);
    super.dispose();
  }

  // ---------- data load + realtime ----------
  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await _sb
          .from('error_logs')
          .select()
          .order('timestamp', ascending: false);
      setState(() => rows = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      _toast('Failed to load error logs', error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _subscribeRt() {
    _chan = _sb.channel('error_logs_rt')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'error_logs',
        callback: (_) => _load(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'error_logs',
        callback: (_) => _load(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'error_logs',
        callback: (_) => _load(),
      )
      ..subscribe();
  }

  // ---------- CRUD ----------
  Future<void> _create() async {
    final form = await _openDialog();
    if (form == null) return;
    try {
      await _sb.from('error_logs').insert(form);
      _toast('Log added');
      await _load();
    } catch (e) {
      _toast('Insert failed', error: true);
    }
  }

  Future<void> _edit(Map<String, dynamic> row) async {
    final id = row['id'];
    if (id == null) return;
    final form = await _openDialog(initial: row);
    if (form == null) return;
    try {
      await _sb.from('error_logs').update(form).eq('id', id);
      _toast('Updated');
      await _load();
    } catch (e) {
      _toast('Update failed', error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final id = row['id'];
    if (id == null) return;
    final ok = await _confirmDelete();
    if (!ok) return;
    try {
      await _sb.from('error_logs').delete().eq('id', id);
      _toast('Deleted');
      await _load();
    } catch (e) {
      _toast('Delete failed', error: true);
    }
  }

  Future<void> _toggleResolved(Map<String, dynamic> row) async {
    final id = row['id'];
    final current = (row['resolved'] ?? false) == true;
    try {
      await _sb.from('error_logs').update({'resolved': !current}).eq('id', id);
      _toast(!current ? 'Marked resolved' : 'Marked unresolved');
      await _load();
    } catch (e) {
      _toast('Update failed', error: true);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final severities = const ['All', 'low', 'medium', 'high', 'critical'];

    final filtered = rows.where((r) {
      final sevOk =
          selectedSeverity == 'All' ||
          (r['severity']?.toString().toLowerCase() == selectedSeverity);
      final res = (r['resolved'] ?? false) == true;
      final resOk =
          selectedResolved == 'All' ||
          (selectedResolved == 'Resolved' && res) ||
          (selectedResolved == 'Unresolved' && !res);
      return sevOk && resOk;
    }).toList();

    // KPIs
    final total = filtered.length;
    final unresolved = filtered
        .where((r) => (r['resolved'] ?? false) == false)
        .length;
    final critical = filtered
        .where((r) => (r['severity']?.toString().toLowerCase() == 'critical'))
        .length;
    final lastMsg = total > 0
        ? (filtered.first['error_message']?.toString() ?? '-')
        : '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          'Error Logs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A5F),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _create,
            icon: const Icon(Icons.add, color: Color(0xFF1E3A5F)),
            tooltip: 'Add Log',
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A5F)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Sidebar(onItemSelected: (t) {}),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 12),
            _filters(
              severities: severities,
              onSev: (v) => setState(() => selectedSeverity = v ?? 'All'),
              onResolved: (v) => setState(() => selectedResolved = v ?? 'All'),
            ),
            const SizedBox(height: 12),
            _kpis(total, unresolved, critical, lastMsg),
            const SizedBox(height: 12),
            _tableCard(filtered),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: const Color(0xFF1E3A5F),
        icon: const Icon(Icons.add),
        label: const Text('Add Log'),
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
          child: const Icon(
            Icons.error_outline,
            color: Color(0xFF1E3A5F),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'System Error & Alarm Log',
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

  Widget _filters({
    required List<String> severities,
    required ValueChanged<String?> onSev,
    required ValueChanged<String?> onResolved,
  }) {
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
            child: _labeledDropdown(
              label: 'Severity',
              value: selectedSeverity,
              items: severities,
              onChanged: onSev,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _labeledDropdown(
              label: 'Resolved',
              value: selectedResolved,
              items: const ['All', 'Resolved', 'Unresolved'],
              onChanged: onResolved,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpis(int total, int unresolved, int critical, String lastMsg) {
    final cards = [
      {'label': 'Total Logs', 'value': '$total', 'color': Colors.blue},
      {'label': 'Unresolved', 'value': '$unresolved', 'color': Colors.orange},
      {'label': 'Critical', 'value': '$critical', 'color': Colors.redAccent},
      {'label': 'Latest', 'value': lastMsg, 'color': Colors.teal},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 3.0,
      ),
      itemCount: cards.length,
      itemBuilder: (context, i) {
        final c = cards[i];
        final color = c['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                c['value'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                c['label'] as String,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        );
      },
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
            children: [
              const Text(
                'Recent Error Logs (Realtime)',
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
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (data.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No data found'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                dataRowMinHeight: 40,
                headingRowHeight: 40,
                columns: [
                  DataColumn(label: _hdr('Time')),
                  DataColumn(label: _hdr('Crane')),
                  DataColumn(label: _hdr('Error Code')),
                  DataColumn(label: _hdr('Message')),
                  DataColumn(label: _hdr('Severity')),
                  DataColumn(label: _hdr('Resolved')),
                  DataColumn(label: _hdr('Actions')),
                ],
                rows: data.take(50).map((r) {
                  final crane = r['crane_id']?.toString() ?? '-';
                  final code = r['error_code']?.toString() ?? '-';
                  final msg = r['error_message']?.toString() ?? '-';
                  final sev = r['severity']?.toString() ?? '-';
                  final resolved = (r['resolved'] ?? false) == true;

                  String time = '-';
                  final ts = r['timestamp'];
                  if (ts != null) {
                    try {
                      final dt = DateTime.parse(ts.toString()).toLocal();
                      time =
                          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    } catch (_) {}
                  }

                  final sevColor = _sevColor(sev);

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(time, style: const TextStyle(fontSize: 11)),
                      ),
                      DataCell(
                        Text(crane, style: const TextStyle(fontSize: 11)),
                      ),
                      DataCell(
                        Text(code, style: const TextStyle(fontSize: 11)),
                      ),
                      DataCell(
                        SizedBox(
                          width: 240,
                          child: Text(
                            msg,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: sevColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _title(sev),
                            style: TextStyle(
                              color: sevColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              resolved
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: resolved ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              resolved ? 'Yes' : 'No',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _toggleResolved(r),
                              icon: const Icon(Icons.task_alt, size: 18),
                              tooltip: 'Toggle Resolved',
                            ),
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

  // ---------- misc helpers ----------
  static Widget _hdr(String t) => Text(
    t,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 11,
      color: Color(0xFF1E3A5F),
    ),
  );

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

  Color _sevColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.blueGrey;
      case 'medium':
        return Colors.amber;
      case 'high':
        return Colors.deepOrange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _title(String s) =>
      s.isEmpty ? '-' : s[0].toUpperCase() + s.substring(1);

  Future<Map<String, dynamic>?> _openDialog({
    Map<String, dynamic>? initial,
  }) async {
    final editing = initial != null;

    final craneCtrl = TextEditingController(
      text: initial?['crane_id']?.toString() ?? '',
    );
    final codeCtrl = TextEditingController(
      text: initial?['error_code']?.toString() ?? '',
    );
    final msgCtrl = TextEditingController(
      text: initial?['error_message']?.toString() ?? '',
    );
    String severity = (initial?['severity']?.toString() ?? 'low').toLowerCase();
    bool resolved = (initial?['resolved'] ?? false) == true;

    final key = GlobalKey<FormState>();

    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(editing ? 'Edit Error Log' : 'Add Error Log'),
        content: SizedBox(
          width: 460,
          child: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _tf(
                    controller: craneCtrl,
                    label: 'Crane ID',
                    hint: 'e.g., CRANE-001',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _tf(
                          controller: codeCtrl,
                          label: 'Error Code',
                          hint: 'e.g., TEMP_HIGH',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: severity,
                          items: const ['low', 'medium', 'high', 'critical']
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => severity = v ?? 'low',
                          decoration: InputDecoration(
                            labelText: 'Severity',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _tf(
                    controller: msgCtrl,
                    label: 'Message',
                    hint: 'Brief description…',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: resolved,
                    onChanged: (v) => resolved = v,
                    title: const Text('Resolved'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
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
              if (!key.currentState!.validate()) return;
              Navigator.pop<Map<String, dynamic>>(ctx, {
                'crane_id': craneCtrl.text.trim(),
                'error_code': codeCtrl.text.trim(),
                'error_message': msgCtrl.text.trim(),
                'severity': severity,
                'resolved': resolved,
              });
            },
            child: Text(editing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );

    craneCtrl.dispose();
    codeCtrl.dispose();
    msgCtrl.dispose();
    return res;
  }

  static Widget _tf({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      validator: validator,
    );
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete log?'),
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
}
