import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScanVault {
  static List<Map<String, dynamic>> savedScans = [];

  static Future<void> loadScans() async {
    final prefs = await SharedPreferences.getInstance();
    final String? scansString = prefs.getString('kuber_saved_scans');
    if (scansString != null) {
      final List<dynamic> decoded = jsonDecode(scansString);
      savedScans = decoded.map((e) => e as Map<String, dynamic>).toList();
    }
  }

  static Future<void> saveScan(Map<String, dynamic> newScan) async {
    // Prevent duplicates by checking date
    final int index = savedScans.indexWhere((scan) => scan['scan_date'] == newScan['scan_date']);
    if (index == -1) {
      newScan['scan_date'] ??= DateTime.now().toString().substring(0, 16);
      savedScans.add(newScan);
      await _persist();
    }
  }

  static Future<void> deleteScan(String dateId) async {
    savedScans.removeWhere((scan) => scan['scan_date'] == dateId);
    await _persist();
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kuber_saved_scans', jsonEncode(savedScans));
  }
}