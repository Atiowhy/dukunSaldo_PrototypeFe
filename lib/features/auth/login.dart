import 'package:dukunsaldo_fe/core/constants/app_assets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  late TapGestureRecognizer _registerTapRecognizer;

  @override
  void initState() {
    super.initState();
    // 👇 2. Inisialisasi fungsi kliknya di sini
    _registerTapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        print("Pergi ke halaman Register");
        // Nanti kode Navigator ke RegisterScreen ditaruh di sini
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
                                Text("Email", style: theme.textTheme.bodyLarge),
                                SizedBox(height: 16),
                                CustomTextField(
                                  labelText: "Email",
                                  hintText: "Masukkan Email Anda",
                                  prefixIcon: Icons.email,
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
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
                            SizedBox(height: 16),

                            CustomButton(
                              prefixIcon: Icons.arrow_forward,
                              text: "MASUK",
                              isLoading: _isLoading,

                              onPressed: () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                print(
                                  "Mencoba login dengan Email: ${_emailController.text}",
                                );
                                await Future.delayed(
                                  const Duration(seconds: 2),
                                );
                                setState(() {
                                  _isLoading = false;
                                });
                              },
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
