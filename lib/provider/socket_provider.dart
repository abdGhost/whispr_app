import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

final socketProvider = Provider<IO.Socket>((ref) {
  final socket = IO.io(
    'https://whisper-2nhg.onrender.com',
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build(),
  );

  socket.connect();

  socket.onConnect((_) => print('✅ Socket connected'));
  socket.onDisconnect((_) => print('❌ Socket disconnected'));
  socket.onError((data) => print('⚠️ Socket error: $data'));

  ref.onDispose(() {
    socket.dispose();
    print('🗑️ Socket disposed');
  });

  return socket;
});
