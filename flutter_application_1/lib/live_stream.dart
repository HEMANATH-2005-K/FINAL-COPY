import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../mqtt_service.dart';

class LiveStreamWithGraph extends StatefulWidget {
  @override
  _LiveStreamWithGraphState createState() => _LiveStreamWithGraphState();
}

class _LiveStreamWithGraphState extends State<LiveStreamWithGraph> {
  final MQTTService _mqtt = MQTTService();

  Timer? timer;

  int dataRate = 10;
  int previousRate = 10;

  double xTime = 0;
  int liveValue = 50;

  List<FlSpot> graph = [];

  // 🎯 Advanced Stats
  int peak = 0;
  int minVal = 200;
  double avg = 0;
  List<int> valueHistory = [];

  @override
  void initState() {
    super.initState();

    // Listen incoming MQTT data
    _mqtt.messageStream.listen((msg) {
      final int? v = int.tryParse(msg);
      if (v != null) updateLiveValue(v, fromMQTT: true);
    });
  }

  // 🎯 Special fluctuating data generator (CPU-style)
  int generateValue() {
    final r = Random();

    int change = r.nextInt(25) - 12;

    // Random spike: 5% chance
    if (r.nextInt(100) < 5) {
      change = r.nextInt(40) + 30; // big spike
    }

    liveValue += change;

    if (liveValue < 0) liveValue = 0;
    if (liveValue > 100) liveValue = 100;

    return liveValue;
  }

  void updateLiveValue(int value, {bool fromMQTT = false}) {
    setState(() {
      liveValue = value;
      xTime += 0.1;

      graph.add(FlSpot(xTime, value.toDouble()));

      if (graph.length > 100) graph.removeAt(0);

      // Update stats
      valueHistory.add(value);
      if (valueHistory.length > 200) valueHistory.removeAt(0);

      avg = valueHistory.reduce((a, b) => a + b) / valueHistory.length;
      if (value > peak) peak = value;
      if (value < minVal) minVal = value;
    });

    if (fromMQTT) {
      print("📩 MQTT → $value");
    } else {
      print("📈 LIVE → $value");
      print("📤 MQTT SENT → $value");
      _mqtt.publish("crane/operations", value.toString());
    }
  }

  void start() async {
    if (!_mqtt.isConnected) {
      await _mqtt.connect();
    }

    timer?.cancel();
    int intervalMs = (1000 ~/ dataRate);

    timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      updateLiveValue(generateValue());
    });

    detectFlowChange();
  }

  void detectFlowChange() {
    if (dataRate != previousRate) {
      previousRate = dataRate;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚡ Speed updated: $dataRate/sec"),
          duration: Duration(milliseconds: 600),
        ),
      );
    }
  }

  void stop() {
    timer?.cancel();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Color getLineColor() {
    if (liveValue > avg + 10) return Colors.red; // Spike
    if (liveValue < avg - 10) return Colors.orange; // Drop
    return Colors.blue; // Normal
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Advanced Live Stream"),
        backgroundColor: Colors.blue,
      ),

      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.bolt),
        backgroundColor: Colors.orange,
        onPressed: () => updateLiveValue(100), // manual spike
        tooltip: "Force Spike!",
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔥 MQTT Status Row
            Row(
              children: [
                Icon(
                  _mqtt.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _mqtt.isConnected ? Colors.green : Colors.red,
                ),
                SizedBox(width: 10),
                Text(
                  _mqtt.isConnected ? 'MQTT Connected' : 'MQTT Disconnected',
                  style: TextStyle(
                    color: _mqtt.isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            // 🔥 ADVANCED STATS PANEL
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statBox("Avg", avg.toStringAsFixed(1)),
                    _statBox("Peak", peak.toString()),
                    _statBox("Min", minVal.toString()),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // LIVE VALUE
            Text("📡 Live Value", style: TextStyle(fontSize: 18)),
            Text(
              "$liveValue",
              style: TextStyle(fontSize: 70, fontWeight: FontWeight.bold),
            ),

            // Speed slider
            Slider(
              min: 1,
              max: 100,
              divisions: 99,
              value: dataRate.toDouble(),
              label: "$dataRate/sec",
              onChanged: (v) {
                setState(() => dataRate = v.toInt());
                start();
              },
            ),

            SizedBox(height: 20),

            // GRAPH
            Expanded(
              child: LineChart(
                LineChartData(
                  minX: graph.isNotEmpty ? graph.first.x : 0,
                  maxX: graph.isNotEmpty ? graph.last.x : 5,
                  minY: 0,
                  maxY: 100,
                  backgroundColor: Colors.blue[50],
                  lineBarsData: [
                    LineChartBarData(
                      spots: graph,
                      isCurved: true,
                      color: getLineColor(),
                      barWidth: 3,
                    ),
                  ],
                ),
              ),
            ),

            // Start & stop
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: start, child: Text("START")),
                ElevatedButton(
                  onPressed: stop,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text("STOP"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
        SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
