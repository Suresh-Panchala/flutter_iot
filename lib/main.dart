import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:iot/%20mqtt_service.dart';
import 'device.dart';

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
  List<Room> rooms = [];

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

  void addDevice(Room room, Device device) {
    setState(() {
      room.devices.add(device);
    });
  }

  void addRoom(Room room) {
    setState(() {
      rooms.add(room);
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
                itemCount: rooms.length,
                itemBuilder: (context, roomIndex) {
                  final room = rooms[roomIndex];
                  return ExpansionTile(
                    title: Text(room.name,
                        style: TextStyle(fontSize: 20, color: Colors.yellow)),
                    children: room.devices.map((device) {
                      if (device.type == DeviceType.light) {
                        return buildLightCard(device);
                      } else if (device.type == DeviceType.fan) {
                        return buildFanCard(device);
                      }
                      return Container();
                    }).toList(),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  onPressed: () => showAddRoomDialog(context),
                  child: Icon(Icons.add),
                  heroTag: null,
                ),
                FloatingActionButton(
                  onPressed: () => showAddDeviceDialog(context),
                  child: Icon(Icons.add_circle_outline),
                  heroTag: null,
                ),
              ],
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
    Room? selectedRoom;

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
                DropdownButtonFormField<Room>(
                  decoration: InputDecoration(labelText: 'Select Room'),
                  items: rooms.map((room) {
                    return DropdownMenuItem(
                      value: room,
                      child: Text(room.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedRoom = value;
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a room';
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
                  addDevice(selectedRoom!,
                      Device(name: name!, topic: topic!, type: type!));
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

  void showAddRoomDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? roomName;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Room'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              decoration: InputDecoration(labelText: 'Room Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a room name';
                }
                return null;
              },
              onSaved: (value) {
                roomName = value;
              },
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
                  addRoom(Room(name: roomName!, devices: []));
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
