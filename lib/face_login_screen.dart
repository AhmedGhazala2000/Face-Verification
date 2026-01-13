import 'dart:developer';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:face_verification/face_verification.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'models/user_model.dart';
import 'services/database_service.dart';
import 'services/firestore_service.dart';

class FaceLoginScreen extends StatefulWidget {
  const FaceLoginScreen({super.key});

  @override
  State<FaceLoginScreen> createState() => _FaceLoginScreenState();
}

class _FaceLoginScreenState extends State<FaceLoginScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isLoading = false;
  bool _isCameraInitialized = false;
  String? _message;
  bool _isSuccess = false;
  UserModel? _loggedInUser;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _message = '📷 Camera permission required';
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _message = '⚠️ Camera initialization failed: $e';
      });
    }
  }

  Future<void> _captureAndLogin() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isLoading = true;
      _message = null;
      _isSuccess = false;
      _loggedInUser = null;
    });

    try {
      // Get all registered users - try Firestore first, then local
      List<Map<String, dynamic>> firestoreUsers = [];
      try {
        firestoreUsers = await FirestoreService.instance.getAllUsers();
        log('Found ${firestoreUsers.length} users in Firestore');
      } catch (e) {
        log('⚠️ Could not fetch from Firestore: $e');
      }

      final localUsers = await DatabaseService.instance.getAllUsers();
      log('Found ${localUsers.length} users in local database');

      if (firestoreUsers.isEmpty && localUsers.isEmpty) {
        setState(() {
          _isSuccess = false;
          _message = '⚠️ No users registered yet.\nPlease register first.';
        });
        return;
      }

      // Capture the image
      final XFile image = await _controller!.takePicture();
      final imagePath = image.path;
      log('loginImagePath: $imagePath');

      String? matchedFaceId;
      Map<String, dynamic>? matchedUser;

      // Try local verification against all registered users
      log('🔍 Attempting face verification...');

      // Combine face IDs from both sources
      final allFaceIds = <String>{};
      for (final user in localUsers) {
        allFaceIds.add(user.faceId);
      }
      for (final user in firestoreUsers) {
        final faceId = user['faceId'] as String?;
        if (faceId != null) {
          allFaceIds.add(faceId);
        }
      }

      for (final faceId in allFaceIds) {
        try {
          final matchId = await FaceVerification.instance.verifyFromImagePath(
            imagePath: imagePath,
            threshold: 0.85,
            staffId: faceId,
          );

          if (matchId != null) {
            matchedFaceId = faceId;
            log('✅ Face verification successful! Match: $matchedFaceId');

            // Get user details - try Firestore first
            matchedUser = await FirestoreService.instance.getUserByFaceId(faceId);

            // Fallback to local database
            if (matchedUser == null) {
              final localUser = await DatabaseService.instance.getUserByFaceId(faceId);
              if (localUser != null) {
                matchedUser = localUser.toMap();
              }
            }
            break;
          }
        } catch (e) {
          log('Verification failed for $faceId: $e');
        }
      }

      if (matchedFaceId != null && matchedUser != null) {
        // Convert matched user to UserModel
        _loggedInUser = UserModel(
          name: matchedUser['name'] as String,
          email: matchedUser['email'] as String,
          faceId: matchedUser['faceId'] as String? ?? matchedUser['face_id'] as String,
          createdAt: matchedUser['createdAt'] != null
              ? (matchedUser['createdAt'] is DateTime
                    ? matchedUser['createdAt'] as DateTime
                    : DateTime.tryParse(matchedUser['createdAt'].toString()) ?? DateTime.now())
              : (matchedUser['created_at'] != null
                    ? DateTime.parse(matchedUser['created_at'] as String)
                    : DateTime.now()),
        );

        setState(() {
          _isSuccess = true;
          _message = '✅ Login Successful!\nWelcome back, ${_loggedInUser?.name}!';
        });

        // Wait a moment then show success dialog
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        setState(() {
          _isSuccess = false;
          _message = '❌ Face not recognized.\nPlease try again or register.';
        });
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        if (e.toString().contains('No face detected') ||
            e.toString().contains('detection failed')) {
          _message = '😕 No face detected.\nPlease position your face correctly.';
        } else if (e.toString().contains('No registered')) {
          _message = '⚠️ No face registered yet.\nPlease register first.';
        } else {
          _message = '⚠️ Verification failed:\n${e.toString().split(':').last.trim()}';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Calculate cosine similarity between two embeddings
  double _calculateCosineSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      return 0.0;
    }

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }

    if (norm1 == 0.0 || norm2 == 0.0) {
      return 0.0;
    }

    return dotProduct / math.sqrt(norm1 * norm2);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              'Login Successful!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            if (_loggedInUser != null) ...[
              Text(
                'Welcome back,',
                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 4),
              Text(
                _loggedInUser!.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _loggedInUser!.email,
                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
              ),
            ] else
              Text(
                'Your identity has been verified.',
                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, _loggedInUser); // Go back to home with user
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized && _controller != null)
            Positioned.fill(child: CameraPreview(_controller!))
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Initializing camera...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),

          // Gradient overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                ),
              ),
            ),
          ),

          // Face Guide Overlay
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isLoading ? 1.0 : _pulseAnimation.value,
                  child: Container(
                    width: 280,
                    height: 360,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isSuccess
                            ? Colors.green
                            : (_isLoading ? Colors.blue : Colors.white),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(180),
                      boxShadow: [
                        BoxShadow(
                          color: (_isSuccess ? Colors.green : Colors.blue).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Scanning animation when loading
          if (_isLoading) Center(child: SizedBox(width: 280, height: 360, child: _ScanAnimation())),

          // Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Face Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
          ),

          // Instructions
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Position your face within the oval\nLook directly at the camera',
                style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Message
                  if (_message != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isSuccess
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isSuccess
                              ? Colors.green.withValues(alpha: 0.5)
                              : Colors.red.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        _message!,
                        style: TextStyle(
                          fontSize: 16,
                          color: _isSuccess ? Colors.green : Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Capture Button
                  GestureDetector(
                    onTap: (_isLoading || !_isCameraInitialized) ? null : _captureAndLogin,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.deepPurple,
                              ),
                            )
                          : Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.deepPurple, width: 4),
                              ),
                              child: const Icon(Icons.login, color: Colors.deepPurple, size: 32),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    _isLoading ? 'Verifying...' : 'Tap to login',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Scanning animation widget
class _ScanAnimation extends StatefulWidget {
  @override
  State<_ScanAnimation> createState() => _ScanAnimationState();
}

class _ScanAnimationState extends State<_ScanAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(painter: _ScanPainter(_animation.value));
      },
    );
  }
}

class _ScanPainter extends CustomPainter {
  final double progress;

  _ScanPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.withValues(alpha: 0.0),
          Colors.blue.withValues(alpha: 0.5),
          Colors.blue.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, progress * size.height - 30, size.width, 60));

    canvas.drawRect(Rect.fromLTWH(0, progress * size.height - 30, size.width, 60), paint);
  }

  @override
  bool shouldRepaint(covariant _ScanPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
