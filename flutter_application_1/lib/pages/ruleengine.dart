import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';

class RulesEnginePage extends StatefulWidget {
  const RulesEnginePage({super.key});

  @override
  RulesEnginePageState createState() => RulesEnginePageState();
}

class RulesEnginePageState extends State<RulesEnginePage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;

  final List<String> _machines = ['Select machine', 'CRN-001', 'CRN-002', 'CRN-003', 'All Cranes'];
  final List<String> _dataPoints = ['Select data point', 'Temperature', 'Operation Time', 'Load Weight', 'Idle Status'];
  final List<String> _operators = ['Greater Than', 'Less Than', 'Equal To'];
  final List<String> _units = ['N/A', '°C', 'hours', 'kg'];
  final List<String> _actions = ['Select action', 'Send Alert', 'Log Event', 'Shutdown Crane'];
  final List<String> _machineTypes = ['All Machines', 'Tower Crane', 'Mobile Crane', 'Overhead Crane'];
  String? _selectedMachineType = 'All Machines';

  final List<ActiveRule> _activeRules = [
    ActiveRule(
      title: 'Extended Operation Alert',
      description: 'Triggers when a crane operates continuously for more than 2 hours without a break.',
      machines: 'All Cranes',
      condition: 'Operation time > 2 hours',
      activeSince: '2023-05-10',
    ),
    ActiveRule(
      title: 'Weekend Operation Alert',
      description: 'Notifies when any crane operates on weekends.',
      machines: 'All Cranes',
      condition: 'Operation on weekend',
      activeSince: '2023-04-15',
    ),
    ActiveRule(
      title: 'High Ambient Temperature Alert',
      description: 'Triggers when ambient temperature exceeds 35°C and crane is operating.',
      machines: 'CRN-001, CRN-002',
      condition: 'Temperature > 35°C',
      activeSince: '2023-06-01',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const Sidebar(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('CraneIQ Rules Engine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/dashboard', 
                (route) => false
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Machine Rule Engine',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create and manage automation rules for your cranes',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Create New Rule', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6EFD),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildCreateRuleForm(),
            const SizedBox(height: 32),
            _buildActiveRulesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorValueUnitFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 340) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormTitle('Operator'),
                    _buildDropdown(_operators, initialValue: 'Greater Than'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormTitle('Value'),
                    TextFormField(decoration: const InputDecoration(hintText: 'Value')),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormTitle('Unit'),
                    _buildDropdown(_units),
                  ],
                ),
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormTitle('Operator'),
              _buildDropdown(_operators, initialValue: 'Greater Than'),
              const SizedBox(height: 16),
              _buildFormTitle('Value'),
              TextFormField(decoration: const InputDecoration(hintText: 'Value')),
              const SizedBox(height: 16),
              _buildFormTitle('Unit'),
              _buildDropdown(_units),
            ],
          );
        }
      },
    );
  }

  Widget _buildCreateRuleForm() {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'Conditional Rule'),
              Tab(text: 'Scheduled Rule'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormTitle('Rule Name'),
                TextFormField(
                  decoration: const InputDecoration(hintText: 'Enter rule name'),
                ),
                const SizedBox(height: 16),
                _buildFormTitle('Machine'),
                _buildDropdown(_machines),
                const SizedBox(height: 16),
                _buildFormTitle('Data Point'),
                _buildDropdown(_dataPoints),
                const SizedBox(height: 16),
                _buildOperatorValueUnitFields(),
                const SizedBox(height: 16),
                _buildFormTitle('Action'),
                _buildDropdown(_actions),
                const SizedBox(height: 16),
                _buildFormTitle('Description'),
                TextFormField(
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Rule description'),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      child: const Text('Create Rule', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildDropdown(List<String> items, {String? initialValue}) {
    String? currentValue = initialValue ?? items.first;
    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          currentValue = newValue;
        });
      },
    );
  }

  Widget _buildActiveRulesSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0D6EFD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 16,
            children: [
              const Text(
                'Active Rules',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedMachineType,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _machineTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedMachineType = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: _activeRules.map((rule) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ActiveRuleCard(rule: rule),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ActiveRule {
  final String title;
  final String description;
  final String machines;
  final String condition;
  final String activeSince;

  const ActiveRule({
    required this.title,
    required this.description,
    required this.machines,
    required this.condition,
    required this.activeSince,
  });
}

class ActiveRuleCard extends StatelessWidget {
  final ActiveRule rule;

  const ActiveRuleCard({super.key, required this.rule});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    rule.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const Chip(
                  label: Text('active'),
                  backgroundColor: Color(0xFFD1FAE5),
                  labelStyle: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold),
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              rule.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildInfoRow('Machines:', rule.machines),
            _buildInfoRow('Condition:', rule.condition),
            _buildInfoRow('Active since:', rule.activeSince),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}