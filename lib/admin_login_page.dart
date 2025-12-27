import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_dashboard_page.dart';
import 'dart:ui';
import 'responsive_utils.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String error = '';
  bool loading = false;

  // 🎨 Palette de couleurs
  final Color _deepTerracotta = const Color(0xFFB6745E);
  final Color _warmClay = const Color(0xFFD3A588);
  final Color _mutedRose = const Color(0xFFC99A9A);
  final Color _warmTaupe = const Color(0xFF8C6E63);
  final Color _amberDust = const Color(0xFFC7A16B);
  final Color _backgroundBeige = const Color(0xFFEEE3D6);

  Future<void> loginAdmin() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      if (doc.exists && doc['role'] == 'admin') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
        );
      } else {
        setState(() => error = 'Accès refusé (pas admin)');
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _backgroundBeige,
              _warmClay.withValues(alpha: 0.4),
              _mutedRose.withValues(alpha: 0.25),
              _deepTerracotta.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.maxContentWidth,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.responsivePadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Bouton retour
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: _deepTerracotta,
                          size: context.responsive(mobile: 24, tablet: 28, desktop: 32),
                        ),
                      ),
                    ),
                    SizedBox(height: context.responsive(mobile: 16, tablet: 24, desktop: 32)),

                    // Logo/Icon
                    Container(
                      width: context.responsive(mobile: 80, tablet: 90, desktop: 100),
                      height: context.responsive(mobile: 80, tablet: 90, desktop: 100),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [_deepTerracotta, _amberDust],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _deepTerracotta.withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: context.responsive(mobile: 40, tablet: 45, desktop: 50),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Titre
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [_deepTerracotta, _amberDust, _mutedRose],
                      ).createShader(bounds),
                      child: Text(
                        'ADMIN',
                        style: TextStyle(
                          fontSize: context.responsiveFont(32),
                          fontWeight: FontWeight.w300,
                          letterSpacing: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Espace administrateur',
                      style: TextStyle(
                        fontSize: context.responsiveFont(14),
                        color: _warmTaupe.withValues(alpha: 0.6),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Email field
                    _buildTextField(
                      controller: emailCtrl,
                      label: 'Email',
                      icon: Icons.email_rounded,
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    _buildTextField(
                      controller: passCtrl,
                      label: 'Mot de passe',
                      icon: Icons.lock_rounded,
                      obscureText: true,
                    ),
                    const SizedBox(height: 32),

                    // Bouton connexion
                    _buildLoginButton(),

                    // Erreur
                    if (error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      error,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: context.responsiveFont(13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _warmClay.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _warmTaupe.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            enabled: !loading,
            style: TextStyle(
              color: const Color(0xFF3D322B),
              fontSize: context.responsiveFont(15),
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: _warmTaupe.withValues(alpha: 0.6),
                fontSize: context.responsiveFont(14),
              ),
              prefixIcon: Icon(
                icon,
                color: _deepTerracotta.withValues(alpha: 0.7),
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.responsive(mobile: 20, tablet: 24, desktop: 28),
                vertical: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: context.responsive(mobile: 56, tablet: 60, desktop: 64),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_deepTerracotta, _amberDust],
        ),
        boxShadow: [
          BoxShadow(
            color: _deepTerracotta.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : loginAdmin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Connexion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsiveFont(16),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }
}