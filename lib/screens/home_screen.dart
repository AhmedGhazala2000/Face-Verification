import 'dart:io';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'face_login_screen.dart';
import 'face_register_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _hasRegisteredUsers = false;
  bool _isLoading = true;
  int _userCount = 0;
  UserModel? _loggedInUser;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _checkRegistration();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkRegistration() async {
    // Check Firestore only
    int firestoreCount = 0;
    try {
      firestoreCount = await FirestoreService.instance.getUserCount();
    } catch (e) {
      // Firestore might not be available
    }

    final count = firestoreCount;

    setState(() {
      _userCount = count;
      _hasRegisteredUsers = count > 0;
      _isLoading = false;
    });
    _animationController.forward();
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to logout, ${_loggedInUser?.name}?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _loggedInUser = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('👋 Logged out successfully'),
                  backgroundColor: Colors.deepPurple,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade900,
                Colors.deepPurple.shade600,
                Colors.purple.shade400,
              ],
            ),
          ),
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    // Show logged in user profile if authenticated
    if (_loggedInUser != null) {
      return _buildLoggedInScreen();
    }

    // Show login/register screen if not authenticated
    return _buildAuthScreen();
  }

  /// Build the logged-in user profile screen
  Widget _buildLoggedInScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade600,
              Colors.purple.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Face Recognition',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      // Logout Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, color: Colors.white),
                          tooltip: 'Logout',
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // User Avatar with Face Image
                        Stack(
                          children: [
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.deepPurple.shade400, Colors.purple.shade700],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurple.withValues(alpha: 0.5),
                                    blurRadius: 25,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child:
                                    _loggedInUser!.imagePath != null &&
                                        File(_loggedInUser!.imagePath!).existsSync()
                                    ? Image.file(
                                        File(_loggedInUser!.imagePath!),
                                        fit: BoxFit.cover,
                                        width: 160,
                                        height: 160,
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.green.shade400, Colors.green.shade700],
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          size: 90,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.deepPurple.shade900, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.verified, color: Colors.white, size: 24),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Welcome Message
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '👋 Welcome back!',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // User Name
                        Text(
                          _loggedInUser!.name,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 36),

                        // User Details Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.account_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Profile Details',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Email
                              _buildDetailRow(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: _loggedInUser!.email,
                              ),

                              const Divider(color: Colors.white24, height: 32),

                              // Face ID
                              _buildDetailRow(
                                icon: Icons.fingerprint,
                                label: 'Face ID',
                                value: _loggedInUser!.faceId,
                              ),

                              const Divider(color: Colors.white24, height: 32),

                              // Registration Date
                              _buildDetailRow(
                                icon: Icons.calendar_today_outlined,
                                label: 'Member Since',
                                value: _formatDate(_loggedInUser!.createdAt),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Status Cards Row
                        Row(
                          children: [
                            // Authentication Status Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.withValues(alpha: 0.2),
                                      Colors.green.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.verified_user,
                                        color: Colors.green,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Verified',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Authenticated',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Cloud Sync Status Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.withValues(alpha: 0.2),
                                      Colors.blue.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.cloud_done,
                                        color: Colors.blue,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Cloud',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Synced',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Logout Button (Large)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, size: 20),
                            label: const Text(
                              'Logout',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: BorderSide(
                                color: Colors.redAccent.withValues(alpha: 0.8),
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Build the authentication screen (login/register)
  Widget _buildAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade600,
              Colors.purple.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Spacer(flex: 1),

                  // App Icon/Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.face, size: 64, color: Colors.white),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Face Recognition',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    _hasRegisteredUsers
                        ? '$_userCount user${_userCount > 1 ? 's' : ''} registered. Login with your face'
                        : 'Register your face to get started',
                    style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.8)),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 2),

                  // Register Button
                  _buildActionButton(
                    icon: Icons.person_add_rounded,
                    label: 'Register New User',
                    subtitle: 'Save a new face for login',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FaceRegisterScreen()),
                      );
                      if (result == true) {
                        _checkRegistration();
                        // Show success snackbar
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Registration successful! You can now login.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                    isPrimary: !_hasRegisteredUsers,
                  ),

                  const SizedBox(height: 16),

                  // Login Button
                  _buildActionButton(
                    icon: Icons.login_rounded,
                    label: 'Login with Face',
                    subtitle: 'Verify your identity',
                    onTap: _hasRegisteredUsers
                        ? () async {
                            final user = await Navigator.push<UserModel>(
                              context,
                              MaterialPageRoute(builder: (context) => const FaceLoginScreen()),
                            );
                            if (user != null) {
                              _animationController.reset();
                              setState(() {
                                _loggedInUser = user;
                              });
                              _animationController.forward();
                            }
                          }
                        : null,
                    isPrimary: _hasRegisteredUsers,
                  ),

                  const Spacer(flex: 1),

                  // Status indicator
                  if (_hasRegisteredUsers)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '$_userCount user${_userCount > 1 ? 's' : ''} registered',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'No users registered yet',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback? onTap,
    required bool isPrimary,
  }) {
    final isEnabled = onTap != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isPrimary
                  ? Colors.white.withValues(alpha: isEnabled ? 0.2 : 0.1)
                  : Colors.white.withValues(alpha: isEnabled ? 0.1 : 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPrimary
                    ? Colors.white.withValues(alpha: isEnabled ? 0.4 : 0.2)
                    : Colors.white.withValues(alpha: isEnabled ? 0.2 : 0.1),
                width: isPrimary ? 2 : 1,
              ),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.4),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isEnabled
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isEnabled
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.2),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
