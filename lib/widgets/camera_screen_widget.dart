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
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) {
      debugPrint('⚠️ No cameras available');
      return;
    }

    _controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('⚠️ Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_isInitialized || _isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      final picture = await _controller.takePicture();
      final file = File(picture.path);
      widget.onPictureTaken(file);
      if (mounted) Navigator.pop(context, file);
    } catch (e) {
      debugPrint('⚠️ Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to take picture')),
        );
      }
    } finally {
      setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_isInitialized) {
      if (widget.cameras.isEmpty) {
        return Scaffold(
          body: Center(
            child: Text(
              'No camera available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CameraPreview(_controller),
          ),

          // Subtle gradient overlay for readability
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black45,
                  Colors.transparent,
                  Colors.black54,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Top app bar overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              iconSize: 28,
              onPressed: () => Navigator.pop(context),
              tooltip: 'Close camera',
            ),
          ),

          // Capture button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36.0),
              child: GestureDetector(
                onTap: _takePicture,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isTakingPicture
                              ? Colors.grey
                              : Colors.white70,
                          width: 4,
                        ),
                      ),
                    ),
                    // Inner circle (shutter)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: _isTakingPicture ? 48 : 60,
                      height: _isTakingPicture ? 48 : 60,
                      decoration: BoxDecoration(
                        color: _isTakingPicture
                            ? Colors.grey.shade400
                            : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (!_isTakingPicture)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
