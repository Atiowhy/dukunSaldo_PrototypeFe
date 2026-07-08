import 'package:dukunsaldo_fe/database/db_helper.dart';
import 'package:dukunsaldo_fe/database/firebase_db_helper.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/models/log_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  List<LogModel> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    final logs = await FirebaseDbHelper.instance.getLogsByUserId(Preference.userId);
    logs.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  Widget _buildIcon(String type, ThemeData theme) {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (type) {
      case 'income':
        iconData = Icons.arrow_downward;
        iconColor = const Color(0xFF00875A); // Green
        bgColor = const Color(0xFF00875A).withOpacity(0.15);
        break;
      case 'expense':
        iconData = Icons.arrow_upward;
        iconColor = theme.colorScheme.error; // Red
        bgColor = theme.colorScheme.error.withOpacity(0.15);
        break;
      case 'system':
      default:
        iconData = Icons.info_outline;
        iconColor = const Color(0xFF4C9AFF); // Blue
        bgColor = const Color(0xFF4C9AFF).withOpacity(0.15);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatMessage(String message) {
    return message.replaceAllMapped(RegExp(r'Rp\s*(\d+)(?:\.\d+)?'), (match) {
      final amount = int.tryParse(match.group(1) ?? '0') ?? 0;
      final formatted = amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      return 'Rp $formatted';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Notifikasi",
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_paused,
                          size: 64,
                          color: theme.dividerColor,
                        ),
                      ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 2000.ms, color: theme.primaryColor.withOpacity(0.3)),
                      const SizedBox(height: 24),
                      Text(
                        "Belum ada notifikasi",
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fade(duration: 600.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 8),
                      Text(
                        "Semua aktivitas dan peringatan\nakan muncul di sini.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ).animate().fade(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    
                    Color accentColor;
                    if (log.type == 'income') {
                      accentColor = const Color(0xFF00875A);
                    } else if (log.type == 'expense') {
                      accentColor = theme.colorScheme.error;
                    } else {
                      accentColor = const Color(0xFF4C9AFF);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: accentColor, width: 4),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: _buildIcon(log.type, theme),
                            title: Text(
                              log.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  _formatMessage(log.message),
                                  style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _formatDate(log.date),
                                  style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fade(duration: 400.ms, delay: (50 * index).ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
                  },
                ),
    );
  }
}
