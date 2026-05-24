import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; 
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:kuber/providers/theme_provider.dart'; 
import '../upload/upload_screen.dart'; 
import '../loading/settings_screen.dart'; 
import '../../core/constants/app_constants.dart'; 
import '../../core/utils/scan_vault.dart' as vault;
// Import html safely for Web downloads without breaking Mobile builds
import 'package:flutter/services.dart';
import '../../core/utils/web_downloader_stub.dart' 
    if (dart.library.js_util) '../../core/utils/web_downloader.dart';
class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> analysisData;

  const DashboardScreen({super.key, required this.analysisData});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    // --- THE DYNAMIC ACCENT PALETTE ---
    final Color premiumGold = const Color(0xFFFFD700); 
    final Color richLavender = const Color(0xFF7E22CE); 
    
    final Color themeAccent = isDark ? premiumGold : richLavender;
    
    final Color textColor = isDark ? Colors.white : AppColors.textBlack;
    final Color subTextColor = isDark ? const Color(0xFFA4C2BC) : AppColors.subTextLight;
    
    final Color baseAccent = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488); 

    // Glass Cards
    final Color glassCardColor = isDark 
        ? const Color(0xFF0A3A50).withOpacity(0.65) 
        : Colors.white.withOpacity(0.85);          
        
    final Color solidCardColor = isDark 
        ? const Color(0xFF051821) 
        : Colors.white;

    final metrics = analysisData['metrics'] ?? {};
    final double totalIncome = (metrics['total_income'] ?? 0).toDouble();
    final double totalExpense = (metrics['total_expense'] ?? 0).toDouble();
    final double netSavings = (metrics['net_savings'] ?? 0).toDouble();
    final String topCategory = metrics['highest_spending_category'] ?? "None";
    final Map<String, dynamic> categoryData = analysisData['category_breakdown'] ?? {};
    final List<dynamic> transactions = analysisData['transactions'] ?? [];
    
    final String aiCommentary = analysisData['ai_recommendation'] 
                             ?? "Kuber is analyzing your habits. Try refreshing or uploading a clean statement.";

    final Map<String, List<dynamic>> groupedTransactions = {};
    for (var tx in transactions) {
      final String cat = tx['category'] ?? 'Uncategorized';
      if (!groupedTransactions.containsKey(cat)) groupedTransactions[cat] = [];
      groupedTransactions[cat]!.add(tx);
    }

    return DefaultTabController(
      length: 3, 
      child: Stack(
        children: [
          // ==========================================
          // Layer 1: BLUISH-TEAL & LAVENDER GRADIENTS
          // ==========================================
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: isDark 
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF125C7A), Color(0xFF030D14)],
                      stops: [0.0, 0.85], 
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFFFFF), Color(0xFFE9D5FF)],
                      stops: [0.1, 1.0],
                    ),
            ),
          ),
          
          _buildElegantLineDoodles(themeAccent),
          
          Scaffold(
            backgroundColor: Colors.transparent, 
            
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const UploadScreen()), 
                    (route) => false
                  );
                },
              ),
              title: Text(
                'KUBER AI', 
                style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: 20)
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent, 
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(Icons.settings_rounded, color: themeAccent),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                ),
                IconButton(
                  icon: Icon(Icons.ios_share_rounded, color: themeAccent), 
                  tooltip: "Share Financial Report",
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Generating Financial Report..."))
                    );
                    await _generateAndSharePDF(
                      context, totalIncome, totalExpense, netSavings, topCategory, aiCommentary, transactions, categoryData
                    );
                  },
                ),
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: themeAccent),
                  onPressed: () => themeProvider.toggleTheme(!isDark),
                ),
                const SizedBox(width: 8),
              ],
              
              bottom: TabBar(
                indicatorColor: themeAccent, 
                indicatorWeight: 4,
                labelColor: themeAccent,     
                unselectedLabelColor: subTextColor,
                dividerColor: Colors.transparent, 
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0),
                tabs: const [
                  Tab(icon: Icon(Icons.pie_chart_outline_rounded), text: "OVERVIEW"),
                  Tab(icon: Icon(Icons.auto_awesome_rounded), text: "AI INSIGHTS"),
                  Tab(icon: Icon(Icons.list_alt_rounded), text: "HISTORY"),
                ],
              ),
            ),

            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                if (analysisData.isEmpty) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const UploadScreen()), 
                    (route) => false
                  );
                  return;
                }

                final TextEditingController nameController = TextEditingController(
                  text: analysisData['scan_name'] ?? "Statement - ${DateTime.now().toString().substring(0, 10)}"
                );

                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: solidCardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text("Save to Vault", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    content: TextField(
                      controller: nameController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: "Vault Entry Name",
                        labelStyle: TextStyle(color: subTextColor),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: subTextColor.withOpacity(0.5))),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: themeAccent, width: 2)),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel", style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          analysisData['scan_name'] = nameController.text.trim();
                          await vault.ScanVault.saveScan(analysisData); // Assuming this is handled elsewhere or unimplemented
                          
                          if (!context.mounted) return;
                          Navigator.pop(context); 
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const UploadScreen()), 
                            (route) => false
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeAccent, 
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: const Text("Save Vault", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                );
              },
              backgroundColor: analysisData.isNotEmpty ? Colors.redAccent : themeAccent,
              icon: Icon(
                analysisData.isNotEmpty ? Icons.save_rounded : Icons.upload_file, 
                color: analysisData.isNotEmpty ? Colors.white : (isDark ? Colors.black : Colors.white)
              ),
              label: Text(
                analysisData.isNotEmpty ? "Save to Vault" : "New Scan", 
                style: TextStyle(
                  color: analysisData.isNotEmpty ? Colors.white : (isDark ? Colors.black : Colors.white), 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 1.0
                )
              ),
            ),

            body: TabBarView(
              children: [
                // TAB 1: OVERVIEW
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildMetricCard("Income", totalIncome, isDark ? Colors.greenAccent : Colors.green, glassCardColor, subTextColor, textColor, baseAccent)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMetricCard("Expenses", totalExpense, isDark ? Colors.redAccent : Colors.red, glassCardColor, subTextColor, textColor, baseAccent)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildMetricCard("Net Savings", netSavings, themeAccent, glassCardColor, subTextColor, textColor, baseAccent)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTopSpendCard(topCategory, glassCardColor, subTextColor, textColor, baseAccent)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        height: 260,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: glassCardColor, 
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: themeAccent.withOpacity(0.15)), 
                        ),
                        child: categoryData.isNotEmpty 
                          ? PieChart(PieChartData(sectionsSpace: 3, centerSpaceRadius: 40, sections: _buildPieChartSections(categoryData, textColor)))
                          : Center(child: Text("No expenses to display", style: TextStyle(color: subTextColor))),
                      ),
                      const SizedBox(height: 80), 
                    ],
                  ),
                ),

                // TAB 2: AI INSIGHTS
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Kuber's Analysis", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 16),
                      // The fully upgraded AI Insight Card
                      _buildAiInsightCard(aiCommentary, glassCardColor, themeAccent, textColor, subTextColor, baseAccent),
                    ],
                  ),
                ),

                // TAB 3: HISTORY
                ListView.builder(
                  padding: const EdgeInsets.all(16.0).copyWith(bottom: 80.0),
                  itemCount: groupedTransactions.keys.length,
                  itemBuilder: (context, index) {
                    final String category = groupedTransactions.keys.elementAt(index);
                    final List<dynamic> catTxs = groupedTransactions[category]!;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: glassCardColor, 
                        borderRadius: BorderRadius.circular(16), 
                        border: Border.all(color: baseAccent.withOpacity(0.1))
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          iconColor: themeAccent, 
                          collapsedIconColor: subTextColor,
                          leading: CircleAvatar(
                            backgroundColor: themeAccent.withOpacity(0.15),
                            child: Icon(_getCategoryIcon(category), color: themeAccent, size: 22), 
                          ),
                          title: Text(category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                          subtitle: Text("${catTxs.length} transactions", style: TextStyle(color: subTextColor, fontSize: 12)),
                          
                          children: (() {
                            final List<dynamic> debits = catTxs.where((t) => (t['debit'] ?? 0) > 0).toList();
                            final List<dynamic> credits = catTxs.where((t) => (t['credit'] ?? 0) > 0).toList();
                            List<Widget> widgets = [];

                            Widget buildTile(dynamic tx, bool isDebit) {
                              final double amount = isDebit ? (tx['debit'] ?? 0).toDouble() : (tx['credit'] ?? 0).toDouble();
                              final String txDate = tx['date'] ?? tx['timestamp'] ?? '';
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                                title: Text(tx['narration'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
                                subtitle: txDate.isNotEmpty ? Text(txDate, style: TextStyle(fontSize: 11, color: subTextColor)) : null,
                                trailing: Text(
                                  "${isDebit ? '-' : '+'}₹${amount.toStringAsFixed(2)}", 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDebit ? Colors.redAccent : Colors.green)
                                ),
                                onTap: () => _showTransactionDetails(context, tx, isDebit, amount, category, txDate, solidCardColor, textColor, subTextColor, themeAccent),
                              );
                            }

                            if (debits.isNotEmpty) {
                              widgets.add(Padding(
                                padding: const EdgeInsets.only(left: 24, top: 12, bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.arrow_downward_rounded, size: 14, color: Colors.redAccent),
                                    const SizedBox(width: 6),
                                    Text("MONEY OUT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent.withOpacity(0.8), letterSpacing: 1.0)),
                                  ]
                                ),
                              ));
                              widgets.addAll(debits.map((tx) => buildTile(tx, true)));
                            }

                            if (credits.isNotEmpty) {
                              if (debits.isNotEmpty) {
                                widgets.add(Divider(color: baseAccent.withOpacity(0.15), indent: 24, endIndent: 24, height: 16));
                              }
                              widgets.add(Padding(
                                padding: const EdgeInsets.only(left: 24, top: 8, bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.arrow_upward_rounded, size: 14, color: Colors.green),
                                    const SizedBox(width: 6),
                                    Text("MONEY IN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.withOpacity(0.8), letterSpacing: 1.0)),
                                  ]
                                ),
                              ));
                              widgets.addAll(credits.map((tx) => buildTile(tx, false)));
                            }

                            widgets.add(const SizedBox(height: 8)); 
                            return widgets;
                          })(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER METHODS
  // ==========================================

  Widget _buildElegantLineDoodles(Color themeAccent) {
    return SizedBox(
      width: double.infinity, 
      height: double.infinity,
      child: CustomPaint(
        painter: LineArtPainter(color: themeAccent.withOpacity(0.08)), 
      ),
    );
  }

  Widget _buildMetricCard(String title, double amount, Color amountColor, Color cardColor, Color subTextColor, Color textColor, Color borderAccent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: borderAccent.withOpacity(0.1))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(title, style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w600)), 
          const SizedBox(height: 10), 
          Text("₹${amount.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: amountColor))
        ]
      ),
    );
  }

  Widget _buildTopSpendCard(String category, Color cardColor, Color subTextColor, Color textColor, Color borderAccent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: borderAccent.withOpacity(0.1))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text("Top Spend", style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w600)), 
          const SizedBox(height: 10), 
          Row(
            children: [
              Icon(_getCategoryIcon(category), size: 19, color: Colors.orangeAccent), 
              const SizedBox(width: 8), 
              Expanded(
                child: Text(category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor), overflow: TextOverflow.ellipsis)
              )
            ]
          )
        ]
      ),
    );
  }

  // --- THE FULLY UPGRADED AI INSIGHT CARD ---
  Widget _buildAiInsightCard(String rawAiText, Color cardColor, Color themeAccent, Color textColor, Color subTextColor, Color baseAccent) {
    String primaryFocus = "Overall Expenses";
    String strategyText = rawAiText; 
    String nextMoveText = "Continue tracking your habits to unlock advanced wealth strategies.";

    // Dynamically isolate the Primary Target category
    if (rawAiText.contains("concentrated in ")) {
      primaryFocus = rawAiText.split("concentrated in ").last.split('.').first;
    } else if (rawAiText.contains("Track your ")) {
      primaryFocus = rawAiText.split("Track your ").last.split(" spending").first;
    }

    // Robust Regex Processing Layer
    try {
      final RegExp strategyRegex = RegExp(r'Strategy:\s*(.*?)\s*(?=Since you|$)', caseSensitive: false);
      final RegExp nextMoveRegex = RegExp(r'consider your next move:\s*(.*)', caseSensitive: false);

      final Match? strategyMatch = strategyRegex.firstMatch(rawAiText);
      final Match? nextMoveMatch = nextMoveRegex.firstMatch(rawAiText);

      if (strategyMatch != null && strategyMatch.group(1) != null) {
        String extractedStrat = strategyMatch.group(1)!.trim();
        if (extractedStrat.isNotEmpty) strategyText = extractedStrat;
      }

      if (nextMoveMatch != null && nextMoveMatch.group(1) != null) {
        String extractedMove = nextMoveMatch.group(1)!.trim();
        if (extractedMove.isNotEmpty) nextMoveText = extractedMove;
      }
    } catch (e) {
      debugPrint("Kuber Parsing Safe-Catch: $e");
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeAccent.withOpacity(0.3), width: 1.5), 
        boxShadow: [BoxShadow(color: themeAccent.withOpacity(0.05), blurRadius: 20, spreadRadius: 2)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // The Expanded wrapper preventing layout stripe overflow
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: themeAccent, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "KUBER'S FINANCIAL INTELLIGENCE",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(color: themeAccent, fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, color: Colors.green, size: 12),
                    SizedBox(width: 4),
                    Text("Verified", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Text("Primary Target: ${primaryFocus.trim()}", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(height: 3, width: 60, color: themeAccent),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: themeAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Optimization Strategy", style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(strategyText, style: TextStyle(color: textColor, fontSize: 14, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: themeAccent.withOpacity(0.2)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.rocket_launch_rounded, color: baseAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Next Wealth Move", style: TextStyle(color: baseAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(nextMoveText, style: TextStyle(color: textColor, fontSize: 14, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, dynamic> categories, Color dynamicTextColor) {
    int colorIndex = 0;
    
    final List<Color> absoluteContrastColors = [
      const Color(0xFFE6194B), const Color(0xFF3CB44B), const Color(0xFFFFE119), const Color(0xFF4363D8), 
      const Color(0xFFF58231), const Color(0xFF911EB4), const Color(0xFF46F0F0), const Color(0xFFF032E6), 
      const Color(0xFFBFCF02), const Color(0xFF008080), 
    ];

    final validCategories = categories.entries.where((e) => (e.value ?? 0) > 0);
    
    return validCategories.map((entry) {
      return PieChartSectionData(
        color: absoluteContrastColors[colorIndex++ % absoluteContrastColors.length], 
        value: (entry.value ?? 0).toDouble(), 
        title: entry.key, 
        radius: 50, 
        titlePositionPercentageOffset: 1.4,
        titleStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: dynamicTextColor, letterSpacing: 0.5), 
      );
    }).toList();
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('food') || cat.contains('zomato') || cat.contains('swiggy')) return Icons.fastfood_rounded;
    if (cat.contains('shopping') || cat.contains('amazon') || cat.contains('flipkart')) return Icons.shopping_bag_rounded;
    if (cat.contains('health') || cat.contains('pharmacy') || cat.contains('apollo')) return Icons.local_hospital_rounded;
    if (cat.contains('utility') || cat.contains('electricity') || cat.contains('bill')) return Icons.lightbulb_rounded;
    if (cat.contains('travel') || cat.contains('transport') || cat.contains('uber')) return Icons.directions_car_rounded;
    if (cat.contains('rent') || cat.contains('home') || cat.contains('housing')) return Icons.house_rounded;
    if (cat.contains('emi') || cat.contains('loan') || cat.contains('bank')) return Icons.account_balance_rounded;
    if (cat.contains('education') || cat.contains('college') || cat.contains('school')) return Icons.school_rounded;
    if (cat.contains('income') || cat.contains('salary')) return Icons.payments_rounded;
    if (cat.contains('grocery') || cat.contains('mart')) return Icons.local_grocery_store_rounded;
    if (cat.contains('entertainment') || cat.contains('movie')) return Icons.movie_rounded;
    if (cat.contains('fuel') || cat.contains('petrol')) return Icons.local_gas_station_rounded;
    return Icons.receipt_long_rounded; 
  }

  void _showTransactionDetails(BuildContext context, Map<String, dynamic> tx, bool isDebit, double amount, String category, String date, Color solidBgColor, Color textColor, Color subTextColor, Color themeAccent) {
    final double balance = (tx['balance'] ?? 0).toDouble();
    showModalBottomSheet(
      context: context, 
      backgroundColor: solidBgColor, 
      isScrollControlled: true, 
      elevation: 10, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return Padding(
          padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 32.0, bottom: 32.0 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 44, 
                backgroundColor: isDebit ? Colors.redAccent.withOpacity(0.12) : Colors.green.withOpacity(0.12), 
                child: Icon(_getCategoryIcon(category), color: isDebit ? Colors.redAccent : Colors.green, size: 40)
              ),
              const SizedBox(height: 18),
              Text(
                "${isDebit ? '-' : '+'} ₹${amount.toStringAsFixed(2)}", 
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: isDebit ? Colors.redAccent : Colors.green)
              ),
              const SizedBox(height: 10),
              Text(
                tx['narration'] ?? 'Unknown', 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w600)
              ),
              const SizedBox(height: 36),
              Divider(color: themeAccent.withOpacity(0.2), thickness: 1),
              const SizedBox(height: 18),
              _buildDetailRow("Category", category, Icons.category_rounded, textColor, subTextColor),
              const SizedBox(height: 18),
              _buildDetailRow("Date", date.isNotEmpty ? date : "N/A", Icons.calendar_today_rounded, textColor, subTextColor),
              const SizedBox(height: 18),
              _buildDetailRow("Type", isDebit ? "Debit (Money Out)" : "Credit (Money In)", Icons.swap_horiz_rounded, textColor, subTextColor),
              if (balance > 0) ...[
                const SizedBox(height: 18), 
                _buildDetailRow("Balance", "₹${balance.toStringAsFixed(2)}", Icons.account_balance_wallet_rounded, textColor, subTextColor)
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, 
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context), 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeAccent, 
                    foregroundColor: Colors.white, 
                    padding: const EdgeInsets.symmetric(vertical: 18), 
                    elevation: 3, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ), 
                  child: const Text("Close", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0))
                )
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color textColor, Color subTextColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: subTextColor), 
        const SizedBox(width: 14), 
        Text(label, style: TextStyle(fontSize: 14, color: subTextColor, fontWeight: FontWeight.w500)), 
        const Spacer(), 
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor))
      ]
    );
  }

  Future<void> _generateAndSharePDF(BuildContext flutterContext, double income, double expense, double savings, String topSpend, String aiText, List<dynamic> txs, Map<String, dynamic> categories) async {
    final pdf = pw.Document();
    
    String safeString(dynamic input) => (input ?? '').toString().replaceAll('₹', 'Rs. ');

    final List<PdfColor> pdfColors = [
      PdfColors.blue, PdfColors.orange, PdfColors.purple, PdfColors.red, 
      PdfColors.teal, PdfColors.indigo, PdfColors.pink, PdfColors.amber, PdfColors.cyan
    ];
    int colorIdx = 0;
    final List<pw.Dataset> pieDatasets = [];
    final List<pw.Widget> legendItems = [];
    
    categories.forEach((key, value) {
      final double val = (value ?? 0).toDouble();
      if (val > 0) {
        final color = pdfColors[colorIdx % pdfColors.length];
        pieDatasets.add(pw.PieDataSet(value: val, color: color, drawBorder: false));
        legendItems.add(
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min, 
            children: [
              pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle)),
              pw.SizedBox(width: 6),
              pw.Text(safeString('$key (Rs. ${val.toStringAsFixed(0)})'), style: const pw.TextStyle(fontSize: 11)),
            ]
          )
        );
        colorIdx++;
      }
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4, 
        margin: const pw.EdgeInsets.all(32), 
        build: (pw.Context context) {
          return [
            pw.Text("Kuber AI Financial Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
            pw.Text("Generated on: ${DateTime.now().toString().substring(0, 16)}", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
            pw.SizedBox(height: 24),
            pw.Text("Financial Overview", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, 
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start, 
                  children: [
                    pw.Text(safeString("Total Income: Rs. ${income.toStringAsFixed(2)}"), style: pw.TextStyle(color: PdfColors.green700, fontSize: 14)), 
                    pw.SizedBox(height: 4), 
                    pw.Text(safeString("Total Expense: Rs. ${expense.toStringAsFixed(2)}"), style: pw.TextStyle(color: PdfColors.red700, fontSize: 14)), 
                  ]
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start, 
                  children: [
                    pw.Text(safeString("Net Savings: Rs. ${savings.toStringAsFixed(2)}"), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)), 
                    pw.SizedBox(height: 4), 
                    pw.Text(safeString("Top Spend: $topSpend"), style: const pw.TextStyle(fontSize: 14)), 
                  ]
                ),
              ], 
            ), 
            pw.SizedBox(height: 24), 
            
            if (pieDatasets.isNotEmpty) ...[
              pw.Text("Expense Breakdown", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)), 
              pw.Divider(), 
              pw.SizedBox(height: 12), 
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center, 
                children: [
                  pw.Container(height: 140, width: 140, child: pw.Chart(grid: pw.PieGrid(), datasets: pieDatasets)), 
                  pw.SizedBox(width: 24), 
                  pw.Expanded(child: pw.Wrap(spacing: 16, runSpacing: 12, children: legendItems)) 
                ] 
              ), 
              pw.SizedBox(height: 32), 
            ], 
            
            pw.Text("Kuber AI Insights", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)), 
            pw.Divider(), 
            pw.Container(
              padding: const pw.EdgeInsets.all(12), 
              decoration: pw.BoxDecoration(
                color: PdfColors.teal50, 
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)), 
                border: pw.Border.all(color: PdfColors.teal200)
              ), 
              child: pw.Text(safeString(aiText), style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 12)), 
            ), 
            pw.SizedBox(height: 32), 
            
            pw.Text("Transaction History", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)), 
            pw.Divider(), 
            pw.SizedBox(height: 8), 
            
            pw.TableHelper.fromTextArray(
              context: context, 
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5), 
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal100), 
              headerHeight: 28, 
              cellHeight: 22, 
              cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft, 2: pw.Alignment.center, 3: pw.Alignment.centerRight}, 
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), 
              cellStyle: const pw.TextStyle(fontSize: 10), 
              headers: ['Date', 'Narration', 'Category', 'Amount (Rs)'], 
              data: txs.map((tx) { 
                final isDebit = (tx['debit'] ?? 0) > 0; 
                final amount = isDebit ? "-${tx['debit']}" : "+${tx['credit']}"; 
                return [safeString(tx['date']), safeString(tx['narration']), safeString(tx['category']), safeString(amount)]; 
              }).toList(), 
            ), 
          ];
        }, 
      ), 
    );

    final bytes = await pdf.save();
    
    if (kIsWeb) {
      // 1. Force the browser to download via our isolated web helper class
      WebDownloader.downloadPdf(bytes, 'Kuber_AI_Report.pdf');

      // 2. Format a clean text summary and force it into the clipboard
      final String summaryText = "Kuber AI Financial Report Summary:\nIncome: Rs. ${income.toStringAsFixed(2)}\nExpenses: Rs. ${expense.toStringAsFixed(2)}\nSavings: Rs. ${savings.toStringAsFixed(2)}\n\nAI Insights: $aiText";
      
      await Clipboard.setData(ClipboardData(text: summaryText));

      // 3. Clear old loading snacks and show success
      ScaffoldMessenger.of(flutterContext).hideCurrentSnackBar();
      ScaffoldMessenger.of(flutterContext).showSnackBar(
        const SnackBar(
          content: Text("PDF Downloaded & Summary Copied to Clipboard!"), 
          backgroundColor: Colors.green
        )
      );
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/Kuber_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      await Share.shareXFiles([XFile(file.path)], text: "Check out my AI Financial Report generated by Kuber!");
      ScaffoldMessenger.of(flutterContext).showSnackBar(const SnackBar(content: Text("PDF saved securely to your device!")));
    }
  }
}

class LineArtPainter extends CustomPainter {
  final Color color;

  LineArtPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3 
      ..style = PaintingStyle.stroke;

    final path1 = Path()..moveTo(0, size.height * 0.1)..lineTo(size.width, size.height * 0.3);
    final path2 = Path()..moveTo(size.width, size.height * 0.15)..lineTo(size.width * 0.2, size.height);
    final path3 = Path()..moveTo(size.width * 0.7, 0)..lineTo(size.width * 0.9, size.height * 0.8);
    final path4 = Path()..moveTo(size.width * 0.5, 0)..cubicTo(size.width * 0.7, size.height * 0.4, size.width * 0.1, size.height * 0.6, 0, size.height * 0.2);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
    canvas.drawPath(path4, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}