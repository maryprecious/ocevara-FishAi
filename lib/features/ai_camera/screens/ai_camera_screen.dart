import 'package:camera/camera.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ocevara/core/theme/app_colors.dart';
import 'package:ocevara/features/ai_camera/providers/ai_camera_provider.dart';
import 'package:ocevara/features/catch_log/widgets/add_catch_form.dart';

class AICameraScreen extends ConsumerStatefulWidget {
  const AICameraScreen({super.key});

  @override
  ConsumerState<AICameraScreen> createState() => _AICameraScreenState();
}

class _AICameraScreenState extends ConsumerState<AICameraScreen> {
  CameraController? _controller;
  bool _isProcessing = false;
  String? _detectedLabel;
  bool _isSnapping = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high, 
      enableAudio: false,
    );

    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});

    _controller!.startImageStream((image) {
      if (_isProcessing) return;
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    _isProcessing = true;
    
    
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted && _detectedLabel == null) {
      setState(() {
        _detectedLabel = 'Scanning for species...';
      });
    }
    _isProcessing = false;
  }

  /// this takes a still photo and identifies it using Gemini Vision via the backend.
  Future<void> _snapAndIdentify() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isSnapping = true);
    try {
      // this will stop the live stream while snapping
      await _controller!.stopImageStream();
      final file = await _controller!.takePicture();
      
      final service = ref.read(aiCameraServiceProvider);
      final bytes = await file.readAsBytes();
      final result = await service.identifyFish(bytes);

      if (mounted) {
        setState(() {
          final commonName = result['commonName'] ?? 'Unknown';
          final confidence = ((result['confidence'] ?? 0.0) * 100).toInt();
          _detectedLabel = '$commonName ($confidence%)';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Identified: $_detectedLabel'),
            backgroundColor: AppColors.accentBlue,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // restart live stream
      _controller!.startImageStream((image) {
        if (_isProcessing) return;
        _processImage(image);
      });
    } catch (e) {
      debugPrint('Snap error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error identifying fish: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSnapping = false);
    }
  }

  /// Opens the Add Catch form pre-filled with the detected fish name.
  void _logCatch() {
    if (_detectedLabel != null) {
      showAddCatchDialog(
        context,
        initialSpecies: _detectedLabel!.split('(')[0].trim(),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Point the camera at a fish first!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      // no AppBar here just true full-screen camera experience
      body: Stack(
        fit: StackFit.expand, 
        children: [
     
          _FullScreenCamera(controller: _controller!),

          
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 60, 
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.navy.withOpacity(0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.accentBlue, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.psychology, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _detectedLabel ?? 'Scanning for fish...',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),

        
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Snap & Identify
                    _buildControlButton(
                      icon: _isSnapping
                          ? Icons.hourglass_top
                          : Icons.camera_alt,
                      label: 'Snap & ID',
                      onTap: _isSnapping ? null : _snapAndIdentify,
                    ),

                    // log Catch the primary large button
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _logCatch,
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.accentBlue.withOpacity(0.45),
                                  blurRadius: 24,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 34),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Log Catch',
                          style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    // torch or th flash placeholder
                    _buildControlButton(
                      icon: Icons.flash_auto,
                      label: 'Flash',
                      onTap: () async {
                        try {
                          await _controller!.setFlashMode(
                            _controller!.value.flashMode == FlashMode.off
                                ? FlashMode.torch
                                : FlashMode.off,
                          );
                          setState(() {});
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Point camera at fish • tap + to log catch',
                  style: GoogleFonts.lato(
                      color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.lato(color: Colors.white, fontSize: 11),
        ),
      ],
    );
  }
}


class _FullScreenCamera extends StatelessWidget {
  final CameraController controller;
  const _FullScreenCamera({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final previewAspect = controller.value.aspectRatio;

    
    var scale = size.aspectRatio * previewAspect;
    if (scale < 1) scale = 1 / scale;

    return Transform.scale(
      scale: scale,
      child: Center(child: CameraPreview(controller)),
    );
  }
}
