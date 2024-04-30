import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:http/http.dart' as http;

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  bool isListening = false;
  BluetoothConnection? connection;
  List<BluetoothDevice> devices = [];
  bool isScanning = false;
  String gloveText = 'Welcome';

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    try {
      await FlutterBluetoothSerial.instance.requestEnable();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _scanDevices() async {
    setState(() {
      isScanning = true;
      devices.clear();
    });

    try {
      final Stream<BluetoothDiscoveryResult> results =
          FlutterBluetoothSerial.instance.startDiscovery();

      results.listen((BluetoothDiscoveryResult result) {
        setState(() {
          devices.add(result.device);
        });
      }).onDone(() {
        setState(() {
          isScanning = false;
        });
      });
    } catch (e) {
      print(e.toString());
      setState(() {
        isScanning = false;
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      connection = await BluetoothConnection.toAddress(device.address);

      // Set up listeners for incoming data or connection events
      _setUpConnectionListeners(); // Call _setUpConnectionListeners here

      print('Connected to ${device.name}');
    } catch (e) {
      print('Failed to connect: $e');
    }
  }

  void _setUpConnectionListeners() {
    if (!isListening) {
      connection!.input!.listen((Uint8List data) {
        // Handle incoming data
        String receivedString = String.fromCharCodes(data);
        print('Received data = $receivedString');

        // Send data to API
        _sendDataToApi(receivedString);
      }, onDone: () {
        // Handle connection closed event
        print('Connection closed');
      }, onError: (error) {
        // Handle error event
        print('Error: $error');
      });
      isListening = true;
    }
  }

  Future<void> _sendDataToApi(String receivedString) async {
    final url = Uri.parse('http://smartglove.somee.com/api/Sensor_Data');
    print('headers:${receivedString.trim()}');
    List<String> numberStrings = receivedString.split(',');
    print('headers1:${numberStrings[0]}');
    print('headers2:${numberStrings[1]}');
    print('headers3:${numberStrings[2]}');
    print('headers4:${numberStrings[3]}');
    print('headers5:${numberStrings[4]}');

    final headers = {
      'Sensor1_Value': numberStrings[0],
      'Sensor2_Value': numberStrings[1],
      'Sensor3_Value': numberStrings[2],
      'Sensor4_Value': numberStrings[3],
      'Sensor5_Value': numberStrings[4],
      'UserID': '1'
    };
    final body = jsonEncode({
      "Sensor1_Value": numberStrings[0],
      "Sensor2_Value": numberStrings[1],
      "Sensor3_Value": numberStrings[2],
      "Sensor4_Value": numberStrings[3],
      "Sensor5_Value": numberStrings[4],
      "UserID": 1
    });

    try {
      final response = await http.post(
        body: body,
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        //body: body,
      );

      if (response.statusCode == 201) {
        print('${response.body}');
        setState(() {
          gloveText = response.body;
        });

        print('Data sent successfully');
      } else {
        print('Failed to send data. Error: ${response.body}');
      }
    } catch (e) {
      print('Error sending data to API: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Communication'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              _scanDevices();
            },
            child: Text(isScanning ? 'Scanning...' : 'Scan Devices'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device.name ?? 'null string value'),
                  subtitle: Text(device.address),
                  onTap: () {
                    _connectToDevice(device);
                  },
                );
              },
            ),
          ),
          Text(
            gloveText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
