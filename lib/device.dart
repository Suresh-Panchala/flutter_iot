enum DeviceType { light, fan }

class Device {
  final String name;
  final String topic;
  final DeviceType type;
  bool state;
  double value;

  Device({
    required this.name,
    required this.topic,
    required this.type,
    this.state = false,
    this.value = 0,
  });
}

class Room {
  final String name;
  final List<Device> devices;

  Room({required this.name, required this.devices});
}
