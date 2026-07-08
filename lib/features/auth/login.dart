import 'package:dukunsaldo_fe/core/constants/app_assets.dart';
import 'package:dukunsaldo_fe/database/db_helper.dart';
import 'package:dukunsaldo_fe/database/firebase_db_helper.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
// import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/features/auth/register.dart';
import 'package:dukunsaldo_fe/features/home/home_screen.dart';
import 'package:dukunsaldo_fe/models/log_model.dart';
// import 'package:dukunsaldo_fe/features/home/home_screen.dart';
import 'package:dukunsaldo_fe/models/model_users.dart';
import 'package:dukunsaldo_fe/service/firebase_auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

//lupa kata sandi di kecilin lalu letakkan dibawah kolom password
//term and conditions

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // final TextEditingController _cityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void login() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text;

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Isi semua field!')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = FirebaseAuthService();
    final pengguna = await authService.signIn(email, pass);

    if (pengguna != null) {
      // Sync user to local database so foreign keys work!
      await DatabaseHelper.instance.registerUser(
        UserModelSql(
          id: pengguna.id,
          username: pengguna.username,
          email: pengguna.email,
          password: pengguna.password,
        ),
      );
    }

    // Cek apakah widget masih terpasang (mounted) sebelum menggunakan context
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (pengguna != null) {
      await Preference.saveUserSession(
        pengguna.id!,
        pengguna.username,
        pengguna.email,
        pengguna.photoUrl,
      );

      final logData = LogModel(
        userId: pengguna.id!,
        title: "Login Berhasil",
        message: "Selamat datang kembali, ${pengguna.username}!",
        date: DateTime.now().toIso8601String(),
        type: 'system',
      );
      await DatabaseHelper.instance.insertLog(logData);
      await FirebaseDbHelper.instance.insertLog(logData);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login gagal! email atau Password salah.'),
        ),
      );
    }
  }

  late TapGestureRecognizer _registerTapRecognizer;

  @override
  void initState() {
    super.initState();

    _registerTapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Register()),
        );
      };
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _registerTapRecognizer.dispose();
    super.dispose();
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
                              "Selamat Datang Kembali",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Masuk ke akun Anda untuk memantau prediksi keuangan",
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
                                            Text(
                                              "Lupa Kata Sandi?",
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
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            CustomButton(
                              prefixIcon: Icons.arrow_forward,
                              text: "MASUK",
                              isLoading: _isLoading,

                              onPressed: login,
                            ),

                            SizedBox(height: 24),

                            Center(
                              child: Text.rich(
                                TextSpan(
                                  text: 'Belum punya akun? ',
                                  style: theme.textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text: 'Daftar',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryColor,
                                          ),

                                      recognizer: _registerTapRecognizer,
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
