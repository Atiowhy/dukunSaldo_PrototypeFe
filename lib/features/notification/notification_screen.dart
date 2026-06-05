import 'package:dukunsaldo_fe/database/db_helper.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/models/log_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final logs = await DatabaseHelper.instance.getLogsByUserId(Preference.userId);
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
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Belum ada notifikasi",
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Semua aktivitas dan peringatan\nakan muncul di sini.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: _buildIcon(log.type, theme),
                        title: Text(
                          log.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              log.message,
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDate(log.date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
