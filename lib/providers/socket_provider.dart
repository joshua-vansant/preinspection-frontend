import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_provider.dart';
import '../config/api_config.dart';

typedef SocketCallback = void Function(dynamic data);

class SocketProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  IO.Socket? _socket;

  final Map<String, List<SocketCallback>> _listeners = {};

  SocketProvider({required this.authProvider}) {
    _initSocket();
  }

  void _initSocket() async {
    if (_socket != null) {
      debugPrint("SocketProvider: Socket already initialized, skipping.");
      return; 
    }

    // Make sure to have the org ID
    final orgId = authProvider.org?['id'];
    if (orgId == null) {
      debugPrint("SocketProvider: org_id missing, calling loadOrg...");
      await authProvider.loadOrg();
    }

    final finalOrgId = authProvider.org?['id'];
    if (finalOrgId == null) {
      debugPrint("SocketProvider: No org ID, cannot initialize socket.");
      return;
    }

    debugPrint("SocketProvider: Initializing socket for org $finalOrgId...");

    final uri = ApiConfig.baseUrl;
    debugPrint("SocketProvider: Connecting to $uri");

    _socket = IO.io(
      uri,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect() 
          .enableReconnection() 
          .build(),
    );


    _socket!.onConnect((_) {
      debugPrint("SocketProvider: ✅ Connected to backend socket");
      debugPrint("SocketProvider: Emitting join_org with org_id=$finalOrgId");

      _socket!.emit('join_org', {'org_id': finalOrgId});
    });

    _socket!.onDisconnect((_) {
      debugPrint("SocketProvider: ❌ Disconnected from backend socket");
    });

    _socket!.onConnectError((err) {
      debugPrint("SocketProvider: ⚠️ Connect error: $err");
    });

    _socket!.onError((err) {
      debugPrint("SocketProvider: 🔥 Socket error: $err");
    });


    _socket!.onAny((event, data) {
      debugPrint("SocketProvider: 📩 Event received: $event -> $data");
      if (_listeners.containsKey(event)) {
        for (var callback in _listeners[event]!) {
          callback(data);
        }
      } else {
        debugPrint("SocketProvider: No listeners registered for event '$event'");
      }
    });

    _socket!.onReconnect((_) => debugPrint("SocketProvider: 🔄 Reconnected"));
    _socket!.onReconnectAttempt((_) => debugPrint("SocketProvider: Trying to reconnect..."));
    _socket!.onReconnectFailed((_) => debugPrint("SocketProvider: Reconnect failed"));

    _socket!.connect();
    debugPrint("SocketProvider: Connection attempt complete.");
  }

  void onEvent(String event, SocketCallback callback) {
  _listeners.putIfAbsent(event, () => []);
  _listeners[event]!.add(callback);

  _socket?.on(event, callback);

  debugPrint("SocketProvider: Listener added for event '$event'");
}


  void offEvent(String event, [SocketCallback? callback]) {
    if (!_listeners.containsKey(event)) return;

    if (callback != null) {
      _listeners[event]!.remove(callback);
      debugPrint("SocketProvider: Listener removed for event '$event'");
    } else {
      _listeners[event] = [];
      debugPrint("SocketProvider: All listeners removed for event '$event'");
    }
  }

  void disconnect() {
    debugPrint("SocketProvider: Manual disconnect called.");
    _socket?.disconnect();
    _socket = null;
    _listeners.clear();
    debugPrint("SocketProvider: Socket disconnected and listeners cleared.");
  }
}
