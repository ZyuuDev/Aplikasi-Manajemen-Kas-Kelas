import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/class_provider.dart';
import '../theme.dart';
import 'dashboard_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final input = _usernameController.text.trim();
      final password = _passwordController.text;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final email = input == 'bendahara' ? 'arrasydnanda09@gmail.com' : input;
        
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.user != null) {
          // Load class data via Riverpod
          await ref.read(classProvider.notifier).loadClassData();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        } else {
          setState(() {
            _errorMessage = 'Login gagal. Silakan coba lagi.';
          });
        }
      } on AuthException catch (e) {
        setState(() {
          _errorMessage = e.message;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: $e';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Glow Blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryEmerald.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentAmber.withOpacity(0.05),
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryEmerald, Color(0xFF0D9488)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24.0),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryEmerald.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.wallet,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // App Name
                  const Text(
                    'SakuKelas',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pusat Kendali Kas Kelas Bendahara',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Login Form Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Akses Bendahara',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Masukkan detail akun bendahara untuk masuk.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Username Input
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                hintText: 'bendahara',
                                prefixIcon: Icon(LucideIcons.user, size: 20, color: AppTheme.textMuted),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Harap isi username.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Input
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: '******',
                                prefixIcon: const Icon(LucideIcons.lock, size: 20, color: AppTheme.textMuted),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                    size: 20,
                                    color: AppTheme.textMuted,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Harap isi password.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Error Message
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppTheme.destructiveRose,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            
                            // Submit Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Masuk Ke Dashboard'),
                                        SizedBox(width: 8),
                                        Icon(LucideIcons.arrowRight, size: 18),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Helper Notice
                  const Text(
                    '💡 Akun Bendahara: "arrasydnanda09@gmail.com" / "nanda1234"\n(atau ketik "bendahara" dengan password "nanda1234")',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
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
