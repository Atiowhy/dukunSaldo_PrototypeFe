import 'package:dukunsaldo_fe/database/db_helper.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/features/auth/login.dart';
import 'package:dukunsaldo_fe/models/model_users.dart';
import 'package:dukunsaldo_fe/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String _currentName = '';

  double _currentSaved = 0;
  double _savingsTarget = 5000000;
  double _thisMonthSavings = 0;
  double _progressPercent = 0;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _currentName = Preference.username;
    _nameController.text = _currentName;
    _loadSavingsData();
  }

  Future<void> _loadSavingsData() async {
    try {
      final transactions = await DatabaseHelper.instance
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
      // Target dinamis: kelipatan 5 juta terdekat di atas saldo saat ini
      double target = ((currentSaved ~/ 5000000) + 1) * 5000000.0;
      if (target <= 0) target = 5000000.0; // Minimal target

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
        await Preference.setUsername(newName);
        if (mounted) {
          setState(() {
            _currentName = newName;
          });
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

  void _showEditProfileDialog() {
    _nameController.text = _currentName;
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.primaryColor,
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
                  Icon(Icons.account_balance_wallet, color: primaryAccent),
            ),
            const SizedBox(width: 8),
            Text(
              "Dukun Saldo",
              style: TextStyle(
                color: theme.primaryColor,
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
            icon: Icon(Icons.notifications_none, color: theme.primaryColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            // User Info
            Text(
              _currentName,
              style: TextStyle(
                color: theme.primaryColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

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
                      Icon(Icons.savings, color: primaryAccent, size: 18),
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
                                color: theme.textTheme.bodyMedium?.color,
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
            _buildListTile(
              theme,
              Icons.workspace_premium_outlined,
              "Manajemen Langganan",
              "Fitur AI Advisor dan Pro",
            ),
            _buildListTile(
              theme,
              Icons.notifications_outlined,
              "Pengaturan Notifikasi",
              "Kelola laporan dan peringatan EWS",
            ),
            _buildListTile(
              theme,
              Icons.headset_mic_outlined,
              "Bantuan & Dukungan",
              "FAQ dan layanan chat bantuan",
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
