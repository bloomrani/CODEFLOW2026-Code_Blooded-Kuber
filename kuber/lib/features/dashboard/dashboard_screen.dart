import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
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

    // Theme Colors
    final Color bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final Color cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final Color textColor = isDark ? AppColors.textWhite : AppColors.textBlack;
    final Color subTextColor = isDark ? AppColors.subTextDark : AppColors.subTextLight;
    final Color accentColor = AppColors.accentBlue;

    // --- DATA EXTRACTION ---
    final metrics = analysisData['metrics'] ?? {};
    final double totalIncome = (metrics['total_income'] ?? 0).toDouble();
    final double totalExpense = (metrics['total_expense'] ?? 0).toDouble();
    final double netSavings = (metrics['net_savings'] ?? 0).toDouble();
    final String topCategory = metrics['highest_spending_category'] ?? "None";
    final Map<String, dynamic> categoryData = analysisData['category_breakdown'] ?? {};
    final List<dynamic> transactions = analysisData['transactions'] ?? [];
    
    final String aiCommentary = analysisData['ai_recommendation'] 
                             ?? "Kuber is analyzing your habits. Try refreshing or uploading a clean statement.";

    // 👇 THIS IS THE MAGIC WRAPPER FOR TABS 👇
    return DefaultTabController(
      length: 3, // We have 3 sections
      child: Scaffold(
        backgroundColor: bgColor,
        
        // --- APP BAR WITH TAB BAR ---
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'KUBER AI', 
                style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
            ],
          ),
          backgroundColor: bgColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: accentColor),
              onPressed: () => themeProvider.toggleTheme(!isDark),
            ),
            const SizedBox(width: 8),
          ],
          // The actual Tab Bar
          bottom: TabBar(
            indicatorColor: accentColor,
            indicatorWeight: 4,
            labelColor: accentColor,
            unselectedLabelColor: subTextColor,
            tabs: const [
              Tab(icon: Icon(Icons.pie_chart_outline_rounded), text: "Overview"),
              Tab(icon: Icon(Icons.auto_awesome_rounded), text: "AI Insights"),
              Tab(icon: Icon(Icons.list_alt_rounded), text: "History"),
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UploadScreen())),
          backgroundColor: accentColor,
          icon: const Icon(Icons.upload_file, color: Colors.white),
          label: const Text("New Scan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),

        // --- TAB VIEWS (What shows when you click each tab) ---
        body: TabBarView(
          children: [
            
            // ==========================================
            // TAB 1: OVERVIEW (Metrics & Chart)
            // ==========================================
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard("Income", totalIncome, Colors.greenAccent, cardColor, subTextColor, textColor)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard("Expenses", totalExpense, Colors.redAccent, cardColor, subTextColor, textColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard("Net Savings", netSavings, accentColor, cardColor, subTextColor, textColor)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTopSpendCard(topCategory, cardColor, subTextColor, textColor)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                    child: categoryData.isNotEmpty 
                      ? PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 40, sections: _buildPieChartSections(context, categoryData)))
                      : Center(child: Text("No expenses to display", style: TextStyle(color: subTextColor))),
                  ),
                  const SizedBox(height: 80), 
                ],
              ),
            ),

            // ==========================================
            // TAB 2: AI INSIGHTS
            // ==========================================
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Kuber's Analysis", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark 
                            ? [Colors.blueAccent.withOpacity(0.15), Colors.purpleAccent.withOpacity(0.05)]
                            : [Colors.blueAccent.withOpacity(0.08), Colors.purpleAccent.withOpacity(0.03)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 32),
                        const SizedBox(height: 16),
                        Text(
                          aiCommentary,
                          style: TextStyle(color: textColor, fontSize: 16, height: 1.6, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // TAB 3: TRANSACTIONS
            // ==========================================
            ListView.builder(
              padding: const EdgeInsets.all(16.0).copyWith(bottom: 80.0),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final bool isDebit = (tx['debit'] ?? 0) > 0;
                final double amount = isDebit ? (tx['debit'] ?? 0).toDouble() : (tx['credit'] ?? 0).toDouble();
                final String category = tx['category'] ?? 'Uncategorized';
                final String txDate = tx['date'] ?? tx['timestamp'] ?? '';

                return Card(
                  color: cardColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: isDebit ? Colors.redAccent.withOpacity(0.15) : Colors.greenAccent.withOpacity(0.15),
                      child: Icon(_getCategoryIcon(category), color: isDebit ? Colors.redAccent : Colors.greenAccent, size: 20),
                    ),
                    title: Text(tx['narration'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                    subtitle: Row(
                      children: [
                        Text(category, style: const TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                        if (txDate.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text("•  $txDate", style: TextStyle(fontSize: 11, color: subTextColor)),
                        ]
                      ],
                    ),
                    trailing: Text("₹${amount.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDebit ? textColor : Colors.greenAccent)),
                    onTap: () => _showTransactionDetails(context, tx, isDebit, amount, category, txDate, cardColor, textColor, subTextColor),
                  ),
                );
              },
            ),
            
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS (Unchanged) ---

  Widget _buildMetricCard(String title, double amount, Color amountColor, Color cardColor, Color subTextColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text("₹${amount.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: amountColor)),
        ],
      ),
    );
  }

  Widget _buildTopSpendCard(String category, Color cardColor, Color subTextColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Top Spend", style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(_getCategoryIcon(category), size: 18, color: Colors.orangeAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  category, 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(BuildContext context, Map<String, dynamic> categories) {
    int colorIndex = 0;
    final List<Color> colors = [
      AppColors.accentBlue, Colors.orangeAccent, Colors.purpleAccent, 
      Colors.redAccent, Colors.tealAccent, Colors.indigoAccent
    ];

    final validCategories = categories.entries.where((e) => (e.value ?? 0) > 0);

    return validCategories.map((entry) {
      return PieChartSectionData(
        color: colors[colorIndex++ % colors.length],
        value: (entry.value ?? 0).toDouble(),
        title: entry.key,
        radius: 45, 
        titlePositionPercentageOffset: 1.5,
        titleStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color),
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

  // --- BOTTOM SHEET INTERACTION ---
  void _showTransactionDetails(BuildContext context, Map<String, dynamic> tx, bool isDebit, double amount, String category, String date, Color bgColor, Color textColor, Color subTextColor) {
    final double balance = (tx['balance'] ?? 0).toDouble();

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        // 👇 FIX: Get the height of the phone's system navigation bar 👇
        final bottomPadding = MediaQuery.of(context).padding.bottom;

        return Padding(
          // 👇 FIX: Add that system padding to our bottom spacing so it pushes up! 👇
          padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 32.0, bottom: 32.0 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: isDebit ? Colors.redAccent.withOpacity(0.15) : Colors.greenAccent.withOpacity(0.15),
                child: Icon(_getCategoryIcon(category), color: isDebit ? Colors.redAccent : Colors.greenAccent, size: 36),
              ),
              const SizedBox(height: 16),
              
              Text(
                "${isDebit ? '-' : '+'} ₹${amount.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDebit ? Colors.redAccent : Colors.greenAccent),
              ),
              const SizedBox(height: 8),
              
              Text(
                tx['narration'] ?? 'Unknown Transaction',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),
              Divider(color: subTextColor.withOpacity(0.3), thickness: 1),
              const SizedBox(height: 16),

              _buildDetailRow("Category", category, Icons.category_rounded, textColor, subTextColor),
              const SizedBox(height: 16),
              _buildDetailRow("Date", date.isNotEmpty ? date : "N/A", Icons.calendar_today_rounded, textColor, subTextColor),
              const SizedBox(height: 16),
              _buildDetailRow("Transaction Type", isDebit ? "Money Out (Debit)" : "Money In (Credit)", Icons.swap_horiz_rounded, textColor, subTextColor),
              
              if (balance > 0) ...[
                 const SizedBox(height: 16),
                _buildDetailRow("Account Balance", "₹${balance.toStringAsFixed(2)}", Icons.account_balance_wallet_rounded, textColor, subTextColor),
              ],
              
              const SizedBox(height: 36),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Close", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
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
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, color: subTextColor, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }
}