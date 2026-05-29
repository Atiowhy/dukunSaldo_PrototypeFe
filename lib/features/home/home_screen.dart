import 'package:dukunsaldo_fe/data/transactions_data.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/features/auth/login.dart';
import 'package:dukunsaldo_fe/models/transactions_model.dart';
import 'package:flutter/material.dart';

// import '../../models/advisor_model.dart';
import '../advisor/advisor_screen.dart';
import '../recomendation/recomendation_screen.dart';

class HomePage extends StatefulWidget {
  // static const String routeName = "/home";
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isOn = false;
  String? selectedDropdown;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logOut() async {
    await Preference.logOut();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  String formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  final List<String> kategoryList = [
    "Pengeluaran",
    "Pemasukkan",
    "Tabungan",
    "Investasi",
  ];

  @override
  Widget build(BuildContext context) {
    // ── Dipindah ke dalam build() agar ikut rebuild saat setState ──
    final List<Widget> pages = [
      _buildHomeContent(),
      const AdvisorPage(),
      const RecommendationPage(),
    ];

    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String userEmail = args?['email'] ?? "Guest";
    final String userCity = args?['city'] ?? "Anywhere";

    return Scaffold(
      backgroundColor: isOn ? const Color(0xff051424) : const Color(0xffF8F9FA),

      appBar: AppBar(
        title: Text(
          userEmail,
          style: TextStyle(
            color: isOn ? const Color(0xff6BFB9A) : const Color(0xff041627),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isOn
            ? const Color(0xff0D1C2D)
            : const Color(0xffF8F9FA),
        iconTheme: IconThemeData(
          color: isOn ? const Color(0xff6BFB9A) : const Color(0xff041627),
        ),
        actions: [
          Icon(
            Icons.notifications_active,
            color: isOn ? const Color(0xff6BFB9A) : const Color(0xff041627),
          ),
          const SizedBox(width: 16),
        ],
      ),

      drawer: Drawer(
        backgroundColor: isOn ? const Color(0xff0D1C2D) : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isOn ? const Color(0xff051424) : const Color(0xff1A2B3C),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.asset(
                      "assets/images/logo.png",
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.account_circle,
                        size: 60,
                        color: isOn ? const Color(0xff6BFB9A) : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userEmail,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userCity,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.home,
                color: isOn ? const Color(0xff6BFB9A) : const Color(0xff041627),
              ),
              title: Text(
                "Beranda",
                style: TextStyle(color: isOn ? Colors.white : Colors.black87),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: isOn ? const Color(0xff6BFB9A) : const Color(0xff041627),
              ),
              title: Text(
                "Pengaturan",
                style: TextStyle(color: isOn ? Colors.white : Colors.black87),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(
                Icons.logout_outlined,
                color: isOn ? const Color(0xff6BFB9A) : const Color(0xff041627),
              ),
              title: Text(
                "Logout",
                style: TextStyle(color: isOn ? Colors.white : Colors.black87),
              ),
              onTap: _logOut,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 24),
              child: Row(
                children: [
                  Switch(
                    value: isOn,
                    onChanged: (bool? value) {
                      setState(() {
                        isOn = value ?? false;
                      });
                    },
                  ),
                  Text(
                    isOn ? "Light Mode" : "Dark Mode",
                    style: TextStyle(
                      color: isOn
                          ? const Color(0xff6BFB9A)
                          : const Color(0xff041627),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: IndexedStack(index: _selectedIndex, children: pages),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "List Map"),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: "List Model",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline),
            label: "Rekomendasi",
          ),
        ],
        currentIndex: _selectedIndex,
        unselectedItemColor: Colors.white54,
        selectedItemColor: const Color(0xff6BFB9A),
        onTap: _onItemTapped,
        backgroundColor: const Color(0xff0D1C2D),
      ),
    ); // Scaffold
  }

  Widget _buildHomeContent() {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String userEmail = args?['email'] ?? "Guest";
    final String userCity = args?['city'] ?? "Anywhere";
    return SingleChildScrollView(
      child: Column(
        children: [
          Text("Selamat Datang $userEmail dari $userCity"),
          // ── Kartu Saldo ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              height: 204,
              decoration: BoxDecoration(
                color: isOn ? const Color(0xff6BFB9A) : const Color(0xff1A2B3C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Saldo Saat Ini",
                      style: TextStyle(
                        color: isOn
                            ? const Color(0xff005E2D)
                            : const Color(0xffB7C8DE),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rp. 500.000.000",
                      style: TextStyle(
                        color: isOn
                            ? const Color(0xff005E2D)
                            : const Color(0xffFFFFFF),
                        fontWeight: FontWeight.w500,
                        fontSize: 40,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(
              left: 24,
              bottom: 16,
              top: 16,
              right: 24,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Riwayat Transaksi",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isOn ? Colors.black : Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 4),
                    Text(
                      "25 Mei 2026",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: kategoryList.map((kategori) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        kategori,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final trx = transactions[index];
                final bool isIncome = trx.type == TransactionType.income;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isOn
                        ? const Color(0xff1A2B3C)
                        : const Color(0xffFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isIncome
                                ? Icons.arrow_circle_down
                                : Icons.shopping_bag_outlined,
                            size: 38,
                            color: isIncome
                                ? const Color(0xff6BFB9A)
                                : (isOn ? Colors.white70 : Colors.black87),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trx.merchantName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isOn ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                trx.category,
                                style: TextStyle(
                                  color: isOn ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        "${isIncome ? '+' : '-'} Rp. ${formatRupiah(trx.amount.toInt())}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,

                          color: isIncome
                              ? (isOn ? const Color(0xff6BFB9A) : Colors.green)
                              : (isOn ? Color(0xffBA1A1A) : Color(0xffBA1A1A)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ); // SingleChildScrollView
  }
}
