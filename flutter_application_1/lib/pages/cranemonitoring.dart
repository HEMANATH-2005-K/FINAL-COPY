// pages/cranemonitoring.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../widgets/sidebar.dart';

class CraneMonitoringScreen extends StatefulWidget {
  const CraneMonitoringScreen({super.key});

  @override
  State<CraneMonitoringScreen> createState() => _CraneMonitoringScreenState();
}

class _CraneMonitoringScreenState extends State<CraneMonitoringScreen> {
  double bridgeX = 0.0;
  double trolleyZ = 0.0;
  double hookY = 5.0;

  double cameraAngleX = 30.0;
  double cameraAngleY = 45.0;
  double cameraZoom = 1.0;

  String operationState = 'bridgeForward';
  int operationPause = 0;
  Timer? operationTimer;

  final Map<String, dynamic> movementParams = {
    'bridge': {'speed': 0.05, 'min': -20.0, 'max': 20.0},
    'trolley': {'speed': 0.03, 'min': -8.0, 'max': 8.0},
    'hoist': {'speed': 0.02, 'min': 2.0, 'max': 8.0},
  };

  String currentZone = "Main Work Area";
  String nearestRestricted = "3.2m NW";

  @override
  void initState() {
    super.initState();
    startCraneSimulation();
  }

  @override
  void dispose() {
    operationTimer?.cancel();
    super.dispose();
  }

  void startCraneSimulation() {
    operationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        switch (operationState) {
          case 'bridgeForward':
            if (bridgeX < movementParams['bridge']['max']) {
              bridgeX += movementParams['bridge']['speed'];
            } else {
              operationState = 'trolleyRight';
            }
            break;
          case 'trolleyRight':
            if (trolleyZ < movementParams['trolley']['max']) {
              trolleyZ += movementParams['trolley']['speed'];
            } else {
              operationState = 'hoistDown';
            }
            break;
          case 'hoistDown':
            if (hookY > movementParams['hoist']['min']) {
              hookY -= movementParams['hoist']['speed'];
            } else {
              operationState = 'pauseAtBottom';
              operationPause = 30;
            }
            break;
          case 'pauseAtBottom':
            if (operationPause > 0) {
              operationPause--;
            } else {
              operationState = 'hoistUp';
            }
            break;
          case 'hoistUp':
            if (hookY < movementParams['hoist']['max']) {
              hookY += movementParams['hoist']['speed'];
            } else {
              operationState = 'trolleyLeft';
            }
            break;
          case 'trolleyLeft':
            if (trolleyZ > movementParams['trolley']['min']) {
              trolleyZ -= movementParams['trolley']['speed'];
            } else {
              operationState = 'bridgeReverse';
            }
            break;
          case 'bridgeReverse':
            if (bridgeX > movementParams['bridge']['min']) {
              bridgeX -= movementParams['bridge']['speed'];
            } else {
              operationState = 'pauseAtStart';
              operationPause = 60;
            }
            break;
          case 'pauseAtStart':
            if (operationPause > 0) {
              operationPause--;
            } else {
              operationState = 'bridgeForward';
            }
            break;
        }
      });
    });
  }

  void resetView() {
    setState(() {
      cameraAngleX = 30.0;
      cameraAngleY = 45.0;
      cameraZoom = 1.0;
    });
  }

  void topView() {
    setState(() {
      cameraAngleX = 0.0;
      cameraAngleY = 0.0;
    });
  }

  void sideView() {
    setState(() {
      cameraAngleX = 0.0;
      cameraAngleY = 90.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'CraneIQ - Zone Control',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
        ],
      ),
      drawer: const Sidebar(onItemSelected: null),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EOT Crane #CRN-001 - Zone Monitoring',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Real-time 3D visualization and control of restricted zones',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Status Cards
              if (isMobile)
                Column(
                  children: [
                    _buildStatusRow([
                      _buildStatusCard(
                        icon: Icons.check_circle,
                        label: 'Crane Status',
                        value: 'Operational',
                        color: Colors.green,
                      ),
                      _buildStatusCard(
                        icon: Icons.location_on,
                        label: 'Current Zone',
                        value: currentZone,
                        color: Colors.blue,
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _buildStatusRow([
                      _buildStatusCard(
                        icon: Icons.warning,
                        label: 'Nearest Restricted',
                        value: nearestRestricted,
                        color: Colors.orange,
                      ),
                      _buildStatusCard(
                        icon: Icons.fitness_center,
                        label: 'Current Load',
                        value: '2.5 / 5.0 tons',
                        color: Colors.purple,
                      ),
                    ]),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: _buildStatusCard(icon: Icons.check_circle, label: 'Crane Status', value: 'Operational', color: Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatusCard(icon: Icons.location_on, label: 'Current Zone', value: currentZone, color: Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatusCard(icon: Icons.warning, label: 'Nearest Restricted', value: nearestRestricted, color: Colors.orange)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatusCard(icon: Icons.fitness_center, label: 'Current Load', value: '2.5 / 5.0 tons', color: Colors.purple)),
                  ],
                ),

              const SizedBox(height: 20),

              // 3D Visualization
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SizedBox(
                  height: isMobile ? 350 : 500,
                  child: Stack(
                    children: [
                      GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            cameraAngleY += details.delta.dx * 0.5;
                            cameraAngleX -= details.delta.dy * 0.5;
                            cameraAngleX = cameraAngleX.clamp(-90.0, 90.0);
                          });
                        },
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: Crane3DPainter(
                            bridgeX,
                            trolleyZ,
                            hookY,
                            cameraAngleX,
                            cameraAngleY,
                            cameraZoom,
                          ),
                        ),
                      ),

                      // Control Buttons
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Column(
                          children: [
                            _buildControlButton(icon: Icons.home, onPressed: resetView, tooltip: 'Reset View'),
                            const SizedBox(height: 8),
                            _buildControlButton(
                              icon: Icons.zoom_in,
                              onPressed: () => setState(() => cameraZoom = (cameraZoom * 1.2).clamp(0.5, 3.0)),
                              tooltip: 'Zoom In',
                            ),
                            const SizedBox(height: 8),
                            _buildControlButton(
                              icon: Icons.zoom_out,
                              onPressed: () => setState(() => cameraZoom = (cameraZoom / 1.2).clamp(0.5, 3.0)),
                              tooltip: 'Zoom Out',
                            ),
                            const SizedBox(height: 8),
                            _buildControlButton(icon: Icons.map, onPressed: topView, tooltip: 'Top View'),
                            const SizedBox(height: 8),
                            _buildControlButton(icon: Icons.view_sidebar, onPressed: sideView, tooltip: 'Side View'),
                          ],
                        ),
                      ),

                      // Desktop Position Indicators
                      if (!isMobile)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Column(
                            children: [
                              _buildPositionIndicator('Bridge (LT)', '${bridgeX.toStringAsFixed(2)} m'),
                              const SizedBox(height: 8),
                              _buildPositionIndicator('Trolley (CT)', '${trolleyZ.toStringAsFixed(2)} m'),
                              const SizedBox(height: 8),
                              _buildPositionIndicator('Hoist', '${hookY.toStringAsFixed(2)} m'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Mobile Position Indicators
              if (isMobile) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildMobilePositionRow([
                          _buildMobilePosition('Bridge (X)', '${bridgeX.toStringAsFixed(2)} m', Icons.arrow_right_alt),
                          _buildMobilePosition('Trolley (Z)', '${trolleyZ.toStringAsFixed(2)} m', Icons.swap_horiz),
                        ]),
                        const SizedBox(height: 12),
                        _buildMobilePosition('Hook Height (Y)', '${hookY.toStringAsFixed(2)} m', Icons.height),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Real-time Position Tracking
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.track_changes, color: Colors.blue[700], size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Real-time Position Tracking',
                            style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.w600, color: Colors.blue[900]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isMobile)
                        Column(
                          children: [
                            _buildPositionValue('Bridge Position (X)', bridgeX.toStringAsFixed(2)),
                            const SizedBox(height: 12),
                            _buildPositionValue('Trolley Position (Z)', trolleyZ.toStringAsFixed(2)),
                            const SizedBox(height: 12),
                            _buildPositionValue('Hook Height (Y)', hookY.toStringAsFixed(2)),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(child: _buildPositionValue('Bridge Position (X)', bridgeX.toStringAsFixed(2))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildPositionValue('Trolley Position (Z)', trolleyZ.toStringAsFixed(2))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildPositionValue('Hook Height (Y)', hookY.toStringAsFixed(2))),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Active Zones
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.dashboard, color: Colors.orange[700], size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Active Zones',
                            style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.w600, color: Colors.blue[900]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildZoneListItem(id: 'ZN-001', name: 'Main Work Area', type: 'Work', position: '0,0,0', dimensions: '20×15×6m', color: Colors.green),
                      _buildZoneListItem(id: 'ZN-002', name: 'Personnel Area', type: 'Restricted', position: '25,5,0', dimensions: '8×8×6m', color: Colors.red),
                      _buildZoneListItem(id: 'ZN-003', name: 'Equipment Storage', type: 'Warning', position: '-15,5,0', dimensions: '10×10×6m', color: Colors.orange),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildStatusRow(List<Widget> children) {
    return Row(
      children: children.map((child) => Expanded(child: child)).expand((w) => [w, const SizedBox(width: 12)]).toList()..removeLast(),
    );
  }

  Widget _buildStatusCard({required IconData icon, required String label, required String value, required Color color}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 24, color: color)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed, required String tooltip}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]),
      child: IconButton(icon: Icon(icon, color: Colors.blue[700]), onPressed: onPressed, tooltip: tooltip),
    );
  }

  Widget _buildPositionIndicator(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Column(children: [Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 14, color: Colors.blue))]),
    );
  }

  Widget _buildMobilePositionRow(List<Widget> children) {
    return Row(children: children.map((c) => Expanded(child: c)).expand((w) => [w, const SizedBox(width: 12)]).toList()..removeLast());
  }

  Widget _buildMobilePosition(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
      child: Column(children: [
        Icon(icon, size: 20, color: Colors.blue[700]),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.blue), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildPositionValue(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
      child: Column(children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 8), Text('$value m', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue))]),
    );
  }

  Widget _buildZoneListItem({required String id, required String name, required String type, required String position, required String dimensions, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(children: [
        Expanded(flex: 1, child: Text(id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        Expanded(flex: 2, child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(type, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
        const SizedBox(width: 8),
        Expanded(child: Text(position, style: const TextStyle(fontSize: 11, color: Colors.grey))),
        Expanded(child: Text(dimensions, style: const TextStyle(fontSize: 11, color: Colors.grey))),
      ]),
    );
  }
}

// 3D Painter (Unchanged)
class Crane3DPainter extends CustomPainter {
  final double bridgeX, trolleyZ, hookY, cameraAngleX, cameraAngleY, cameraZoom;

  Crane3DPainter(this.bridgeX, this.trolleyZ, this.hookY, this.cameraAngleX, this.cameraAngleY, this.cameraZoom);

  Offset project3D(double x, double y, double z, Size size) {
    final angleX = cameraAngleX * math.pi / 180;
    final angleY = cameraAngleY * math.pi / 180;
    final x1 = x * math.cos(angleY) - z * math.sin(angleY);
    final z1 = x * math.sin(angleY) + z * math.cos(angleY);
    final y2 = y * math.cos(angleX) - z1 * math.sin(angleX);
    final z2 = y * math.sin(angleX) + z1 * math.cos(angleX);
    const distance = 50.0;
    final scale = distance / (distance + z2) * cameraZoom * 8;
    return Offset(size.width / 2 + x1 * scale, size.height / 2 - y2 * scale);
  }

  void drawBox(Canvas canvas, Paint paint, Size size, double x, double y, double z, double w, double h, double d) {
    final vertices = [
      project3D(x - w/2, y - h/2, z - d/2, size),
      project3D(x + w/2, y - h/2, z - d/2, size),
      project3D(x + w/2, y + h/2, z - d/2, size),
      project3D(x - w/2, y + h/2, z - d/2, size),
      project3D(x - w/2, y - h/2, z + d/2, size),
      project3D(x + w/2, y - h/2, z + d/2, size),
      project3D(x + w/2, y + h/2, z + d/2, size),
      project3D(x - w/2, y + h/2, z + d/2, size),
    ];

    final path = Path()..moveTo(vertices[0].dx, vertices[0].dy)
      ..lineTo(vertices[1].dx, vertices[1].dy)
      ..lineTo(vertices[2].dx, vertices[2].dy)
      ..lineTo(vertices[3].dx, vertices[3].dy)
      ..close();
    canvas.drawPath(path, paint);

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      canvas.drawLine(vertices[i], vertices[(i + 1) % 4], paint);
      canvas.drawLine(vertices[i], vertices[i + 4], paint);
      canvas.drawLine(vertices[i + 4], vertices[(i + 1) % 4 + 4], paint);
    }

    paint.style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Background
    paint.color = const Color(0xFFF0F0F0);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Grid
    paint.color = Colors.grey[400]!;
    paint.strokeWidth = 0.5;
    paint.style = PaintingStyle.stroke;
    for (int i = -20; i <= 20; i += 2) {
      final start1 = project3D(i.toDouble(), 0, -20, size);
      final end1 = project3D(i.toDouble(), 0, 20, size);
      canvas.drawLine(start1, end1, paint);
      final start2 = project3D(-20, 0, i.toDouble(), size);
      final end2 = project3D(20, 0, i.toDouble(), size);
      canvas.drawLine(start2, end2, paint);
    }

    paint.style = PaintingStyle.fill;

    // Zones
    paint.color = Colors.green.withAlpha(51);
    drawBox(canvas, paint, size, 0, 3, 0, 20, 6, 15);
    paint.color = Colors.red.withAlpha(51);
    drawBox(canvas, paint, size, 25, 3, 5, 8, 6, 8);
    paint.color = Colors.orange.withAlpha(51);
    drawBox(canvas, paint, size, -15, 3, 5, 10, 6, 10);

    // Rails
    paint.color = Colors.grey[700]!;
    drawBox(canvas, paint, size, 0, 10, -8, 50, 0.5, 0.5);
    drawBox(canvas, paint, size, 0, 10, 8, 50, 0.5, 0.5);

    // Bridge
    paint.color = Colors.blue;
    drawBox(canvas, paint, size, bridgeX, 10, 0, 1, 0.5, 16);

    // Trolley
    paint.color = Colors.blue[700]!;
    drawBox(canvas, paint, size, bridgeX, 9, trolleyZ, 1.5, 0.8, 1.5);

    // Hoist Line
    paint.color = Colors.black;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    final trolleyPos = project3D(bridgeX, 9, trolleyZ, size);
    final hookPos = project3D(bridgeX, hookY, trolleyZ, size);
    canvas.drawLine(trolleyPos, hookPos, paint);

    // Hook
    paint.color = Colors.red;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(hookPos, 8, paint);

    // Axes
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    final origin = project3D(0, 0, 0, size);
    paint.color = Colors.red;
    canvas.drawLine(origin, project3D(10, 0, 0, size), paint);
    paint.color = Colors.green;
    canvas.drawLine(origin, project3D(0, 10, 0, size), paint);
    paint.color = Colors.blue;
    canvas.drawLine(origin, project3D(0, 0, 10, size), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}