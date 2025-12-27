import 'package:flutter/material.dart';

/// Utilitaire pour gérer la responsivité de l'application
class ResponsiveHelper {
  /// Vérifie si l'écran est de taille mobile (< 600px)
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  /// Vérifie si l'écran est de taille tablette (600-1024px)
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  /// Vérifie si l'écran est de taille desktop (>= 1024px)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  /// Retourne une valeur selon la taille d'écran
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Padding responsive standard
  static double responsivePadding(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
  }

  /// Taille de police responsive
  static double responsiveFontSize(BuildContext context, double baseSize) {
    return responsiveValue(
      context,
      mobile: baseSize,
      tablet: baseSize * 1.1,
      desktop: baseSize * 1.2,
    );
  }

  /// Largeur maximale du contenu pour centrer sur grand écran
  static double maxContentWidth(BuildContext context) {
    return responsiveValue(
      context,
      mobile: double.infinity,
      tablet: 600.0,
      desktop: 800.0,
    );
  }

  /// Nombre de colonnes pour une grille
  static int gridColumns(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }
}

/// Widget responsive qui adapte automatiquement son layout
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 600) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Extension pour faciliter l'utilisation de la responsivité
extension ResponsiveExtension on BuildContext {
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  
  double get responsivePadding => ResponsiveHelper.responsivePadding(this);
  double get maxContentWidth => ResponsiveHelper.maxContentWidth(this);
  int get gridColumns => ResponsiveHelper.gridColumns(this);
  
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    return ResponsiveHelper.responsiveValue(
      this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
  
  double responsiveFont(double baseSize) {
    return ResponsiveHelper.responsiveFontSize(this, baseSize);
  }
}