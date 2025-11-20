import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:http/http.dart' as http;

void main() async {
  final client = MqttServerClient('YOUR DEVICE IP', 'db_to_mqtt_publisher');

  client.port = 1883;
  client.keepAlivePeriod = 30;
  client.logging(on: true);
  client.setProtocolV311();

  print("🚀 Connecting to MQTT...");

  try {
    await client.connect();
    print("🔥 Connected to MQTT broker!");
  } catch (e) {
    print("❌ MQTT Connection failed: $e");
    return;
  }

  const supabaseServiceKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxmeXN0eWFjeGVqZXpkc3Zwa2hnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MzM5NzAsImV4cCI6MjA3NzMwOTk3MH0.PrFlVBg9vQoK1X1aFbuaOmNHavCFsvzy2g76_oSo7Tc";

  while (true) {
    try {
      final response = await http.get(
        Uri.parse(
          "https://lfystyacxejezdsvpkhg.supabase.co/rest/v1/operations_log" // ← CHANGED TABLE
          "?select=crane_id,operation_type,description,operator,timestamp&order=timestamp.desc", // ← CHANGED COLUMNS
        ),
        headers: {
          "apikey": supabaseServiceKey,
          "Authorization": "Bearer $supabaseServiceKey",
        },
      );

      if (response.statusCode != 200) {
        print("Supabase fetch failed: ${response.statusCode} ${response.body}");
        await Future.delayed(Duration(seconds: 1));
        continue;
      }

      final jsonData = jsonDecode(response.body);

      print(
        "📊 Found ${jsonData.length} operation records from operations_log",
      );

      // PROCESS ALL OPERATIONS
      for (var i = 0; i < jsonData.length; i++) {
        final String craneId = jsonData[i]["crane_id"];
        final String operationType =
            jsonData[i]["operation_type"]; // ← USING operation_type
        final String description = jsonData[i]["description"];
        final String operator = jsonData[i]["operator"];
        final String timestamp = jsonData[i]["timestamp"];

        // DEBUG: Show each operation's data
        print(
          "🏗️ Crane: $craneId, Operation: $operationType, Desc: $description",
        );

        // 🆕 Convert operation_type to HOIST UP/DOWN logic if needed
        // If operation_type already has "HOIST UP" or "HOIST DOWN", use it directly
        // Otherwise, you might need to map it based on description
        final String operation = operationType.contains("UP")
            ? "HOIST UP"
            : operationType.contains("DOWN")
            ? "HOIST DOWN"
            : operationType; // Use as-is if already correct

        final msg = jsonEncode({
          "operation": operation,
          "crane_id": craneId,
          "description": description,
          "operator": operator,
          "timestamp": timestamp,
        });

        final builder = MqttClientPayloadBuilder();
        builder.addString(msg);

        client.publishMessage(
          "crane/operations",
          MqttQos.atLeastOnce,
          builder.payload!,
        );

        print("📡 Sent → $msg");

        // Small delay between publishing each operation
        await Future.delayed(Duration(milliseconds: 200));
      }

      print("✅ Published ${jsonData.length} operations");
      print("⏰ Waiting 3 seconds before next update...");
    } catch (e) {
      print("ERROR: $e");
    }

    await Future.delayed(Duration(seconds: 3));
  }
}
