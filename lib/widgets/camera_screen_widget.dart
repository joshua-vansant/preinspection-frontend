import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  final Function(File) onPictureTaken;
  final List<CameraDescription> cameras;

  const CameraScreen({
    required this.onPictureTaken,
    required this.cameras,
    super.key,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isNotEmpty) {
      _controller = CameraController(
        widget.cameras.first,
        ResolutionPreset.medium,
      );
      _controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isInitialized = true;
        });
      });
    } else {
      // No cameras found
      debugPrint('DEBUG: ⚠️ No cameras available');
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      if (widget.cameras.isEmpty) {
        return const Scaffold(body: Center(child: Text('No camera available')));
      }

      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: CameraPreview(_controller),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            final picture = await _controller.takePicture();
            Navigator.pop(context, File(picture.path));
          } catch (e) {
            debugPrint('DEBUG: ⚠️ Error taking picture: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to take picture')),
            );
          }
        },
        child: const Icon(Icons.camera),
      ),
    );
  }
}
