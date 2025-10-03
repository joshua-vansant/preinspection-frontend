import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_provider.dart';
import '../config/api_config.dart';
import '../utils/ui_helpers.dart';

typedef SocketCallback = void Function(dynamic data);

class SocketProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  IO.Socket? _socket;

  final Map<String, List<SocketCallback>> _listeners = {};
  BuildContext? _context;

  SocketProvider({required this.authProvider});

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> _initSocket() async {
    if (_socket != null) return;

    final token = authProvider.token;
    if (token == null) {
      debugPrint("SocketProvider: No auth token, cannot init socket");
      _showError("Not authenticated: cannot connect to socket.");
      return;
    }

    final orgId = authProvider.org?['id'];
    if (authProvider.isAdmin && orgId == null) {
      debugPrint("SocketProvider: Admin missing org ID, cannot init socket");
      _showError("No organization found for admin.");
      return;
    }

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
      debugPrint("SocketProvider: Connected to backend socket");

      if (orgId != null) {
        _socket!.emit('join_org', {'org_id': orgId});
      } else {
        _socket!.emit('join_user', {'user_id': authProvider.user?['id']});
      }
    });

    _socket!.onDisconnect((_) => debugPrint("SocketProvider: Disconnected"));
    _socket!.onConnectError((err) => _showError("Socket connect error: $err"));
    _socket!.onError((err) => _showError("Socket error: $err"));

    _socket!.onAny((event, data) {
      if (_listeners.containsKey(event)) {
        for (var callback in _listeners[event]!) {
          callback(data);
        }
      }
    });

    _socket!.connect();
  }

  void onEvent(String event, SocketCallback callback) {
    _listeners.putIfAbsent(event, () => []);
    _listeners[event]!.add(callback);
    _socket?.on(event, callback);
  }

  void offEvent(String event, [SocketCallback? callback]) {
    if (!_listeners.containsKey(event)) return;
    if (callback != null) {
      _listeners[event]!.remove(callback);
    } else {
      _listeners[event] = [];
    }
  }

  Future<void> reconnectIfNeeded() async {
    if (_socket == null || !_socket!.connected) {
      disconnect();
      await _initSocket();
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _listeners.clear();
  }

  void _showError(String message) {
    debugPrint("SocketProvider: $message");
    if (_context != null) {
      UIHelpers.showError(_context!, message);
    }
  }
}
