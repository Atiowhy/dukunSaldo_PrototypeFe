import 'package:dukunsaldo_fe/core/constants/app_assets.dart';
// import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/features/auth/login.dart';
// import 'package:dukunsaldo_fe/features/home/home_screen.dart';
import 'package:dukunsaldo_fe/models/user_model_firebase.dart';
import 'package:dukunsaldo_fe/service/firebase_auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _username = TextEditingController();
  // final TextEditingController _cityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isAgreedToTerms = false;

  late TapGestureRecognizer _loginTapRecognizer;
  late TapGestureRecognizer _termsTapRecognizer;
  late TapGestureRecognizer _privacyTapRecognizer;

  void register() async {
    final username = _username.text;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Isi semua field")));
      return;
    }

    if (!_isAgreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Anda harus menyetujui Syarat dan Ketentuan"),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = FirebaseAuthService();

    bool emailExists = await authService.checkEmailExist(email);
    if (emailExists) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email sudah terdaftar!')));
      return;
    }

    final user = UserModelFirebase(
      username: username,
      email: email,
      password: password,
    );

    final registeredUser = await authService.signUp(user);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (registeredUser != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Akun berhasil dibuat')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat akun, silakan coba lagi.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _loginTapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      };

    _termsTapRecognizer = TapGestureRecognizer()..onTap = _showTermsDialog;
    _privacyTapRecognizer = TapGestureRecognizer()..onTap = _showPrivacyDialog;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _username.dispose();
    _loginTapRecognizer.dispose();
    _termsTapRecognizer.dispose();
    _privacyTapRecognizer.dispose();
    super.dispose();
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Syarat & Ketentuan", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(
              "Selamat datang di Dukun Saldo.\n\n"
              "1. Layanan: Aplikasi ini ditujukan sebagai prototipe manajemen keuangan pribadi.\n"
              "2. Penggunaan: Pengguna setuju untuk tidak menyalahgunakan layanan untuk tindakan ilegal.\n"
              "3. Tanggung Jawab: Kami tidak bertanggung jawab atas kerugian finansial yang diakibatkan oleh keputusan Anda sendiri.\n"
              "4. Perubahan Syarat: Kami berhak mengubah syarat dan ketentuan sewaktu-waktu.\n\n"
              "Dengan menggunakan aplikasi ini, Anda dianggap setuju dengan syarat & ketentuan di atas.",
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Kebijakan Privasi", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(
              "Kebijakan Privasi Dukun Saldo:\n\n"
              "1. Data Pribadi: Kami mengumpulkan data dasar seperti nama dan email Anda saat pendaftaran untuk keperluan autentikasi.\n"
              "2. Keamanan: Data Anda disimpan dengan aman dan tidak akan diperjualbelikan kepada pihak ketiga.\n"
              "3. Transaksi: Data riwayat keuangan Anda dienkripsi (jika tersedia) dan hanya dapat diakses oleh Anda.\n"
              "4. Cookie & Pelacakan: Kami menggunakan sesi sementara untuk menjaga agar Anda tetap masuk.\n\n"
              "Jika Anda memiliki pertanyaan tentang privasi, silakan hubungi tim kami.",
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              // margin: EdgeInsets.only(top: 142),
              padding: EdgeInsets.all(24),
              // constraints: BoxConstraints(
              //   minHeight: MediaQuery.of(context).size.height,
              // ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(8, 8),
                          color: theme.shadowColor,
                          blurRadius: 15,
                          spreadRadius: -4,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    width: double.infinity,
                    child: Column(
                      children: [
                        // logo
                        Column(
                          children: [
                            Image.asset(AppAssets.logo2, height: 64, width: 64),
                            SizedBox(height: 8),
                            Text(
                              "Buat Akun Baru",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Mulai langkah cerdas mengeola keuangan Anda hari ini",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Nama Lengkap",
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                        SizedBox(height: 16),
                                        CustomTextField(
                                          labelText: "Nama",
                                          hintText: "Masukkan Nama Anda",
                                          prefixIcon: Icons.person,
                                          controller: _username,

                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Nama Lengkap Tidak Boleh Kosong";
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          "Email",
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                        SizedBox(height: 16),
                                        CustomTextField(
                                          labelText: "Email",
                                          hintText: "Masukkan Email Anda",
                                          prefixIcon: Icons.email,
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Email Tidak Boleh Kosong";
                                            } else if (!value.contains("@")) {
                                              return "Format Email Tidak Valid";
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Password",
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        CustomTextField(
                                          labelText: "Password",
                                          hintText: "Masukkan Password Anda",
                                          prefixIcon: Icons.lock,
                                          controller: _passwordController,
                                          isPassword: true,
                                        ),
                                        SizedBox(height: 16),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: Checkbox(
                                                value: _isAgreedToTerms,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _isAgreedToTerms =
                                                        value ?? false;
                                                  });
                                                },
                                                activeColor: theme.primaryColor,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text.rich(
                                                TextSpan(
                                                  text: "Saya menyetujui ",
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(fontSize: 13),
                                                  children: [
                                                    TextSpan(
                                                      text: "Syarat & Ketentuan",
                                                      style: TextStyle(
                                                        color: theme.primaryColor,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      recognizer: _termsTapRecognizer,
                                                    ),
                                                    TextSpan(text: " serta "),
                                                    TextSpan(
                                                      text: "Kebijakan Privasi",
                                                      style: TextStyle(
                                                        color: theme.primaryColor,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      recognizer: _privacyTapRecognizer,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            CustomButton(
                              prefixIcon: Icons.arrow_forward,
                              text: "DAFTAR",
                              isLoading: _isLoading,
                              onPressed: register,
                            ),

                            SizedBox(height: 24),

                            Center(
                              child: Text.rich(
                                TextSpan(
                                  text: 'Sudah punya akun? ',
                                  style: theme.textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text: 'Masuk',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryColor,
                                          ),

                                      recognizer: _loginTapRecognizer,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
