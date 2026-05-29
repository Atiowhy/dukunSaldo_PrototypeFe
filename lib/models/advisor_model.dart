import 'package:flutter/material.dart';

// Enum untuk menentukan tipe/prioritas saran
enum AdviceType { urgent, optimasi, growth }

// Class Model untuk Advisor
class AdviceModel {
  final String id;
  final IconData icon;
  final String title;
  final AdviceType type;
  final String description;
  final String primaryButtonText;
  final String secondaryButtonText;

  AdviceModel({
    required this.id,
    required this.icon,
    required this.title,
    required this.type,
    required this.description,
    required this.primaryButtonText,
    required this.secondaryButtonText,
  });

  // Helper function untuk mengambil warna berdasarkan Tipe
  Color getColor() {
    switch (type) {
      case AdviceType.urgent:
        return const Color(0xFFE57373); // Merah
      case AdviceType.optimasi:
        return const Color(0xFF64B5F6); // Biru
      case AdviceType.growth:
        return const Color(0xFF81C784); // Hijau
    }
  }

  // Helper function untuk mengambil teks label tipe
  String getTypeName() {
    switch (type) {
      case AdviceType.urgent:
        return "Urgent";
      case AdviceType.optimasi:
        return "Optimasi";
      case AdviceType.growth:
        return "Growth";
    }
  }
}
