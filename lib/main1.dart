import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:iot/%20mqtt_service.dart';
import 'device1.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Automation',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.yellow,
        hintColor: Colors.yellow,
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
        textTheme: TextTheme(
          bodyText1: TextStyle(color: Colors.white),
          bodyText2: TextStyle(color: Colors.white),
        ),
      ),
      home: HomeAutomationPage(),
    );
  }
}

class HomeAutomationPage extends StatefulWidget {
  @override
  _HomeAutomationPageState createState() => _HomeAutomationPageState();
}

class _HomeAutomationPageState extends State<HomeAutomationPage> {
  late MQTTService mqttService;
  List<Device> devices = [];

  @override
  void initState() {
    super.initState();
    mqttService = MQTTService('test.mosquitto.org', 'flutter_client');
    mqttService.connect();
  }

  @override
  void dispose() {
    mqttService.disconnect();
    super.dispose();
  }

  void onSwitchChanged(Device device, bool state) {
    mqttService.publishMessage(device.topic, state ? "ON" : "OFF");
    setState(() {
      device.state = state;
    });
  }

  void onSliderChanged(Device device, double value) {
    mqttService.publishMessage(device.topic, value.toString());
    setState(() {
      device.value = value;
    });
  }

  void addDevice(Device device) {
    setState(() {
      devices.add(device);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Automation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  if (device.type == DeviceType.light) {
                    return buildLightCard(device);
                  } else if (device.type == DeviceType.fan) {
                    return buildFanCard(device);
                  }
                  return Container();
                },
              ),
            ),
            FloatingActionButton(
              onPressed: () => showAddDeviceDialog(context),
              child: Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLightCard(Device device) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(FontAwesomeIcons.lightbulb,
                    color: Colors.yellow, size: 30),
                SizedBox(width: 16),
                Text(device.name,
                    style: TextStyle(fontSize: 20, color: Colors.white)),
              ],
            ),
            FlutterSwitch(
              width: 55.0,
              height: 25.0,
              value: device.state,
              borderRadius: 30.0,
              padding: 4.0,
              activeColor: Colors.green,
              inactiveColor: Colors.grey,
              onToggle: (value) => onSwitchChanged(device, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFanCard(Device device) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FontAwesomeIcons.fan, color: Colors.yellow, size: 30),
                SizedBox(width: 16),
                Text(device.name,
                    style: TextStyle(fontSize: 20, color: Colors.white)),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 8.0,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 24.0),
              ),
              child: Slider(
                value: device.value,
                min: 0,
                max: 100,
                divisions: 100,
                label: device.value.round().toString(),
                onChanged: (value) => onSliderChanged(device, value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showAddDeviceDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? name;
    String? topic;
    DeviceType? type;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Device'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Device Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a device name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    name = value;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'MQTT Topic'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an MQTT topic';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    topic = value;
                  },
                ),
                DropdownButtonFormField<DeviceType>(
                  decoration: InputDecoration(labelText: 'Device Type'),
                  items: [
                    DropdownMenuItem(
                      value: DeviceType.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: DeviceType.fan,
                      child: Text('Fan'),
                    ),
                  ],
                  onChanged: (value) {
                    type = value;
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a device type';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  addDevice(Device(name: name!, topic: topic!, type: type!));
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
