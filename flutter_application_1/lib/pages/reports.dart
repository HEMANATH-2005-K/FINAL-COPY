// pages/reports.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/sidebar.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _sb = Supabase.instance.client;

  // filters
  String selectedType = 'All';
  String selectedAuthor = 'All';

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
          .from('reports')
          .select()
          .order('created_at', ascending: false);
      setState(() => rows = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      _toast('Failed to load reports', error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _subscribeRt() {
    _chan = _sb.channel('reports_rt')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'reports',
        callback: (_) => _load(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'reports',
        callback: (_) => _load(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'reports',
        callback: (_) => _load(),
      )
      ..subscribe();
  }

  // ---------- CRUD ----------
  Future<void> _create() async {
    final form = await _openDialog();
    if (form == null) return;
    try {
      await _sb.from('reports').insert(form);
      _toast('Report added');
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
      await _sb.from('reports').update(form).eq('id', id);
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
      await _sb.from('reports').delete().eq('id', id);
      _toast('Deleted');
      await _load();
    } catch (e) {
      _toast('Delete failed', error: true);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    // unique dropdown options
    final types = <String>{'All'};
    final authors = <String>{'All'};
    for (final r in rows) {
      final t = r['report_type']?.toString();
      if (t != null && t.isNotEmpty) types.add(t);
      final a = r['generated_by']?.toString();
      if (a != null && a.isNotEmpty) authors.add(a);
    }

    // apply filters
    final filtered = rows.where((r) {
      final tOk =
          selectedType == 'All' ||
          (r['report_type']?.toString() == selectedType);
      final aOk =
          selectedAuthor == 'All' ||
          (r['generated_by']?.toString() == selectedAuthor);
      return tOk && aOk;
    }).toList();

    // KPIs
    final total = filtered.length;
    final lastType = total > 0
        ? (filtered.first['report_type']?.toString() ?? '-')
        : '-';
    final lastBy = total > 0
        ? (filtered.first['generated_by']?.toString() ?? '-')
        : '-';
    final withLinks = filtered
        .where((r) => (r['download_url'] ?? '').toString().isNotEmpty)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          'Reports',
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
            tooltip: 'Add Report',
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
              types: types.toList(),
              authors: authors.toList(),
              onType: (v) => setState(() => selectedType = v ?? 'All'),
              onAuthor: (v) => setState(() => selectedAuthor = v ?? 'All'),
            ),
            const SizedBox(height: 12),
            _kpis(total, lastType, lastBy, withLinks),
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
        label: const Text('Add Report'),
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
            Icons.description,
            color: Color(0xFF1E3A5F),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Generated reports and exports',
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
    required List<String> types,
    required List<String> authors,
    required ValueChanged<String?> onType,
    required ValueChanged<String?> onAuthor,
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
              label: 'Type',
              value: selectedType,
              items: types,
              onChanged: onType,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _labeledDropdown(
              label: 'Generated By',
              value: selectedAuthor,
              items: authors,
              onChanged: onAuthor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpis(int total, String lastType, String lastBy, int withLinks) {
    final cards = [
      {'label': 'Total Reports', 'value': '$total', 'color': Colors.blue},
      {'label': 'Latest Type', 'value': lastType, 'color': Colors.purple},
      {'label': 'Latest Author', 'value': lastBy, 'color': Colors.teal},
      {'label': 'With Links', 'value': '$withLinks', 'color': Colors.green},
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
                'Reports (Realtime)',
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
                  DataColumn(label: _hdr('Report Name')),
                  DataColumn(label: _hdr('Type')),
                  DataColumn(label: _hdr('Generated By')),
                  DataColumn(label: _hdr('Date Range')),
                  DataColumn(label: _hdr('Download')),
                  DataColumn(label: _hdr('Actions')),
                ],
                rows: data.take(100).map((r) {
                  final name = r['report_name']?.toString() ?? '-';
                  final type = r['report_type']?.toString() ?? '-';
                  final by = r['generated_by']?.toString() ?? '-';
                  final url = r['download_url']?.toString() ?? '';
                  final range = _formatRange(r['data_range']);
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

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(time, style: const TextStyle(fontSize: 11)),
                      ),
                      DataCell(
                        Text(name, style: const TextStyle(fontSize: 11)),
                      ),
                      DataCell(
                        Text(type, style: const TextStyle(fontSize: 11)),
                      ),
                      DataCell(Text(by, style: const TextStyle(fontSize: 11))),
                      DataCell(
                        Text(range, style: const TextStyle(fontSize: 11)),
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
                                      _toast('Download URL copied');
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

  String _formatRange(dynamic jsonRange) {
    // expects JSONB like {"from":"YYYY-MM-DD","to":"YYYY-MM-DD"}
    try {
      if (jsonRange is Map) {
        final from = jsonRange['from']?.toString() ?? '';
        final to = jsonRange['to']?.toString() ?? '';
        if (from.isEmpty && to.isEmpty) return '—';
        if (from.isEmpty) return '… → $to';
        if (to.isEmpty) return '$from → …';
        return '$from → $to';
      }
      if (jsonRange is String && jsonRange.trim().isNotEmpty) {
        final m = json.decode(jsonRange);
        return _formatRange(m);
      }
    } catch (_) {}
    return '—';
  }

  Future<Map<String, dynamic>?> _openDialog({
    Map<String, dynamic>? initial,
  }) async {
    final editing = initial != null;

    final nameCtrl = TextEditingController(
      text: initial?['report_name']?.toString() ?? '',
    );
    final typeCtrl = TextEditingController(
      text: initial?['report_type']?.toString() ?? '',
    );
    final byCtrl = TextEditingController(
      text: initial?['generated_by']?.toString() ?? '',
    );
    final urlCtrl = TextEditingController(
      text: initial?['download_url']?.toString() ?? '',
    );

    DateTime? from;
    DateTime? to;
    // prefill date_range if any
    final dr = initial?['data_range'];
    if (dr != null) {
      try {
        final m = (dr is String)
            ? json.decode(dr)
            : Map<String, dynamic>.from(dr);
        final fs = (m['from']?.toString() ?? '').trim();
        final ts = (m['to']?.toString() ?? '').trim();
        if (fs.isNotEmpty) from = DateTime.tryParse(fs);
        if (ts.isNotEmpty) to = DateTime.tryParse(ts);
      } catch (_) {}
    }

    final key = GlobalKey<FormState>();

    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Future<void> pickFrom() async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate: from ?? now,
              firstDate: DateTime(now.year - 5),
              lastDate: DateTime(now.year + 5),
            );
            if (picked != null) setLocal(() => from = picked);
          }

          Future<void> pickTo() async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate: to ?? from ?? now,
              firstDate: DateTime(now.year - 5),
              lastDate: DateTime(now.year + 5),
            );
            if (picked != null) setLocal(() => to = picked);
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(editing ? 'Edit Report' : 'Add Report'),
            content: SizedBox(
              width: 480,
              child: Form(
                key: key,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _tf(
                        controller: nameCtrl,
                        label: 'Report Name',
                        hint: 'e.g., Weekly Load Summary',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _tf(
                              controller: typeCtrl,
                              label: 'Report Type',
                              hint: 'e.g., pdf / csv / json',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _tf(
                              controller: byCtrl,
                              label: 'Generated By',
                              hint: 'e.g., admin@craneiq.com',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _dateBox(
                              label: 'From',
                              date: from,
                              onTap: pickFrom,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _dateBox(
                              label: 'To',
                              date: to,
                              onTap: pickTo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _tf(
                        controller: urlCtrl,
                        label: 'Download URL (optional)',
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
                  final map = <String, dynamic>{
                    'report_name': nameCtrl.text.trim(),
                    'report_type': typeCtrl.text.trim(),
                    'generated_by': byCtrl.text.trim(),
                    'download_url': urlCtrl.text.trim(),
                    'data_range': {
                      'from': from != null
                          ? '${from!.year}-${from!.month.toString().padLeft(2, '0')}-${from!.day.toString().padLeft(2, '0')}'
                          : null,
                      'to': to != null
                          ? '${to!.year}-${to!.month.toString().padLeft(2, '0')}-${to!.day.toString().padLeft(2, '0')}'
                          : null,
                    },
                  };
                  Navigator.pop<Map<String, dynamic>>(ctx, map);
                },
                child: Text(editing ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );

    nameCtrl.dispose();
    typeCtrl.dispose();
    byCtrl.dispose();
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

  Widget _dateBox({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final text = date == null
        ? 'Select'
        : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
        ),
        child: Row(
          children: [
            const Icon(Icons.event, size: 16, color: Colors.black54),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete report?'),
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
