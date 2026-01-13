import 'package:flutter/material.dart';

import 'face_login_screen.dart';
import 'face_register_screen.dart';
import 'models/user_model.dart';
import 'services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasRegisteredUsers = false;
  bool _isLoading = true;
  int _userCount = 0;
  UserModel? _loggedInUser;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    final count = await DatabaseService.instance.getUserCount();
    setState(() {
      _userCount = count;
      _hasRegisteredUsers = count > 0;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                  _loggedInUser != null
                      ? 'Logged in as ${_loggedInUser!.name}'
                      : (_hasRegisteredUsers
                            ? '$_userCount user${_userCount > 1 ? 's' : ''} registered. Login with your face'
                            : 'Register your face to get started'),
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
                            setState(() {
                              _loggedInUser = user;
                            });
                          }
                        }
                      : null,
                  isPrimary: _hasRegisteredUsers,
                ),

                const Spacer(flex: 1),

                // Status indicator
                if (_loggedInUser != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Logged in: ${_loggedInUser!.name}',
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _loggedInUser = null;
                            });
                          },
                          child: const Icon(Icons.logout, color: Colors.blue, size: 18),
                        ),
                      ],
                    ),
                  )
                else if (_hasRegisteredUsers)
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
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
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
