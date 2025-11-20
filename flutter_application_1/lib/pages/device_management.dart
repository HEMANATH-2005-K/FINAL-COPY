import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Device> _devices = []; // Empty list for "No devices found" state

  void _showCreateDeviceType() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateDeviceTypeModal(),
    );
  }

  void _showAddDevice() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddDeviceModal(),
    );
  }

  void _showAddSection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSectionModal(),
    );
  }

  void _showAddField() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddFieldModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const Sidebar(),
      appBar: AppBar(
        title: const Text('CraneIQ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.black87),
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
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header Section
                _buildHeaderSection(),
                const SizedBox(height: 24),
                
                // Action Buttons
                _buildActionButtons(),
                const SizedBox(height: 24),
                
                // Devices List or Empty State
                _devices.isEmpty ? _buildEmptyState() : _buildDevicesList(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Device Management',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage all sensor devices connected to IoT Gateways',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildActionButton(
          icon: Icons.add,
          label: 'Create Device Type',
          color: Colors.blue,
          onTap: _showCreateDeviceType,
        ),
        _buildActionButton(
          icon: Icons.add,
          label: 'Add Device',
          color: Colors.blue,
          onTap: _showAddDevice,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(40),
        width: double.infinity,
        child: Column(
          children: [
            Icon(
              Icons.sensors_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Devices Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a device to get started',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showAddDevice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Add Your First Device'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Devices',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._devices.asMap().entries.map((entry) {
          final index = entry.key;
          final device = entry.value;
          return _buildDeviceCard(device, index + 1);
        }),
      ],
    );
  }

  Widget _buildDeviceCard(Device device, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with index and type
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#$index',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    device.type,
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Device details
            _buildDetailRow('Device Name', device.name),
            _buildDetailRow('Device ID', device.deviceId),
            _buildDetailRow('Gateway', device.gateway),
            _buildDetailRow('Polling Interval', device.pollingInterval),
            const SizedBox(height: 16),
            
            // Action buttons
            _buildActionButtonsRow(device),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsRow(Device device) {
    return Row(
      children: [
        Expanded(
          child: _buildSmallButton(
            label: 'Edit',
            color: Colors.orange,
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSmallButton(
            label: 'Command',
            color: Colors.purple,
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSmallButton(
            label: 'Delete',
            color: Colors.red,
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSmallButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

// Modal for Add Device
class AddDeviceModal extends StatefulWidget {
  const AddDeviceModal({super.key});

  @override
  State<AddDeviceModal> createState() => _AddDeviceModalState();
}

class _AddDeviceModalState extends State<AddDeviceModal> {
  String? _selectedDeviceType;
  final _selectedSections = <String>{};
  final _selectedFields = <String>{};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Device Configuration',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure device settings and data points',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          
          // Device Type
          DropdownButtonFormField<String>(
            initialValue: _selectedDeviceType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Device Type *',
            ),
            items: ['Sensor', 'Controller', 'Gateway', 'Actuator']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedDeviceType = value;
              });
            },
          ),
          const SizedBox(height: 20),
          
          // Sections
          _buildSectionTitle('Sections'),
          _buildCheckboxItem('Select All Sections', _selectedSections.contains('all'), (value) {
            setState(() {
              if (value == true) {
                _selectedSections.add('all');
              } else {
                _selectedSections.remove('all');
              }
            });
          }),
          const SizedBox(height: 16),
          
          // Fields
          _buildSectionTitle('Fields'),
          _buildCheckboxItem('Select All Fields', _selectedFields.contains('all'), (value) {
            setState(() {
              if (value == true) {
                _selectedFields.add('all');
              } else {
                _selectedFields.remove('all');
              }
            });
          }),
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Device'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildCheckboxItem(String label, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

// Modal for Create Device Type
class CreateDeviceTypeModal extends StatefulWidget {
  const CreateDeviceTypeModal({super.key});

  @override
  State<CreateDeviceTypeModal> createState() => _CreateDeviceTypeModalState();
}

class _CreateDeviceTypeModalState extends State<CreateDeviceTypeModal> {
  final _deviceTypeNameController = TextEditingController();
  final _deviceNameController = TextEditingController();
  final _deviceIdController = TextEditingController();
  final _gatewayController = TextEditingController();
  final _pollIntervalController = TextEditingController();

  void _showAddSection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSectionModal(),
    );
  }

  void _showAddField() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddFieldModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Create New Device Type',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Define a new device type and its properties',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          
          // Device Type Identification
          _buildSectionTitle('Device Type Identification'),
          TextField(
            controller: _deviceTypeNameController,
            decoration: const InputDecoration(
              hintText: 'e.g., Sensor, Controller, Gateway',
              border: OutlineInputBorder(),
              labelText: 'Device Type Name *',
            ),
          ),
          const SizedBox(height: 20),
          
          // Add Section Button
          _buildAddButton('Add Section', _showAddSection),
          const SizedBox(height: 20),
          
          // Basic Details Section
          _buildSectionTitle('Basic Details'),
          const SizedBox(height: 12),
          
          // Device Name and Device ID Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _deviceNameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter device name',
                    border: OutlineInputBorder(),
                    labelText: 'Device Name',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _deviceIdController,
                  decoration: const InputDecoration(
                    hintText: 'Enter device ID',
                    border: OutlineInputBorder(),
                    labelText: 'Device ID',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // IoT Gateway and Poll Interval Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _gatewayController,
                  decoration: const InputDecoration(
                    hintText: 'Enter IoT gateway',
                    border: OutlineInputBorder(),
                    labelText: 'IoT Gateway',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _pollIntervalController,
                  decoration: const InputDecoration(
                    hintText: 'Enter poll interval',
                    border: OutlineInputBorder(),
                    labelText: 'Poll Interval (ms)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Data Point Details
          _buildSectionTitle('Data Point Details'),
          const SizedBox(height: 8),
          Text(
            'Configure data points for this device type',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          
          // Add Field Button
          _buildAddButton('Add Field', _showAddField),
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Device Type'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('View Existing Types'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Modal for Add Section
class AddSectionModal extends StatefulWidget {
  const AddSectionModal({super.key});

  @override
  State<AddSectionModal> createState() => _AddSectionModalState();
}

class _AddSectionModalState extends State<AddSectionModal> {
  final _sectionNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Add New Section',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Section Name
          TextField(
            controller: _sectionNameController,
            decoration: const InputDecoration(
              hintText: 'Enter section name',
              border: OutlineInputBorder(),
              labelText: 'Section Name *',
            ),
          ),
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add Section'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Modal for Add Field
class AddFieldModal extends StatefulWidget {
  const AddFieldModal({super.key});

  @override
  State<AddFieldModal> createState() => _AddFieldModalState();
}

class _AddFieldModalState extends State<AddFieldModal> {
  final _fieldNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedDataType;
  String? _selectedFeedType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Add New Field',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A. Basic Information',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          
          // Field Name
          TextField(
            controller: _fieldNameController,
            decoration: const InputDecoration(
              hintText: 'Enter field name',
              border: OutlineInputBorder(),
              labelText: 'Field Name *',
            ),
          ),
          const SizedBox(height: 16),
          
          // Description
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter field description',
              border: OutlineInputBorder(),
              labelText: 'Description',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          
          // Data Configuration
          _buildSectionTitle('Data Configuration'),
          DropdownButtonFormField<String>(
            initialValue: _selectedDataType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Data Type *',
            ),
            items: ['Text', 'Number', 'Boolean', 'Date', 'JSON']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedDataType = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Data Feed Configuration
          _buildSectionTitle('Data Feed Configuration'),
          DropdownButtonFormField<String>(
            initialValue: _selectedFeedType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Feed Type *',
            ),
            items: ['Manual Input', 'Sensor Reading', 'API Call', 'Scheduled']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedFeedType = value;
              });
            },
          ),
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add Field'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}

// Data Models
class Device {
  final String name;
  final String deviceId;
  final String gateway;
  final String type;
  final String pollingInterval;

  Device({
    required this.name,
    required this.deviceId,
    required this.gateway,
    required this.type,
    required this.pollingInterval,
  });
}