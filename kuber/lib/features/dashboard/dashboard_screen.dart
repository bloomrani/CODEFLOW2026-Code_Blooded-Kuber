import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; 
import 'package:kuber/providers/theme_provider.dart'; 
import '../upload/upload_screen.dart'; 
import '../../core/constants/app_constants.dart'; 

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
    
    final Color accentColor = isDark ? themeAccent : const Color(0xFF0D9488);

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
                      colors: [
                        Color(0xFF125C7A), 
                        Color(0xFF030D14), 
                      ],
                      stops: [0.0, 0.85], 
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFFFFF), 
                        Color(0xFFE9D5FF), 
                      ],
                      stops: [0.1, 1.0],
                    ),
            ),
          ),
          
          _buildElegantLineDoodles(isDark, themeAccent),
          
          Scaffold(
            backgroundColor: Colors.transparent, 
            
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const UploadScreen()), (route) => false);
                },
              ),
              title: Text('KUBER AI', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: 20)),
              centerTitle: true,
              backgroundColor: Colors.transparent, 
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(Icons.ios_share_rounded, color: themeAccent), 
                  tooltip: "Share Financial Report",
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sharing Financial Report...")));
                    await _generateAndSharePDF(totalIncome, totalExpense, netSavings, topCategory, aiCommentary, transactions, categoryData);
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
                if (analysisData.isNotEmpty) await ScanVault.saveScan(analysisData);
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const UploadScreen()), (route) => false);
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
                // TAB 2: AI INSIGHTS
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Kuber's Analysis", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 16),
                      
                      // 🌟 THE FIX: Call the new rich UI component here!
                      _buildAiInsightCard(aiCommentary, glassCardColor, themeAccent, textColor, subTextColor, baseAccent),
                    ],
                  ),
                ),

                // ==========================================
                // TAB 3: DEBIT/CREDIT SEPARATED HISTORY
                // ==========================================
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
                          
                          // 👇 NEW LOGIC: Splitting into Debits and Credits inside the dropdown
                          children: (() {
                            final List<dynamic> debits = catTxs.where((t) => (t['debit'] ?? 0) > 0).toList();
                            final List<dynamic> credits = catTxs.where((t) => (t['credit'] ?? 0) > 0).toList();
                            List<Widget> widgets = [];

                            // Helper function to build individual transaction tiles
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

                            // 1. Render Debits (Money Out) first
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

                            // 2. Render Credits (Money In)
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

                            widgets.add(const SizedBox(height: 8)); // Bottom padding
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

  // --- LINE DOODLES ---
  Widget _buildElegantLineDoodles(bool isDark, Color themeAccent) {
    final Color doodleColor = themeAccent; 
    return SizedBox(
      width: double.infinity, height: double.infinity,
      child: CustomPaint(
        painter: LineArtPainter(color: doodleColor.withOpacity(0.08)), 
      ),
    );
  }
  // --- AI INSIGHT TERMINAL UI ---
  Widget _buildAiInsightCard(String rawAiText, Color cardColor, Color themeAccent, Color textColor, Color subTextColor, Color baseAccent) {
    
    // 🔍 1. Set smart defaults. If we can't split the text, just show the RAW text!
    String primaryFocus = "Overall Expenses";
    String strategyText = rawAiText; 
    String nextMoveText = "Continue tracking your habits to unlock advanced wealth strategies.";

    // 🔍 2. Try to extract the Primary Focus
    if (rawAiText.contains("concentrated in ")) {
      primaryFocus = rawAiText.split("concentrated in ").last.split('.').first;
    } else if (rawAiText.contains("Track your ")) {
      primaryFocus = rawAiText.split("Track your ").last.split(" spending").first;
    }

    // 🔍 3. Try to extract the Strategy block
    if (rawAiText.contains("Strategy: ")) {
      strategyText = rawAiText.split("Strategy: ").last.split(" Since").first.replaceAll("Correction Strategy: ", "");
    } else if (rawAiText.contains("Recovery Insight: ")) {
      strategyText = rawAiText.split("Recovery Insight: ").last.split(" Prioritizing").first;
    }

    // 🔍 4. Try to extract the Next Move block
    if (rawAiText.contains("consider your next move: ")) {
      nextMoveText = rawAiText.split("consider your next move: ").last;
    } else if (rawAiText.contains("Reducing outlays here is critical")) {
      nextMoveText = "Reducing outlays in this sector is critical to restoring your capital baseline.";
    } else if (rawAiText.contains("building back an emergency cash buffer")) {
      nextMoveText = "Prioritize your recovery while building back an emergency cash buffer.";
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
          // 1. Header Row with Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: themeAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "KUBER'S FINANCIAL INTELLIGENCE",
                    style: TextStyle(
                      color: themeAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text("Verified", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),

          // 2. Main Metric Target
          Text(
            "Primary Target: $primaryFocus",
            style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: 0.72,
            backgroundColor: subTextColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(themeAccent),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 20),

          // 3. Strategy Column Block
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, color: themeAccent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Optimization Strategy", style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      strategyText,
                      style: TextStyle(color: textColor, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: themeAccent.withOpacity(0.15), thickness: 1),
          ),

          // 4. Wealth Generation Block
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.rocket_launch_outlined, color: baseAccent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Next Wealth Move", style: TextStyle(color: baseAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      nextMoveText,
                      style: TextStyle(color: textColor, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildMetricCard(String title, double amount, Color amountColor, Color cardColor, Color subTextColor, Color textColor, Color borderAccent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderAccent.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text("₹${amount.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: amountColor)),
        ],
      ),
    );
  }

  Widget _buildTopSpendCard(String category, Color cardColor, Color subTextColor, Color textColor, Color borderAccent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderAccent.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Top Spend", style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(_getCategoryIcon(category), size: 19, color: Colors.orangeAccent),
              const SizedBox(width: 8),
              Expanded(child: Text(category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }

 List<PieChartSectionData> _buildPieChartSections(Map<String, dynamic> categories, Color dynamicTextColor) {
    int colorIndex = 0;
    
    // 👇 FIX: Absolute Maximum Contrast Palette.
    // Every color is a completely different hue from the one next to it.
    final List<Color> absoluteContrastColors = [
      const Color(0xFFE6194B), // 1. Pure Red
      const Color(0xFF3CB44B), // 2. Deep Green
      const Color(0xFFFFE119), // 3. Bright Yellow
      const Color(0xFF4363D8), // 4. Strong Blue
      const Color(0xFFF58231), // 5. Pure Orange
      const Color(0xFF911EB4), // 6. Deep Purple
      const Color(0xFF46F0F0), // 7. Neon Cyan
      const Color(0xFFF032E6), // 8. Hot Magenta
      const Color(0xFFBFCF02), // 9. Acid Lime
      const Color(0xFF008080), // 10. Dark Teal
    ];

    final validCategories = categories.entries.where((e) => (e.value ?? 0) > 0);
    
    return validCategories.map((entry) {
      return PieChartSectionData(
        color: absoluteContrastColors[colorIndex++ % absoluteContrastColors.length], 
        value: (entry.value ?? 0).toDouble(), 
        title: entry.key, 
        radius: 50, 
        titlePositionPercentageOffset: 1.4,
        titleStyle: TextStyle(
          fontSize: 10, 
          fontWeight: FontWeight.bold, 
          color: dynamicTextColor, 
          letterSpacing: 0.5
        ), 
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
                child: Icon(_getCategoryIcon(category), color: isDebit ? Colors.redAccent : Colors.green, size: 40),
              ),
              const SizedBox(height: 18),
              Text(
                "${isDebit ? '-' : '+'} ₹${amount.toStringAsFixed(2)}", 
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: isDebit ? Colors.redAccent : Colors.green),
              ),
              const SizedBox(height: 10),
              Text(
                tx['narration'] ?? 'Unknown', 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 36),
              Divider(color: themeAccent.withOpacity(0.2), thickness: 1),
              const SizedBox(height: 18),
              _buildDetailRow("Category", category, Icons.category_rounded, textColor, subTextColor),
              const SizedBox(height: 18),
              _buildDetailRow("Date", date.isNotEmpty ? date : "N/A", Icons.calendar_today_rounded, textColor, subTextColor),
              const SizedBox(height: 18),
              _buildDetailRow("Type", isDebit ? "Debit (Money Out)" : "Credit (Money In)", Icons.swap_horiz_rounded, textColor, subTextColor),
              if (balance > 0) ...[const SizedBox(height: 18), _buildDetailRow("Balance", "₹${balance.toStringAsFixed(2)}", Icons.account_balance_wallet_rounded, textColor, subTextColor)],
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: themeAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text("Close", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0))))
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color textColor, Color subTextColor) {
    return Row(children: [Icon(icon, size: 20, color: subTextColor), const SizedBox(width: 14), Text(label, style: TextStyle(fontSize: 14, color: subTextColor, fontWeight: FontWeight.w500)), const Spacer(), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor))]);
  }

  // --- PDF GENERATOR ---
  Future<void> _generateAndSharePDF(double income, double expense, double savings, String topSpend, String aiText, List<dynamic> txs, Map<String, dynamic> categories) async {
    final pdf = pw.Document();
    
    String safeString(dynamic input) {
      return (input ?? '').toString().replaceAll('₹', 'Rs. ');
    }

    final List<PdfColor> pdfColors = [PdfColors.blue, PdfColors.orange, PdfColors.purple, PdfColors.red, PdfColors.teal, PdfColors.indigo, PdfColors.pink, PdfColors.amber, PdfColors.cyan];
    int colorIdx = 0;
    final List<pw.Dataset> pieDatasets = [];
    final List<pw.Widget> legendItems = [];
    
    categories.forEach((key, value) {
      final double val = (value ?? 0).toDouble();
      if (val > 0) {
        final color = pdfColors[colorIdx % pdfColors.length];
        pieDatasets.add(pw.PieDataSet(value: val, color: color, drawBorder: false));
        legendItems.add(
          pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
            pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle)),
            pw.SizedBox(width: 6),
            pw.Text(safeString('$key (Rs. ${val.toStringAsFixed(0)})'), style: const pw.TextStyle(fontSize: 11)),
          ])
        );
        colorIdx++;
      }
    });

    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(32), build: (pw.Context context) {
          return [
            pw.Text("Kuber AI Financial Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
            pw.Text("Generated on: ${DateTime.now().toString().substring(0, 16)}", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
            pw.SizedBox(height: 24),
            pw.Text("Financial Overview", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(safeString("Total Income: Rs. ${income.toStringAsFixed(2)}"), style: pw.TextStyle(color: PdfColors.green700, fontSize: 14)), 
                  pw.SizedBox(height: 4), 
                  pw.Text(safeString("Total Expense: Rs. ${expense.toStringAsFixed(2)}"), style: pw.TextStyle(color: PdfColors.red700, fontSize: 14)), 
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(safeString("Net Savings: Rs. ${savings.toStringAsFixed(2)}"), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)), 
                  pw.SizedBox(height: 4), 
                  pw.Text(safeString("Top Spend: $topSpend"), style: const pw.TextStyle(fontSize: 14)), 
                ]),
              ], ), pw.SizedBox(height: 24), if (pieDatasets.isNotEmpty) ...[pw.Text("Expense Breakdown", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)), pw.Divider(), pw.SizedBox(height: 12), pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [pw.Container(height: 140, width: 140, child: pw.Chart(grid: pw.PieGrid(), datasets: pieDatasets)), pw.SizedBox(width: 24), pw.Expanded(child: pw.Wrap(spacing: 16, runSpacing: 12, children: legendItems)) ] ), pw.SizedBox(height: 32), ], pw.Text("Kuber AI Insights", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)), pw.Divider(), pw.Container(padding: const pw.EdgeInsets.all(12), decoration: pw.BoxDecoration(color: PdfColors.teal50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)), border: pw.Border.all(color: PdfColors.teal200)), child: pw.Text(safeString(aiText), style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 12)), ), pw.SizedBox(height: 32), pw.Text("Transaction History", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)), pw.Divider(), pw.SizedBox(height: 8), 
              
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
        }, ), );
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Kuber_AI_Report.pdf");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: "Check out my AI Financial Report generated by Kuber!");
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

    final path1 = Path()
      ..moveTo(0, size.height * 0.1)
      ..lineTo(size.width, size.height * 0.3);
      
    final path2 = Path()
      ..moveTo(size.width, size.height * 0.15)
      ..lineTo(size.width * 0.2, size.height);
      
    final path3 = Path()
      ..moveTo(size.width * 0.7, 0)
      ..lineTo(size.width * 0.9, size.height * 0.8);
      
    final path4 = Path()
      ..moveTo(size.width * 0.5, 0)
      ..cubicTo(size.width * 0.7, size.height * 0.4, size.width * 0.1, size.height * 0.6, 0, size.height * 0.2);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
    canvas.drawPath(path4, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}