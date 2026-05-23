import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
// Change 'kuber_app' to whatever is in your pubspec.yaml name field
import 'package:kuber/providers/theme_provider.dart'; // Ensure this path matches your folder structure
import '../upload/upload_screen.dart'; 
import '../../core/constants/app_constants.dart'; 

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> analysisData;

  const DashboardScreen({super.key, required this.analysisData});

  @override
  Widget build(BuildContext context) {
    // 1. Hook into ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    
    final Color bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final Color cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final Color textColor = isDark ? AppColors.textWhite : AppColors.textBlack;
    final Color subTextColor = isDark ? AppColors.subTextDark : AppColors.subTextLight;
    final Color accentColor = AppColors.accentBlue;

    // Data extraction
    final metrics = analysisData['metrics'] ?? {};
    final double totalIncome = (metrics['total_income'] ?? 0).toDouble();
    final double totalExpense = (metrics['total_expense'] ?? 0).toDouble();
    final double netSavings = (metrics['net_savings'] ?? 0).toDouble();
    final String topCategory = metrics['highest_spending_category'] ?? "None";
    final Map<String, dynamic> categoryData = analysisData['category_breakdown'] ?? {};
    final List<dynamic> transactions = analysisData['transactions'] ?? [];

    return Scaffold(
      backgroundColor: bgColor,
      
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: accentColor),
            const SizedBox(width: 8),
            Text(
              'Kuber AI Analysis', 
              style: TextStyle(
                color: textColor, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 2.0, 
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
         Navigator.of(context).push(
         MaterialPageRoute(builder: (context) => const UploadScreen()),
          );
        },
        backgroundColor: accentColor,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text("New Scan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- THEME TOGGLE SWITCH ---
            SwitchListTile(
              title: Text("Dark Mode", style: TextStyle(color: textColor)),
              value: isDark,
              activeColor: accentColor,
              onChanged: (value) => themeProvider.toggleTheme(value),
            ),
            const SizedBox(height: 16),

            // --- METRICS ---
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
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Top Spend", style: TextStyle(color: subTextColor, fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(_getCategoryIcon(topCategory), size: 18, color: Colors.orangeAccent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                topCategory, 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Text("AI Expense Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 16),
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
              child: categoryData.isNotEmpty 
                ? PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 40, sections: _buildPieChartSections(categoryData)))
                : Center(child: Text("No expenses to display", style: TextStyle(color: subTextColor))),
            ),
            const SizedBox(height: 32),

            Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 80.0), 
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final bool isDebit = (tx['debit'] ?? 0) > 0;
                  final double amount = isDebit ? (tx['debit'] ?? 0).toDouble() : (tx['credit'] ?? 0).toDouble();
                  final String category = tx['category'] ?? 'Uncategorized';

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isDebit ? Colors.redAccent.withOpacity(0.15) : Colors.greenAccent.withOpacity(0.15),
                        child: Icon(_getCategoryIcon(category), color: isDebit ? Colors.redAccent : Colors.greenAccent, size: 20),
                      ),
                      title: Text(tx['narration'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                      subtitle: Text(category, style: const TextStyle(fontSize: 10, color: Colors.blueAccent)),
                      trailing: Text("₹${amount.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDebit ? textColor : Colors.greenAccent)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, double amount, Color amountColor, Color cardColor, Color subTextColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: subTextColor, fontSize: 14)),
          const SizedBox(height: 8),
          Text("₹${amount.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: amountColor)),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, dynamic> categories) {
    int colorIndex = 0;
    final List<Color> colors = [Colors.blueAccent, Colors.orangeAccent, Colors.purpleAccent, Colors.redAccent, Colors.tealAccent];
    return categories.entries.map((entry) {
      return PieChartSectionData(
        color: colors[colorIndex++ % colors.length],
        value: (entry.value ?? 0).toDouble(),
        title: entry.key,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
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
}