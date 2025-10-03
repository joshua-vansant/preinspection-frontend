import 'package:flutter/material.dart';

class AppLifeCycleHandler extends StatefulWidget {
  final Widget child;

  const AppLifeCycleHandler({required this.child, super.key});

  @override
  State<AppLifeCycleHandler> createState() => _AppLifeCycleHandlerState();
}

class _AppLifeCycleHandlerState extends State<AppLifeCycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
