import 'package:flutter/material.dart';
import 'admin_login_page.dart';
import 'student_login_page.dart';
import 'dart:ui';
import 'responsive_utils.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  // 🎨 Palette de couleurs
  static const Color _deepTerracotta = Color(0xFFB6745E);
  static const Color _warmClay = Color(0xFFD3A588);
  static const Color _mutedRose = Color(0xFFC99A9A);
  static const Color _oliveMoss = Color(0xFF9BA17B);
  static const Color _warmTaupe = Color(0xFF8C6E63);
  static const Color _amberDust = Color(0xFFC7A16B);
  static const Color _backgroundBeige = Color(0xFFEEE3D6);

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
                child: ResponsiveBuilder(
                  mobile: _buildMobileLayout(context),
                  tablet: _buildTabletLayout(context),
                  desktop: _buildDesktopLayout(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Layout mobile (vertical)
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogo(context, size: 80),
        const SizedBox(height: 32),
        _buildTitle(context),
        const SizedBox(height: 12),
        _buildTagline(context),
        const SizedBox(height: 48),
        _buildDivider(),
        const SizedBox(height: 16),
        _buildSubtitle(context),
        const SizedBox(height: 32),
        _buildRoleButton(
          context: context,
          label: 'ADMINISTRATEUR',
          subtitle: 'Gérer les élèves',
          icon: Icons.admin_panel_settings_rounded,
          gradient: [_deepTerracotta, _amberDust],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminLoginPage()),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildRoleButton(
          context: context,
          label: 'ÉLÈVE',
          subtitle: 'Accéder au chatbot',
          icon: Icons.school_rounded,
          gradient: [_oliveMoss, _warmClay],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudentLoginPage()),
            );
          },
        ),
      ],
    );
  }

  // Layout tablette (2 colonnes)
  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogo(context, size: 100),
        const SizedBox(height: 40),
        _buildTitle(context),
        const SizedBox(height: 12),
        _buildTagline(context),
        const SizedBox(height: 60),
        _buildDivider(),
        const SizedBox(height: 16),
        _buildSubtitle(context),
        const SizedBox(height: 48),
        Row(
          children: [
            Expanded(
              child: _buildRoleButton(
                context: context,
                label: 'ADMIN',
                subtitle: 'Gérer les élèves',
                icon: Icons.admin_panel_settings_rounded,
                gradient: [_deepTerracotta, _amberDust],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildRoleButton(
                context: context,
                label: 'ÉLÈVE',
                subtitle: 'Accéder au chatbot',
                icon: Icons.school_rounded,
                gradient: [_oliveMoss, _warmClay],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentLoginPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Layout desktop (horizontal)
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Partie gauche - Branding
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(context, size: 120),
              const SizedBox(height: 40),
              _buildTitle(context),
              const SizedBox(height: 16),
              _buildTagline(context),
            ],
          ),
        ),
        
        // Séparateur vertical
        Container(
          width: 1,
          height: 300,
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                _deepTerracotta.withValues(alpha: 0.4),
                _amberDust.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),
        
        // Partie droite - Boutons
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSubtitle(context),
              const SizedBox(height: 40),
              _buildRoleButton(
                context: context,
                label: 'ADMINISTRATEUR',
                subtitle: 'Gérer les élèves',
                icon: Icons.admin_panel_settings_rounded,
                gradient: [_deepTerracotta, _amberDust],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildRoleButton(
                context: context,
                label: 'ÉLÈVE',
                subtitle: 'Accéder au chatbot',
                icon: Icons.school_rounded,
                gradient: [_oliveMoss, _warmClay],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentLoginPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(BuildContext context, {required double size}) {
    final responsiveSize = context.responsive(
      mobile: size,
      tablet: size * 1.2,
      desktop: size * 1.3,
    );
    
    return Container(
      width: responsiveSize,
      height: responsiveSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_deepTerracotta, _amberDust],
        ),
        boxShadow: [
          BoxShadow(
            color: _deepTerracotta.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: responsiveSize * 0.5,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [_deepTerracotta, _amberDust, _mutedRose],
      ).createShader(bounds),
      child: Text(
        'KINTANA',
        style: TextStyle(
          fontSize: context.responsiveFont(40),
          fontWeight: FontWeight.w300,
          letterSpacing: 10,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTagline(BuildContext context) {
    return Text(
      'Car nous sommes tous enfants des étoiles',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: context.responsiveFont(13),
        fontWeight: FontWeight.w300,
        color: _warmTaupe.withValues(alpha: 0.6),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      width: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            _deepTerracotta.withValues(alpha: 0.4),
            _amberDust.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      'Choisissez votre profil',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: context.responsiveFont(16),
        fontWeight: FontWeight.w400,
        color: _warmTaupe.withValues(alpha: 0.7),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildRoleButton({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        context.responsive(mobile: 24, tablet: 28, desktop: 32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(
              context.responsive(mobile: 24, tablet: 28, desktop: 32),
            ),
            border: Border.all(
              color: _warmClay.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _warmTaupe.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: EdgeInsets.all(
                  context.responsive(mobile: 20, tablet: 24, desktop: 28),
                ),
                child: Row(
                  children: [
                    Container(
                      width: context.responsive(mobile: 56, tablet: 64, desktop: 72),
                      height: context.responsive(mobile: 56, tablet: 64, desktop: 72),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: context.responsive(mobile: 28, tablet: 32, desktop: 36),
                      ),
                    ),
                    SizedBox(width: context.responsive(mobile: 16, tablet: 20, desktop: 24)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: context.responsiveFont(16),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2,
                              color: const Color(0xFF3D322B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: context.responsiveFont(12),
                              color: _warmTaupe.withValues(alpha: 0.6),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (context.isDesktop)
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: _deepTerracotta.withValues(alpha: 0.6),
                        size: 28,
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
}