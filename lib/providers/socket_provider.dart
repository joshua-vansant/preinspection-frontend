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
  BuildContext? _context; // optional: set context to show errors

  SocketProvider({required this.authProvider});

  /// Optional: provide a context so we can show user-friendly messages
  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> _initSocket() async {
    if (_socket != null) return;

    final orgId = authProvider.org?['id'];
    if (orgId == null) {
      try {
        await authProvider.loadOrg();
      } catch (e) {
        debugPrint("SocketProvider: Failed to load org: $e");
        if (_context != null) UIHelpers.showError(_context!, e.toString());
        return;
      }
    }

    final finalOrgId = authProvider.org?['id'];
    if (finalOrgId == null) {
      debugPrint("SocketProvider: No org ID, cannot initialize socket.");
      if (_context != null)
        UIHelpers.showError(
          _context!,
          "Unable to connect: no organization found",
        );
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
      debugPrint("SocketProvider: ✅ Connected to backend socket");
      _socket!.emit('join_org', {'org_id': finalOrgId});
    });

    _socket!.onDisconnect((_) {});
    _socket!.onConnectError((err) {});
    _socket!.onError((err) {});

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

  void reconnectIfNeeded() async {
    if (_socket == null || !_socket!.connected) {
      _socket?.disconnect();
      _socket = null;
      _listeners.clear();
      await _initSocket();
    }
    if (_socket == null || !_socket!.connected) {
      _initSocket();
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _listeners.clear();
  }
}
