import 'package:probashi_live/utils/variables.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect(String jwtToken) {
    // Configure socket options including the auth token
    socket = IO.io(Variables.BASE_URL, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {
        'token': jwtToken,  // pass JWT here in handshake auth
      },
    });

    // Connect socket
    socket.connect();

    // Connection successful
    socket.on('connect', (_) {
      print('Connected to socket with id: ${socket.id}');
    });

    // Server sends welcome or connected event
    socket.on('connected', (data) {
      print('Server says: ${data['message']}');
    });

    // Listen to custom events from server
    socket.on('some-event', (data) {
      print('Received some-event: $data');
    });

    // Handle disconnection
    socket.on('disconnect', (_) {
      print('Socket disconnected');
    });

    // Handle connection error (e.g., invalid token)
    socket.on('connect_error', (error) {
      print('Connection error: $error');
    });
  }

  void disconnect() {
    socket.disconnect();
  }
}
