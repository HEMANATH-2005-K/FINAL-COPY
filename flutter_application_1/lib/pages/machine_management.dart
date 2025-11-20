// lib/pages/machine_management.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../widgets/sidebar.dart';

class MachineManagementPage extends StatefulWidget {
  const MachineManagementPage({super.key});

  @override
  State<MachineManagementPage> createState() => _MachineManagementPageState();
}

class _MachineManagementPageState extends State<MachineManagementPage> {
  List<Map<String, dynamic>> machines = [];
  bool loading = true;
  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();
    loadMachines();
    subscribeRealtime();
  }

  @override
  void dispose() {
    SupabaseService.supabase.removeChannel(channel!);
    super.dispose();
  }

  void subscribeRealtime() {
    channel = Supabase.instance.client.channel('machines_channel');

    channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'machines',
      callback: (_) => loadMachines(),
    );
    channel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'machines',
      callback: (_) => loadMachines(),
    );
    channel!.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'machines',
      callback: (_) => loadMachines(),
    );

    channel!.subscribe();
  }

  Future loadMachines() async {
    loading = true;
    setState(() {});
    final data = await SupabaseService.getMachines();
    machines = data;
    loading = false;
    setState(() {});
  }

  // UI Header Styling
  static Widget _hdr(String title) => Text(
    title,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: Color(0xFF1E3A5F),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final activeCount = machines
        .where((e) => (e['status'] ?? '') == 'active')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          "Machines Management",
          style: TextStyle(color: Color(0xFF1E3A5F)),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1E3A5F)),
            onPressed: () => openMachineDialog(),
          ),
        ],
      ),
      drawer: Sidebar(onItemSelected: (title) {}),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildKpi(activeCount),
                    const SizedBox(height: 14),
                    _buildCharts(),
                    const SizedBox(height: 18),
                    _buildRealtimeTable(),
                  ],
                ),
              ),
            ),
    );
  }

  // KPI Display
  Widget _buildKpi(int activeCount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _box(),
      child: Row(
        children: [
          Expanded(
            child: _kpiCard(
              "Total Machines",
              machines.length.toString(),
              Icons.factory,
              Colors.blue,
            ),
          ),
          Expanded(
            child: _kpiCard(
              "Active",
              "$activeCount",
              Icons.check_circle,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _box(),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title),
            ],
          ),
        ],
      ),
    );
  }

  // Charts UI
  Widget _buildCharts() {
    final statusCount = <String, int>{};
    final modelCount = <String, int>{};

    for (var m in machines) {
      statusCount[m['status']] = (statusCount[m['status']] ?? 0) + 1;
      modelCount[m['model']] = (modelCount[m['model']] ?? 0) + 1;
    }

    return Row(
      children: [
        Expanded(child: _pieChart(statusCount)),
        Expanded(child: _barChart(modelCount)),
      ],
    );
  }

  Widget _pieChart(Map<String, int> data) {
    final sections = data.entries.map((e) {
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: "${e.key}\n${e.value}",
        radius: 50,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _box(),
      height: 180,
      child: PieChart(PieChartData(sections: sections)),
    );
  }

  Widget _barChart(Map<String, int> data) {
    final bars = data.entries.map((e) {
      return BarChartGroupData(
        x: data.keys.toList().indexOf(e.key),
        barRods: [BarChartRodData(toY: e.value.toDouble())],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _box(),
      height: 180,
      child: BarChart(BarChartData(barGroups: bars)),
    );
  }

  // Realtime Table Display
  Widget _buildRealtimeTable() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: _hdr("Machine ID")),
            DataColumn(label: _hdr("Name")),
            DataColumn(label: _hdr("Model")),
            DataColumn(label: _hdr("Location")),
            DataColumn(label: _hdr("Status")),
            DataColumn(label: _hdr("Installed")),
            DataColumn(label: _hdr("Last Service")),
            DataColumn(label: _hdr("Actions")),
          ],
          rows: machines.map((row) {
            return DataRow(
              cells: [
                DataCell(Text(row['machine_id'] ?? "")),
                DataCell(Text(row['name'] ?? "")),
                DataCell(Text(row['model'] ?? "")),
                DataCell(Text(row['location'] ?? "")),
                DataCell(_statusChip(row['status'])),
                DataCell(Text(row['installed_date'].toString())),
                DataCell(Text(row['last_service_date'].toString())),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => openMachineDialog(data: row),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () => deleteMachine(row),
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

  Widget _statusChip(String status) {
    Color c = Colors.grey;
    if (status == "active") c = Colors.green;
    if (status == "maintenance") c = Colors.orange;
    if (status == "offline") c = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future openMachineDialog({Map<String, dynamic>? data}) async {
    final TextEditingController idCtrl = TextEditingController(
      text: data?['machine_id'],
    );
    final TextEditingController nameCtrl = TextEditingController(
      text: data?['name'],
    );
    final TextEditingController modelCtrl = TextEditingController(
      text: data?['model'],
    );
    final TextEditingController locCtrl = TextEditingController(
      text: data?['location'],
    );

    String status = data?['status'] ?? "active";

    DateTime? installDate = data?['installed_date'] != null
        ? DateTime.parse(data!['installed_date'])
        : null;
    DateTime? serviceDate = data?['last_service_date'] != null
        ? DateTime.parse(data!['last_service_date'])
        : null;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data == null ? "Add Machine" : "Edit Machine"),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _input(idCtrl, "Machine ID"),
              const SizedBox(height: 8),
              _input(nameCtrl, "Name"),
              const SizedBox(height: 8),
              _input(modelCtrl, "Model"),
              const SizedBox(height: 8),
              _input(locCtrl, "Location"),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                value: status,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: "active", child: Text("Active")),
                  DropdownMenuItem(
                    value: "maintenance",
                    child: Text("Maintenance"),
                  ),
                  DropdownMenuItem(value: "offline", child: Text("Offline")),
                ],
                onChanged: (v) => status = v.toString(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (data == null) {
                await SupabaseService.supabase.from('machines').insert({
                  'machine_id': idCtrl.text.trim(),
                  'name': nameCtrl.text.trim(),
                  'model': modelCtrl.text.trim(),
                  'location': locCtrl.text.trim(),
                  'status': status,
                  'installed_date': installDate?.toIso8601String(),
                  'last_service_date': serviceDate?.toIso8601String(),
                });
              } else {
                await SupabaseService.supabase
                    .from('machines')
                    .update({
                      'machine_id': idCtrl.text.trim(),
                      'name': nameCtrl.text.trim(),
                      'model': modelCtrl.text.trim(),
                      'location': locCtrl.text.trim(),
                      'status': status,
                      'installed_date': installDate?.toIso8601String(),
                      'last_service_date': serviceDate?.toIso8601String(),
                    })
                    .eq("id", data['id']);
              }

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future deleteMachine(Map row) async {
    await SupabaseService.supabase
        .from('machines')
        .delete()
        .eq('id', row['id']);
    loadMachines();
  }

  // utility widgets
  InputDecoration _dec(String label) =>
      InputDecoration(labelText: label, border: OutlineInputBorder());

  Widget _input(TextEditingController ctrl, String label) =>
      TextFormField(controller: ctrl, decoration: _dec(label));

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
