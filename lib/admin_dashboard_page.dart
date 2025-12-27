import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'responsive_utils.dart';
import 'config.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  bool loading = false;

  // 🎨 Palette de couleurs
  final Color _deepTerracotta = const Color(0xFFB6745E);
  final Color _warmClay = const Color(0xFFD3A588);
  final Color _mutedRose = const Color(0xFFC99A9A);
  final Color _oliveMoss = const Color(0xFF9BA17B);
  final Color _warmTaupe = const Color(0xFF8C6E63);
  final Color _amberDust = const Color(0xFFC7A16B);
  final Color _backgroundBeige = const Color(0xFFEEE3D6);

 static const String backendUrl = AppConfig.backendUrl;

  String _randomPassword(int length) {
    const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final rnd = Random();
    return String.fromCharCodes(
      List.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> _createStudent() async {
    if (firstNameCtrl.text.trim().isEmpty || lastNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Veuillez remplir prénom et nom"),
          backgroundColor: Colors.red.withValues(alpha: 0.8),
        ),
      );
      return;
    }

    setState(() => loading = true);
    final first = firstNameCtrl.text.trim().toLowerCase();
    final last = lastNameCtrl.text.trim().toLowerCase();
    final email = "$first.$last@eleve.com";
    final password = _randomPassword(8);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'email': email,
        'firstName': firstNameCtrl.text.trim(),
        'lastName': lastNameCtrl.text.trim(),
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      firstNameCtrl.clear();
      lastNameCtrl.clear();

      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => _buildStyledDialog(
          title: "✅ Élève créé avec succès",
          content: "L'élève a été ajouté à la base de données.\n\n"
              "📧 Email:\n$email\n\n"
              "🔑 Mot de passe:\n$password\n\n"
              "💡 Notez ces identifiants et communiquez-les à l'élève.",
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: "Email: $email\nMot de passe: $password"),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Identifiants copiés !"),
                    backgroundColor: _oliveMoss,
                  ),
                );
              },
              child: Text(
                "Copier",
                style: TextStyle(color: _deepTerracotta),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "OK",
                style: TextStyle(color: _deepTerracotta),
              ),
            ),
          ],
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Élève créé avec succès!"),
          backgroundColor: _oliveMoss,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur : $e"),
          backgroundColor: Colors.red.withValues(alpha: 0.8),
        ),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _deleteStudent(String uid, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildStyledDialog(
        title: "Confirmer la suppression",
        content: "Voulez-vous vraiment supprimer l'élève $email ?\n\n"
            "⚠️ Cette action est irréversible.\n"
            "Le compte sera supprimé de Firebase Auth ET Firestore.",
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Annuler",
              style: TextStyle(color: _warmTaupe),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Supprimer",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      try {
        final response = await http.post(
          Uri.parse('$backendUrl/admin/delete_student'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'uid': uid}),
        );

        if (!mounted) return;
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("✅ Élève supprimé complètement"),
              backgroundColor: _oliveMoss,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("⚠️ Supprimé partiellement: ${response.body}"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("⚠️ Supprimé de Firestore uniquement"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _resetPassword(String uid, String email) async {
    final newPassword = _randomPassword(8);
    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/admin/reset_password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'password': newPassword}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => _buildStyledDialog(
            title: "✅ Mot de passe modifié",
            content: "Le mot de passe de $email a été changé avec succès !\n\n"
                "🔑 Nouveau mot de passe:\n$newPassword\n\n"
                "💡 Notez-le et communiquez-le à l'élève.",
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: newPassword));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Mot de passe copié !"),
                      backgroundColor: _oliveMoss,
                    ),
                  );
                },
                child: Text("Copier", style: TextStyle(color: _deepTerracotta)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK", style: TextStyle(color: _deepTerracotta)),
              ),
            ],
          ),
        );
      } else {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        showDialog(
          context: context,
          builder: (context) => _buildStyledDialog(
            title: "📧 Email envoyé",
            content: "Email de réinitialisation envoyé à $email\n\n"
                "💡 Mot de passe suggéré:\n$newPassword",
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK", style: TextStyle(color: _deepTerracotta)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => _buildStyledDialog(
            title: "📧 Email envoyé (fallback)",
            content: "Email de réinitialisation envoyé.\n\n"
                "💡 Mot de passe suggéré:\n$newPassword",
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK", style: TextStyle(color: _deepTerracotta)),
              ),
            ],
          ),
        );
      } catch (emailError) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Erreur: $emailError"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  void _showAddStudentDialog() {
    firstNameCtrl.clear();
    lastNameCtrl.clear();

    showDialog(
      context: context,
      builder: (dialogContext) => _buildStyledDialog(
        title: "Ajouter un élève",
        content: null,
        customContent: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(
              controller: firstNameCtrl,
              label: "Prénom",
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildDialogTextField(
              controller: lastNameCtrl,
              label: "Nom",
              icon: Icons.person_outline,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Annuler", style: TextStyle(color: _warmTaupe)),
          ),
          TextButton(
            onPressed: loading
                ? null
                : () async {
                    Navigator.pop(dialogContext);
                    await _createStudent();
                  },
            child: Text(
              "Créer",
              style: TextStyle(
                color: loading ? _warmTaupe.withValues(alpha: 0.3) : _deepTerracotta,
              ),
            ),
          ),
        ],
      ),
    );
  }

// SUITE DE LA PARTIE 1...

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
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'student')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Erreur : ${snapshot.error}",
                          style: TextStyle(color: _warmTaupe),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(_amberDust),
                        ),
                      );
                    }

                    final students = snapshot.data?.docs ?? [];
                    
                    students.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final aTime = aData['createdAt'] as Timestamp?;
                      final bTime = bData['createdAt'] as Timestamp?;
                      
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;
                      
                      return bTime.compareTo(aTime);
                    });

                    if (students.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_rounded,
                              size: 80,
                              color: _warmTaupe.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Aucun élève enregistré",
                              style: TextStyle(
                                fontSize: context.responsiveFont(18),
                                color: _warmTaupe.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 30),
                            _buildAddButton(),
                          ],
                        ),
                      );
                    }

                    return ResponsiveBuilder(
                      mobile: _buildMobileList(students),
                      tablet: _buildTabletGrid(students),
                      desktop: _buildDesktopGrid(students),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<QueryDocumentSnapshot> students) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.responsivePadding,
            16,
            context.responsivePadding,
            16,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Liste des élèves (${students.length})",
                  style: TextStyle(
                    fontSize: context.responsiveFont(18),
                    fontWeight: FontWeight.w500,
                    color: _warmTaupe,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _buildAddButton(),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final doc = students[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildStudentCard(
                uid: doc.id,
                email: data['email'] ?? '',
                firstName: data['firstName'] ?? '',
                lastName: data['lastName'] ?? '',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabletGrid(List<QueryDocumentSnapshot> students) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.responsivePadding,
            16,
            context.responsivePadding,
            16,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Liste des élèves (${students.length})",
                  style: TextStyle(
                    fontSize: context.responsiveFont(18),
                    fontWeight: FontWeight.w500,
                    color: _warmTaupe,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _buildAddButton(),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final doc = students[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildStudentCard(
                uid: doc.id,
                email: data['email'] ?? '',
                firstName: data['firstName'] ?? '',
                lastName: data['lastName'] ?? '',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopGrid(List<QueryDocumentSnapshot> students) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.responsivePadding,
            16,
            context.responsivePadding,
            16,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Liste des élèves (${students.length})",
                  style: TextStyle(
                    fontSize: context.responsiveFont(20),
                    fontWeight: FontWeight.w500,
                    color: _warmTaupe,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _buildAddButton(),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final doc = students[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildStudentCard(
                uid: doc.id,
                email: data['email'] ?? '',
                firstName: data['firstName'] ?? '',
                lastName: data['lastName'] ?? '',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.responsivePadding,
        16,
        context.responsivePadding,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.responsive(mobile: 48, tablet: 52, desktop: 56),
                height: context.responsive(mobile: 48, tablet: 52, desktop: 56),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_deepTerracotta, _amberDust],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _deepTerracotta.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: context.responsive(mobile: 24, tablet: 26, desktop: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ADMIN',
                      style: TextStyle(
                        fontSize: context.responsiveFont(24),
                        fontWeight: FontWeight.w300,
                        letterSpacing: 5,
                        color: _deepTerracotta,
                      ),
                    ),
                    Text(
                      'Tableau de bord',
                      style: TextStyle(
                        fontSize: context.responsiveFont(12),
                        color: _warmTaupe.withValues(alpha: 0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: Icon(
                  Icons.logout_rounded,
                  color: _deepTerracotta,
                  size: context.responsive(mobile: 24, tablet: 26, desktop: 28),
                ),
                tooltip: "Déconnexion",
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
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
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [_deepTerracotta, _amberDust],
        ),
        boxShadow: [
          BoxShadow(
            color: _deepTerracotta.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _showAddStudentDialog,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          "Ajouter",
          style: TextStyle(fontSize: context.responsiveFont(14)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive(mobile: 16, tablet: 20, desktop: 24),
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }



  Widget _buildStudentCard({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _warmClay.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _warmTaupe.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(
                  context.responsive(mobile: 16, tablet: 18, desktop: 20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: context.responsive(mobile: 44, tablet: 48, desktop: 52),
                      height: context.responsive(mobile: 44, tablet: 48, desktop: 52),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [_oliveMoss, _warmClay],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          firstName.isNotEmpty
                              ? firstName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.responsiveFont(18),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$firstName $lastName",
                            style: TextStyle(
                              fontSize: context.responsiveFont(15),
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF3D322B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: context.responsiveFont(12),
                              color: _warmTaupe.withValues(alpha: 0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: _deepTerracotta,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'reset':
                            _resetPassword(uid, email);
                            break;
                          case 'delete':
                            _deleteStudent(uid, email);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'reset',
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_reset_rounded,
                                size: 20,
                                color: _oliveMoss,
                              ),
                              const SizedBox(width: 12),
                              const Text("Modifier mot de passe"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                size: 20,
                                color: Colors.red,
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Supprimer",
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildStyledDialog({
    required String title,
    String? content,
    Widget? customContent,
    required List<Widget> actions,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: context.responsive(mobile: 400, tablet: 500, desktop: 600),
            ),
            decoration: BoxDecoration(
              color: _backgroundBeige.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _warmClay.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _warmTaupe.withValues(alpha: 0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.responsiveFont(20),
                    fontWeight: FontWeight.w500,
                    color: _deepTerracotta,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                if (content != null)
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: context.responsiveFont(14),
                      color: _warmTaupe,
                      height: 1.5,
                    ),
                  ),
                if (customContent != null) customContent,
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _warmClay.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: const Color(0xFF3D322B),
              fontSize: context.responsiveFont(14),
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: _warmTaupe.withValues(alpha: 0.6),
                fontSize: context.responsiveFont(13),
              ),
              prefixIcon: Icon(icon, color: _deepTerracotta, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    super.dispose();
  }
}

