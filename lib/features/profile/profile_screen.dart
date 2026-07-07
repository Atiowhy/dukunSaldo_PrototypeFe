import 'dart:convert';

import 'package:dukunsaldo_fe/core/constants/app_colors.dart';
import 'package:dukunsaldo_fe/database/db_helper.dart';
import 'package:dukunsaldo_fe/database/firebase_db_helper.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/features/auth/login.dart';
import 'package:dukunsaldo_fe/models/model_users.dart';
import 'package:dukunsaldo_fe/service/firebase_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  bool _isLoading = false;
  String _currentName = '';
  String _currentPhotoUrl = '';
  final ImagePicker _picker = ImagePicker();

  double _currentSaved = 0;
  double _savingsTarget = 5000000;
  double _thisMonthSavings = 0;
  double _progressPercent = 0;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _currentName = Preference.username;
    _currentPhotoUrl = Preference.photoUrl;
    _nameController.text = _currentName;
    _loadSavingsData();
  }

  Future<void> _loadSavingsData() async {
    try {
      final transactions = await FirebaseDbHelper.instance
          .getTransactionsByUserId(Preference.userId);
      double totalIncome = 0;
      double totalExpense = 0;
      double thisMonthIncome = 0;
      double thisMonthExpense = 0;

      final now = DateTime.now();

      for (var t in transactions) {
        final amount = t.amount;
        final isIncome = t.type == 'income';
        final date = DateTime.tryParse(t.date) ?? now;

        if (isIncome)
          totalIncome += amount;
        else
          totalExpense += amount;

        if (date.year == now.year && date.month == now.month) {
          if (isIncome)
            thisMonthIncome += amount;
          else
            thisMonthExpense += amount;
        }
      }

      final currentSaved = totalIncome - totalExpense;
      // Target diambil dinamis dari pengaturan pengguna (default 5.000.000)
      double target = Preference.savingsTarget;

      double progress = currentSaved / target;
      if (progress < 0) progress = 0;
      if (progress > 1) progress = 1;

      if (mounted) {
        setState(() {
          _currentSaved = currentSaved;
          _savingsTarget = target;
          _thisMonthSavings = thisMonthIncome - thisMonthExpense;
          _progressPercent = progress;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  String _formatRp(double value) {
    String sign = value < 0 ? "-" : "";
    String numStr = value
        .abs()
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return "$sign Rp $numStr";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Nama tidak boleh kosong")));
      return;
    }

    final newTargetRaw = _targetController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final newTarget = double.tryParse(newTargetRaw) ?? Preference.savingsTarget;

    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.query(
        "users",
        where: 'id = ?',
        whereArgs: [Preference.userId],
      );

      if (results.isEmpty) {
        throw Exception("User tidak ditemukan");
      }

      final existingUser = UserModelSql.fromMap(results.first);

      final user = UserModelSql(
        id: Preference.userId,
        username: newName,
        email: existingUser.email,
        password: existingUser.password,
      );

      final success = await DatabaseHelper.instance.updateUser(user);

      if (success) {
        // Sync to Firebase (Name only here, photo is synced directly when picked)
        await FirebaseAuthService().updateUserProfile(newName: newName);
        await Preference.setUsername(newName);
        await Preference.setSavingsTarget(newTarget);
        if (mounted) {
          setState(() {
            _currentName = newName;
            _savingsTarget = newTarget;
          });
          _loadSavingsData(); // Reload progress
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profil berhasil diperbarui"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Close dialog
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Gagal memperbarui profil"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080, // HD Quality limit to avoid 1MB Firestore limit
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() => _isLoading = true);

      // Convert to base64
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);

      // Sync to Firebase and Local
      await FirebaseAuthService().updateUserProfile(newPhotoUrl: base64String);
      await Preference.setPhotoUrl(base64String);

      if (mounted) {
        setState(() {
          _currentPhotoUrl = base64String;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Foto Profil berhasil diperbarui"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memperbarui foto: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(
                'Pilih dari Galeri',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(
                'Ambil Foto Kamera',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    _nameController.text = _currentName;
    _targetController.text = _savingsTarget.toInt().toString();
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;
        final primaryAccent = isDarkMode
            ? AppColors.darkPrimaryButtonColor
            : AppColors.lightPrimaryButtonColor;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "Edit Profil",
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Nama Panggilan",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: theme.primaryColor),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryAccent, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Target Tabungan (Rp)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: theme.primaryColor),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryAccent, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Batal", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setStateDialog(() {
                            _isLoading = true;
                          });
                          _updateProfile().then((_) {
                            if (mounted)
                              setStateDialog(() {
                                _isLoading = false;
                              });
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleLogout() async {
    await Preference.logOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Login()),
      (route) => false,
    );
  }

  Widget _buildListTile(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        ),
        child: Icon(icon, color: iconColor ?? theme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color,
          fontSize: 12,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: theme.dividerColor, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final primaryAccent = isDarkMode
        ? AppColors.darkPrimaryButtonColor
        : AppColors.lightPrimaryButtonColor;

    final onPrimaryAccent = isDarkMode ? Colors.black : Colors.white;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/images/logo.png",
              height: 28,
              errorBuilder: (c, e, s) =>
                  Icon(Icons.account_balance_wallet, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text(
              "Dukun Saldo",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Column(
          children: [
            // Banner, User Avatar, and User Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 120, bottom: 70),
              decoration: BoxDecoration(
                color: primaryAccent.withOpacity(0.2),
                image: DecorationImage(
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(
                      0.6,
                    ), // Slightly darker for text readability
                    BlendMode.darken,
                  ),
                  image: _currentPhotoUrl.isNotEmpty
                      ? (_currentPhotoUrl.startsWith('http')
                            ? NetworkImage(_currentPhotoUrl)
                            : MemoryImage(base64Decode(_currentPhotoUrl))
                                  as ImageProvider)
                      : const AssetImage("assets/images/orang.jpg"),
                ),
              ),
              child: Column(
                children: [
                  // User Avatar
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white24,
                          backgroundImage: _currentPhotoUrl.isNotEmpty
                              ? (_currentPhotoUrl.startsWith('http')
                                    ? NetworkImage(_currentPhotoUrl)
                                    : MemoryImage(
                                            base64Decode(_currentPhotoUrl),
                                          )
                                          as ImageProvider)
                              : const AssetImage("assets/images/orang.jpg")
                                    as ImageProvider,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: onPrimaryAccent,
                          ),
                        ),
                      ),
                    ], // close inner Stack children
                  ), // close inner Stack
                  const SizedBox(height: 16),

                  // User Info
                  Text(
                    _currentName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Padding wrapper for the rest of the content, moved up to overlap the banner
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Progres Tabungan Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.savings,
                                color: primaryAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "PROGRES TABUNGAN",
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isLoadingData
                                          ? "..."
                                          : "${(_progressPercent * 100).toStringAsFixed(0)}% ke Target",
                                      style: TextStyle(
                                        color: theme.primaryColor,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isLoadingData
                                          ? "Memuat data..."
                                          : "Dana Terkumpul: ${_formatRp(_currentSaved)} / ${_formatRp(_savingsTarget)}",
                                      style: TextStyle(
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isLoadingData
                                    ? ""
                                    : "${_thisMonthSavings >= 0 ? '+' : ''}${_formatRp(_thisMonthSavings)}",
                                style: TextStyle(
                                  color: _thisMonthSavings >= 0
                                      ? primaryAccent
                                      : Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Stack(
                            children: [
                              Container(
                                height: 8,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return Container(
                                    height: 8,
                                    width:
                                        constraints.maxWidth *
                                        _progressPercent, // Dinamis!
                                    decoration: BoxDecoration(
                                      color: primaryAccent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Pengaturan Akun Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "PENGATURAN AKUN",
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildListTile(
                      theme,
                      Icons.person_outline,
                      "Informasi Pribadi",
                      "Perbarui detail profil dan KYC Anda",
                      onTap: _showEditProfileDialog,
                    ),
                    _buildListTile(
                      theme,
                      Icons.lock_outline,
                      "Keamanan & PIN",
                      "Protokol biometrik dan 2FA",
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 32),
                      child: TextButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        label: const Text(
                          "Keluar",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ), // close TextButton
                    ), // close SizedBox
                  ], // close inner Column children
                ), // close inner Column
              ), // close Padding
            ), // close Transform
          ], // close outer Column children
        ), // close outer Column
      ), // close SingleChildScrollView
    ); // close Scaffold
  }
}
