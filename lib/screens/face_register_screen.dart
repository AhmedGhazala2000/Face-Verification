import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:face_verification/face_verification.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/firestore_service.dart';

class FaceRegisterScreen extends StatefulWidget {
  const FaceRegisterScreen({super.key});

  @override
  State<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends State<FaceRegisterScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isLoading = false;
  bool _isCameraInitialized = false;
  String? _message;
  bool _isSuccess = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Captured face data
  String? _capturedFaceId;

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

  Future<void> _captureFace() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isLoading = true;
      _message = null;
      _isSuccess = false;
    });

    try {
      // Capture the image
      final XFile image = await _controller!.takePicture();
      final imagePath = image.path;
      log('registerImagePath: $imagePath');

      // Generate unique face ID for this user
      final faceId = 'user_${DateTime.now().millisecondsSinceEpoch}';

      // Check if this face ID already registered (for replacement)
      final isAlreadyRegistered = await FaceVerification.instance.isFaceRegistered(faceId);

      // Register the face with FaceVerification
      await FaceVerification.instance.registerFromImagePath(
        id: faceId,
        imagePath: imagePath,
        imageId: 'face_${DateTime.now().millisecondsSinceEpoch}',
        replace: isAlreadyRegistered,
      );

      // Store the captured face data
      _capturedFaceId = faceId;

      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _message = '✅ Face captured successfully!';
      });

      // Show the user info dialog after face is captured
      await _showUserInfoDialog();
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _capturedFaceId = null;
        if (e.toString().contains('No face detected') ||
            e.toString().contains('detection failed')) {
          _message = '😕 No face detected. Please try again.';
        } else if (e.toString().contains('Multiple faces')) {
          _message = '👥 Multiple faces detected. Only one face allowed.';
        } else {
          _message = '⚠️ Face capture failed: ${e.toString().split(':').last.trim()}';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showUserInfoDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Complete Registration',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Face captured successfully!',
                style: TextStyle(color: Colors.green, fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  prefixIcon: const Icon(Icons.person, color: Colors.deepPurple),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  prefixIcon: const Icon(Icons.email, color: Colors.deepPurple),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Cancel - reset local state
              _capturedFaceId = null;
              setState(() {
                _isSuccess = false;
                _message = null;
              });
              Navigator.pop(context, false);
            },
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Register'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _saveUserToDatabase();
    }
  }

  Future<void> _saveUserToDatabase() async {
    if (_capturedFaceId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if email already exists in Firestore
      final firestoreEmailExists = await FirestoreService.instance.emailExists(
        _emailController.text.trim(),
      );

      if (firestoreEmailExists) {
        setState(() {
          _isSuccess = false;
          _message = '⚠️ Email already registered. Please use a different email.';
          _isLoading = false;
          _capturedFaceId = null;
        });
        return;
      }

      // Generate a unique user ID
      final userId = 'uid_${DateTime.now().millisecondsSinceEpoch}';

      // Save to Firestore
      await FirestoreService.instance.saveUser(
        userId: userId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        faceId: _capturedFaceId!,
      );
      log('✅ User saved to Firestore');

      setState(() {
        _isSuccess = true;
        _message = '✅ Registration complete!\nWelcome, ${_nameController.text.trim()}!';
      });

      // Wait a moment then go back
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = '⚠️ Registration failed: ${e.toString().split(':').last.trim()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller?.dispose();
    _nameController.dispose();
    _emailController.dispose();
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

          // Corner guides
          Center(
            child: SizedBox(
              width: 300,
              height: 380,
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, child: _buildCorner(true, true)),
                  Positioned(top: 0, right: 0, child: _buildCorner(true, false)),
                  Positioned(bottom: 0, left: 0, child: _buildCorner(false, true)),
                  Positioned(bottom: 0, right: 0, child: _buildCorner(false, false)),
                ],
              ),
            ),
          ),

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
                      'Register Face',
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
                'Position your face within the oval\nKeep a neutral expression',
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
                    onTap: (_isLoading || !_isCameraInitialized) ? null : _captureFace,
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
                              child: const Icon(
                                Icons.person_add,
                                color: Colors.deepPurple,
                                size: 32,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    _isLoading ? 'Registering...' : 'Tap to register',
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

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}
