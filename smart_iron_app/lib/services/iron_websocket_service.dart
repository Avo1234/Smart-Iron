// import 'dart:convert';
// import 'dart:async';
// import 'package:web_socket_channel/web_socket_channel.dart';

// class IronWebSocketService {
//   final Uri _wsUrl = Uri.parse('ws://192.168.4.1/ws');
//   WebSocketChannel? _channel;
//   bool isConnected = false;

//   // Callbacks hooked directly into the UI state tree lifecycle handlers
//   final Function(Map<String, dynamic>) onMessageReceived;
//   final Function(bool) onConnectionStatusChanged;

//   IronWebSocketService({
//     required this.onMessageReceived,
//     required this.onConnectionStatusChanged,
//   });

//   void connect() {
//     try {
//       _channel = WebSocketChannel.connect(_wsUrl);
//       isConnected = true;
//       onConnectionStatusChanged(true);

//       _channel!.stream.listen(
//         (message) {
//           final Map<String, dynamic> data = jsonDecode(message);
//           onMessageReceived(data);
//         },
//         onError: (error) => _handleDisconnect(),
//         onDone: () => _handleDisconnect(),
//       );
//     } catch (e) {
//       _handleDisconnect();
//     }
//   }

//   void _handleDisconnect() {
//     if (isConnected) {
//       isConnected = false;
//       onConnectionStatusChanged(false);
//     }
//     _reconnectDelay();
//   }

//   void _reconnectDelay() {
//     Future.delayed(const Duration(seconds: 3), () {
//       if (!isConnected) connect();
//     });
//   }

//   void sendModeChange(int index) {
//     if (!isConnected || _channel == null) return;
//     final jsonMessage = jsonEncode({"selectedMode": index});
//     _channel!.sink.add(jsonMessage);
//   }

//   void sendResumeCommand() {
//     if (!isConnected || _channel == null) return;
//     final jsonMessage = jsonEncode({"action": "RESUME"});
//     _channel!.sink.add(jsonMessage);
//   }

//   void dispose() {
//     _channel?.sink.close();
//   }
// }




import 'dart:async';
import 'dart:math';

class IronWebSocketService {
  bool isConnected = false;

  final Function(Map<String, dynamic>) onMessageReceived;
  final Function(bool) onConnectionStatusChanged;

  // Mock Engine Control Variables
  Timer? _mockNetworkTimer;
  Timer? _hardwareSimulationTimer;
  
  int _selectedMode = 0;
  double _currentTemp = 25.0;
  bool _ironActive = true;
  bool _isHeating = false;
  String _shutoffReason = "";
  int _lastInteractionSecondsAgo = 0;

  // Preset configuration map to simulate heater operations accurately
  final List<int> _targetTemps = [110, 140, 150, 180, 200];
  final List<int> _maxTemps = [130, 160, 170, 200, 220];

  IronWebSocketService({
    required this.onMessageReceived,
    required this.onConnectionStatusChanged,
  });

  void connect() {
    // Simulate network connection lag (1.5 seconds)
    Future.delayed(const Duration(milliseconds: 1500), () {
      isConnected = true;
      onConnectionStatusChanged(true);
      
      // Start streaming JSON states to the UI every 300ms
      _mockNetworkTimer = Timer.periodic(const Duration(milliseconds: 300), (_) => _broadcastState());
      
      // Run the iron's internal logic controller every 1 second
      _hardwareSimulationTimer = Timer.periodic(const Duration(seconds: 1), (_) => _runHardwareSimulationLoop());
    });
  }

  void _runHardwareSimulationLoop() {
    if (!_ironActive) return;

    _lastInteractionSecondsAgo++;

    // 1. Simulating Heater Core Thermal Mechanics
    int target = _targetTemps[_selectedMode];
    if (_currentTemp < target - 3) {
      _isHeating = true;
      // Heats up rapidly when element turns on
      _currentTemp += 4.0 + Random().nextDouble() * 2; 
    } else if (_currentTemp >= target) {
      _isHeating = false;
      // Natural room temperature radiant cooling action
      _currentTemp -= 0.8; 
    } else {
      // Small cooling variance when hovering close to target temp
      _currentTemp += _isHeating ? 1.5 : -0.5;
    }

    // 2. Simulate Inactivity Safety Auto-Shutoff Tracker
    if (_lastInteractionSecondsAgo >= 30) {
      triggerShutoff("MOCK INACTIVITY");
    }
  }

  void _broadcastState() {
    int countdown = 30 - _lastInteractionSecondsAgo;
    
    onMessageReceived({
      'currentTemp': _currentTemp,
      'selectedMode': _selectedMode,
      'ironActive': _ironActive,
      'isHeating': _isHeating,
      'shutoffReason': _shutoffReason,
      'countdown': countdown < 0 ? 0 : countdown,
    });
  }

  void sendModeChange(int index) {
    if (!isConnected) return;
    _selectedMode = index;
    _lastInteractionSecondsAgo = 0; // Reset countdown timer on user interaction
    _broadcastState();
  }

  void sendResumeCommand() {
    _ironActive = true;
    _shutoffReason = "";
    _lastInteractionSecondsAgo = 0;
    _currentTemp = 25.0; // Reset iron to room temperature on safety clear
    _broadcastState();
  }

  void triggerShutoff(String reason) {
    _ironActive = false;
    _isHeating = false;
    _shutoffReason = reason;
    _broadcastState();
  }

  void dispose() {
    _mockNetworkTimer?.cancel();
    _hardwareSimulationTimer?.cancel();
  }
}