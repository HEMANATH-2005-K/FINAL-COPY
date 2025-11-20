import 'package:flutter/material.dart';
import 'mqtt_service.dart';

class MQTTDemoPage extends StatefulWidget {
  @override
  _MQTTDemoPageState createState() => _MQTTDemoPageState();
}

class _MQTTDemoPageState extends State<MQTTDemoPage> {
  final MQTTService _mqttService = MQTTService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _topicController = TextEditingController(
    text: 'crane/operations',
  );
  final List<String> _messages = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    print('✅ MQTT PAGE LOADED'); // Debug line

    // ✅ KEEP message listener
    _mqttService.messageStream.listen((message) {
      if (mounted) {
        setState(() {
          _messages.add('📨 FROM SERVER: $message');
        });
      }
    });

    // ❌ REMOVE or COMMENT OUT auto-connect:
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _connect();
    // });
  }

  Future<void> _connect() async {
    print('🔄 CONNECT BUTTON CLICKED - STARTING CONNECTION...');

    setState(() {
      _messages.add('🔄 Connecting to MQTT Broker...');
    });

    // ADD A SMALL DELAY TO SEE THE "CONNECTING" MESSAGE
    await Future.delayed(Duration(milliseconds: 100));

    final connected = await _mqttService.connect();

    print('📊 CONNECTION RESULT: $connected');

    // FORCE UI UPDATE
    setState(() {
      _isConnected = connected;
      if (connected) {
        _messages.add('✅ CONNECTED to Mosquito Broker!');
        _mqttService.publish(
          _topicController.text,
          "Flutter client subscribed ✅",
        );
        _messages.add('📡 Subscribed to: ${_topicController.text}');

        // TEST: SEND A WELCOME MESSAGE
        _mqttService.publish(_topicController.text, 'Flutter app connected!');
        _messages.add('📤 Welcome message sent');
      } else {
        _messages.add('❌ FAILED to connect - check console for error');
      }
    });
  }

  void _publishMessage() {
    if (_messageController.text.isNotEmpty) {
      _mqttService.publish(_topicController.text, _messageController.text);
      setState(() {
        _messages.add('📤 YOU SENT: ${_messageController.text}');
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MQTT Demo - ${_isConnected ? 'CONNECTED' : 'DISCONNECTED'}',
        ),
        backgroundColor: _isConnected ? Colors.green : Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Connection Status
            Card(
              color: _isConnected ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.wifi : Icons.wifi_off,
                          color: _isConnected ? Colors.green : Colors.red,
                          size: 30,
                        ),
                        SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isConnected ? 'CONNECTED' : 'DISCONNECTED',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: _isConnected ? Colors.green : Colors.red,
                              ),
                            ),
                            if (_isConnected) ...[
                              Text(
                                '🔓 Connected to Public Mosquitto Broker',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'Server: test.mosquitto.org:8084',
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ],
                        ),
                        Spacer(),
                        ElevatedButton(
                          onPressed: _isConnected ? null : _connect,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isConnected
                                ? Colors.grey
                                : Colors.blue,
                          ),
                          child: Text(
                            _isConnected ? 'Connected' : 'Connect Now',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Topic & Message Input
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: 'Topic',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Type your message',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                    ),
                    onSubmitted: (_) => _publishMessage(),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _publishMessage,
                  icon: Icon(Icons.send),
                  label: Text('Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Messages List
            Expanded(
              child: Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.chat, color: Colors.blue),
                          SizedBox(width: 10),
                          Text(
                            'Live Messages:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Spacer(),
                          Chip(
                            label: Text('${_messages.length} messages'),
                            backgroundColor: Colors.blue[100],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 10),
                                  Text('No messages yet'),
                                  Text(
                                    'Connect and send a message!',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final isIncoming = message.contains(
                                  'FROM SERVER',
                                );
                                final isSystem =
                                    message.contains('CONNECT') ||
                                    message.contains('Subscribed') ||
                                    message.contains('FAILED') ||
                                    message.contains('AUTHENTICATED');

                                Color bgColor = isSystem
                                    ? Colors.blue[50]!
                                    : isIncoming
                                    ? Colors.green[50]!
                                    : Colors.blue[50]!;

                                return Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSystem
                                            ? Icons.info
                                            : isIncoming
                                            ? Icons.download
                                            : Icons.upload,
                                        color: isSystem
                                            ? Colors.blue
                                            : isIncoming
                                            ? Colors.green
                                            : Colors.blue,
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(child: Text(message)),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _topicController.dispose();
    super.dispose();
  }
}
