// pages/data_hub.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/sidebar.dart';

class DataHubPage extends StatefulWidget {
  const DataHubPage({super.key});

  @override
  State<DataHubPage> createState() => _DataHubPageState();
}

class _DataHubPageState extends State<DataHubPage> {
  final _sb = Supabase.instance.client;

  // filters
  String selFormat = 'All';
  String selStatus = 'All';

  // data
  List<Map<String, dynamic>> rows = [];
  bool loading = true;

  // realtime channel
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

  // ------------ LOAD + REALTIME ------------
  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await _sb
          .from('data_exports')
          .select()
          .order('created_at', ascending: false);
      setState(() => rows = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      _toast('Failed to load exports', error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _subscribeRt() {
    _chan = _sb.channel('data_exports_rt')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'data_exports',
        callback: (_) => _load(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'data_exports',
        callback: (_) => _load(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'data_exports',
        callback: (_) => _load(),
      )
      ..subscribe();
  }

  // ------------ CRUD ------------
  Future<void> _create() async {
    final form = await _openDialog();
    if (form == null) return;
    try {
      await _sb.from('data_exports').insert(form);
      _toast('Export job created');
      await _load();
    } catch (e) {
      _toast('Create failed', error: true);
    }
  }

  Future<void> _edit(Map<String, dynamic> row) async {
    final id = row['id'];
    if (id == null) return;
    final form = await _openDialog(initial: row);
    if (form == null) return;
    try {
      await _sb.from('data_exports').update(form).eq('id', id);
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
      await _sb.from('data_exports').delete().eq('id', id);
      _toast('Deleted');
      await _load();
    } catch (e) {
      _toast('Delete failed', error: true);
    }
  }

  // Quick action: simulate status step (pending -> processing -> completed)
  Future<void> _advanceStatus(Map<String, dynamic> row) async {
    final id = row['id'];
    if (id == null) return;
    final current = (row['status'] ?? 'pending').toString();
    String next = current;
    switch (current) {
      case 'pending':
        next = 'processing';
        break;
      case 'processing':
        next = 'completed';
        break;
      case 'completed':
        next = 'completed';
        break;
      case 'failed':
        next = 'pending';
        break;
    }
    try {
      await _sb.from('data_exports').update({'status': next}).eq('id', id);
      _toast('Status -> $next');
      await _load();
    } catch (e) {
      _toast('Failed to update status', error: true);
    }
  }

  // ------------ UI ------------
  @override
  Widget build(BuildContext context) {
    // dropdown options derived from rows
    final formats = <String>{'All', 'csv', 'json', 'pdf'};
    final statuses = <String>{
      'All',
      'pending',
      'processing',
      'completed',
      'failed',
    };
    // apply filters
    final filtered = rows.where((r) {
      final fOk = selFormat == 'All' || (r['format']?.toString() == selFormat);
      final sOk = selStatus == 'All' || (r['status']?.toString() == selStatus);
      return fOk && sOk;
    }).toList();

    // KPIs
    final total = filtered.length;
    final completed = filtered.where((r) => r['status'] == 'completed').length;
    final processing = filtered
        .where((r) => r['status'] == 'processing')
        .length;
    final failed = filtered.where((r) => r['status'] == 'failed').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          'Data Hub',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A5F),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Create Export',
            onPressed: _create,
            icon: const Icon(Icons.add, color: Color(0xFF1E3A5F)),
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
              formats: formats.toList(),
              statuses: statuses.toList(),
              onFormat: (v) => setState(() => selFormat = v ?? 'All'),
              onStatus: (v) => setState(() => selStatus = v ?? 'All'),
            ),
            const SizedBox(height: 12),
            _kpis(total, completed, processing, failed),
            const SizedBox(height: 12),
            _tableCard(filtered),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: const Color(0xFF1E3A5F),
        icon: const Icon(Icons.add),
        label: const Text('Create Export'),
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
            Icons.cloud_download,
            color: Color(0xFF1E3A5F),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Manage and track your data exports',
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
    required List<String> formats,
    required List<String> statuses,
    required ValueChanged<String?> onFormat,
    required ValueChanged<String?> onStatus,
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
              label: 'Format',
              value: selFormat,
              items: formats,
              onChanged: onFormat,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _labeledDropdown(
              label: 'Status',
              value: selStatus,
              items: statuses,
              onChanged: onStatus,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpis(int total, int completed, int processing, int failed) {
    final cards = [
      {'label': 'Total Exports', 'value': '$total', 'color': Colors.blue},
      {'label': 'Completed', 'value': '$completed', 'color': Colors.green},
      {'label': 'Processing', 'value': '$processing', 'color': Colors.orange},
      {'label': 'Failed', 'value': '$failed', 'color': Colors.red},
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
                'Exports (Realtime)',
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
                  DataColumn(label: _hdr('Created')),
                  DataColumn(label: _hdr('Export Name')),
                  DataColumn(label: _hdr('Format')),
                  DataColumn(label: _hdr('Status')),
                  DataColumn(label: _hdr('File URL')),
                  DataColumn(label: _hdr('Actions')),
                ],
                rows: data.take(100).map((r) {
                  final name = r['export_name']?.toString() ?? '-';
                  final format = r['format']?.toString() ?? '-';
                  final status = r['status']?.toString() ?? '-';
                  final url = r['file_url']?.toString() ?? '';
                  String time = '-';
                  final ts = r['created_at'];
                  if (ts != null) {
                    try {
                      final dt = DateTime.parse(ts.toString()).toLocal();
                      time =
                          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    } catch (_) {}
                  }

                  final chipColor = _statusColor(status);

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(time, style: const TextStyle(fontSize: 11)),
                      ),
                      DataCell(
                        Text(name, style: const TextStyle(fontSize: 11)),
                      ),
                      DataCell(
                        Text(
                          format.toUpperCase(),
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
                            color: chipColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status[0].toUpperCase() + status.substring(1),
                            style: TextStyle(
                              color: chipColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            Icon(
                              url.isEmpty ? Icons.link_off : Icons.link,
                              size: 18,
                              color: url.isEmpty ? Colors.grey : Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: url.isEmpty
                                  ? null
                                  : () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: url),
                                      );
                                      _toast('URL copied');
                                    },
                              child: Text(
                                url.isEmpty ? '—' : 'Copy Link',
                                style: TextStyle(
                                  color: url.isEmpty
                                      ? Colors.black45
                                      : Colors.blue,
                                  fontSize: 11,
                                  decoration: url.isEmpty
                                      ? TextDecoration.none
                                      : TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _advanceStatus(r),
                              icon: const Icon(
                                Icons.playlist_add_check,
                                size: 18,
                              ),
                              tooltip: 'Advance status',
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

  // ------------ helpers ------------
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<Map<String, dynamic>?> _openDialog({
    Map<String, dynamic>? initial,
  }) async {
    final editing = initial != null;
    final nameCtrl = TextEditingController(
      text: initial?['export_name']?.toString() ?? '',
    );
    String format = (initial?['format']?.toString() ?? 'csv').toLowerCase();
    String status = (initial?['status']?.toString() ?? 'pending').toLowerCase();
    final urlCtrl = TextEditingController(
      text: initial?['file_url']?.toString() ?? '',
    );

    final key = GlobalKey<FormState>();

    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(editing ? 'Edit Export' : 'Create Export'),
        content: SizedBox(
          width: 460,
          child: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _tf(
                    controller: nameCtrl,
                    label: 'Export Name',
                    hint: 'e.g., Energy Usage CSV',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _dd(
                          label: 'Format',
                          value: format,
                          items: const ['csv', 'json', 'pdf'],
                          onChanged: (v) => format = v ?? 'csv',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _dd(
                          label: 'Status',
                          value: status,
                          items: const [
                            'pending',
                            'processing',
                            'completed',
                            'failed',
                          ],
                          onChanged: (v) => status = v ?? 'pending',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _tf(
                    controller: urlCtrl,
                    label: 'File URL (optional)',
                    hint: 'https://…',
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
                'export_name': nameCtrl.text.trim(),
                'format': format,
                'status': status,
                'file_url': urlCtrl.text.trim(),
              });
            },
            child: Text(editing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    urlCtrl.dispose();
    return res;
  }

  static Widget _tf({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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
            title: const Text('Delete export?'),
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
    if (!mounted) return;
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
