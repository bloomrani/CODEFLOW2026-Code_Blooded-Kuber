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

    final Color textColor = isDark ? AppColors.textWhite : AppColors.textBlack;
    final Color subTextColor = isDark ? AppColors.subTextDark : AppColors.subTextLight;
    final Color accentColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    final Color glassCardColor = isDark ? AppColors.darkCard.withOpacity(0.70) : AppColors.lightCard.withOpacity(0.80);
    final Color solidCardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    final metrics = analysisData['metrics'] ?? {};
    final double totalIncome = (metrics['total_income'] ?? 0).toDouble();
    final double totalExpense = (metrics['total_expense'] ?? 0).toDouble();
    final double netSavings = (metrics['net_savings'] ?? 0).toDouble();
    final String topCategory = metrics['highest_spending_category'] ?? "None";
    final Map<String, dynamic> categoryData = analysisData['category_breakdown'] ?? {};
    final List<dynamic> transactions = analysisData['transactions'] ?? [];
    
    final String aiCommentary = analysisData['ai_recommendation'] 
                             ?? "Kuber is analyzing your habits. Try refreshing or uploading a clean statement.";

    return DefaultTabController(
      length: 3, 
      child: Stack(
        children: [
          // 👇 FIX: AnimatedContainer smoothly fades the gradients over 500ms 👇
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: isDark 
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E40AF), Color(0xFF000000)], 
                      stops: [0.0, 0.8],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFFFFF), Color(0xFFE9D5FF)], 
                      stops: [0.1, 1.0],
                    ),
            ),
          ),
          
          _buildElegantLineDoodles(isDark),
          
          Scaffold(
            backgroundColor: Colors.transparent, 
            
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const UploadScreen()),
                    (route) => false, 
                  );
                },
              ),
              title: Text(
                'KUBER AI', 
                style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 20),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent, 
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(Icons.ios_share_rounded, color: accentColor), 
                  tooltip: "Share Financial Report",
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sharing Financial Report...")));
                    await _generateAndSharePDF(totalIncome, totalExpense, netSavings, topCategory, aiCommentary, transactions, categoryData);
                  },
                ),
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: accentColor),
                  onPressed: () => themeProvider.toggleTheme(!isDark),
                ),
                const SizedBox(width: 8),
              ],
              bottom: TabBar(
                indicatorColor: accentColor,
                indicatorWeight: 4,
                labelColor: accentColor,
                unselectedLabelColor: subTextColor,
                dividerColor: Colors.transparent, 
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.pie_chart_outline_rounded), text: "Overview"),
                  Tab(icon: Icon(Icons.auto_awesome_rounded), text: "AI Insights"),
                  Tab(icon: Icon(Icons.list_alt_rounded), text: "History"),
                ],
              ),
            ),

            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                if (analysisData.isNotEmpty) await ScanVault.saveScan(analysisData);
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const UploadScreen()), (route) => false);
              },
              backgroundColor: analysisData.isNotEmpty ? Colors.redAccent : accentColor,
              icon: Icon(analysisData.isNotEmpty ? Icons.save_rounded : Icons.upload_file, color: Colors.white),
              label: Text(analysisData.isNotEmpty ? "Save to Vault" : "New Scan", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),

            body: TabBarView(
              children: [
                // TAB 1
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildMetricCard("Income", totalIncome, isDark ? Colors.greenAccent : Colors.green, glassCardColor, subTextColor, textColor, accentColor)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMetricCard("Expenses", totalExpense, isDark ? Colors.redAccent : Colors.red, glassCardColor, subTextColor, textColor, accentColor)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildMetricCard("Net Savings", netSavings, accentColor, glassCardColor, subTextColor, textColor, accentColor)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTopSpendCard(topCategory, glassCardColor, subTextColor, textColor, accentColor)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: 260,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: glassCardColor, 
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: accentColor.withOpacity(0.1)),
                        ),
                        child: categoryData.isNotEmpty 
                          ? PieChart(PieChartData(sectionsSpace: 3, centerSpaceRadius: 40, sections: _buildPieChartSections(context, categoryData)))
                          : Center(child: Text("No expenses to display", style: TextStyle(color: subTextColor))),
                      ),
                      const SizedBox(height: 80), 
                    ],
                  ),
                ),

                // TAB 2
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Kuber's Analysis", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: glassCardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
                          boxShadow: [BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 20, spreadRadius: 2)]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: isDark ? Colors.amberAccent : Colors.orangeAccent, size: 36),
                            const SizedBox(height: 16),
                            Text(aiCommentary, style: TextStyle(color: textColor, fontSize: 16, height: 1.7, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // TAB 3
                ListView.builder(
                  padding: const EdgeInsets.all(16.0).copyWith(bottom: 80.0),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final bool isDebit = (tx['debit'] ?? 0) > 0;
                    final double amount = isDebit ? (tx['debit'] ?? 0).toDouble() : (tx['credit'] ?? 0).toDouble();
                    final String category = tx['category'] ?? 'Uncategorized';
                    final String txDate = tx['date'] ?? tx['timestamp'] ?? '';

                    // 👇 FIX: Swapped Card for AnimatedContainer to fade the lists too! 👇
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: glassCardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentColor.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isDebit ? Colors.redAccent.withOpacity(0.10) : Colors.greenAccent.withOpacity(0.10),
                          child: Icon(_getCategoryIcon(category), color: isDebit ? Colors.redAccent : Colors.green, size: 22),
                        ),
                        title: Text(tx['narration'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text(category, style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold)),
                              if (txDate.isNotEmpty) ...[const SizedBox(width: 8), Text("•  $txDate", style: TextStyle(fontSize: 11, color: subTextColor))]
                            ],
                          ),
                        ),
                        trailing: Text("₹${amount.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDebit ? textColor : Colors.green)),
                        onTap: () => _showTransactionDetails(context, tx, isDebit, amount, category, txDate, solidCardColor, textColor, subTextColor, accentColor),
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

  Widget _buildElegantLineDoodles(bool isDark) {
    final Color doodleColor = isDark 
        ? const Color(0xFF60A5FA) 
        : const Color(0xFFC084FC); 
    return SizedBox(
      width: double.infinity, height: double.infinity,
      child: CustomPaint(
        painter: LineArtPainter(color: doodleColor.withOpacity(0.2)), 
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildMetricCard(String title, double amount, Color amountColor, Color cardColor, Color subTextColor, Color textColor, Color accentColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: accentColor.withOpacity(0.1))
      ),
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

  Widget _buildTopSpendCard(String category, Color cardColor, Color subTextColor, Color textColor, Color accentColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: accentColor.withOpacity(0.1))
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
              Expanded(child: Text(category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(BuildContext context, Map<String, dynamic> categories) {
    int colorIndex = 0;
    final List<Color> colors = [Colors.blueAccent, Colors.purpleAccent, Colors.orangeAccent, Colors.tealAccent, Colors.redAccent, Colors.indigoAccent];
    final validCategories = categories.entries.where((e) => (e.value ?? 0) > 0);
    return validCategories.map((entry) {
      return PieChartSectionData(
        color: colors[colorIndex++ % colors.length], 
        value: (entry.value ?? 0).toDouble(), 
        title: entry.key, 
        radius: 50, 
        titlePositionPercentageOffset: 1.4,
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

  void _showTransactionDetails(BuildContext context, Map<String, dynamic> tx, bool isDebit, double amount, String category, String date, Color solidBgColor, Color textColor, Color subTextColor, Color accentColor) {
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
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(radius: 44, backgroundColor: isDebit ? Colors.redAccent.withOpacity(0.12) : Colors.green.withOpacity(0.12), child: Icon(_getCategoryIcon(category), color: isDebit ? Colors.redAccent : Colors.green, size: 40)),
              const SizedBox(height: 18),
              Text("${isDebit ? '-' : '+'} ₹${amount.toStringAsFixed(2)}", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: isDebit ? Colors.redAccent : Colors.green)),
              const SizedBox(height: 10),
              Text(tx['narration'] ?? 'Unknown', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 36),
              Divider(color: accentColor.withOpacity(0.2), thickness: 1),
              const SizedBox(height: 18),
              _buildDetailRow("Category", category, Icons.category_rounded, textColor, subTextColor),
              const SizedBox(height: 18),
              _buildDetailRow("Date", date.isNotEmpty ? date : "N/A", Icons.calendar_today_rounded, textColor, subTextColor),
              const SizedBox(height: 18),
              _buildDetailRow("Type", isDebit ? "Debit (Money Out)" : "Credit (Money In)", Icons.swap_horiz_rounded, textColor, subTextColor),
              if (balance > 0) ...[const SizedBox(height: 18), _buildDetailRow("Balance", "₹${balance.toStringAsFixed(2)}", Icons.account_balance_wallet_rounded, textColor, subTextColor)],
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text("Close", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0))))
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
            pw.Text('$key (Rs. ${val.toStringAsFixed(0)})', style: const pw.TextStyle(fontSize: 11)),
          ])
        );
        colorIdx++;
      }
    });
    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(32), build: (pw.Context context) {
          return [
            pw.Text("Kuber AI Financial Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.Text("Generated on: ${DateTime.now().toString().substring(0, 16)}", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
            pw.SizedBox(height: 24),
            pw.Text("Financial Overview", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text("Total Income: Rs. ${income.toStringAsFixed(2)}", style: pw.TextStyle(color: PdfColors.green700, fontSize: 14)), pw.SizedBox(height: 4), pw.Text("Total Expense: Rs. ${expense.toStringAsFixed(2)}", style: pw.TextStyle(color: PdfColors.red700, fontSize: 14)), ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text("Net Savings: Rs. ${savings.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)), pw.SizedBox(height: 4), pw.Text("Top Spend: $topSpend", style: const pw.TextStyle(fontSize: 14)), ]),
              ], ), pw.SizedBox(height: 24), if (pieDatasets.isNotEmpty) ...[pw.Text("Expense Breakdown", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)), pw.Divider(), pw.SizedBox(height: 12), pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [pw.Container(height: 140, width: 140, child: pw.Chart(grid: pw.PieGrid(), datasets: pieDatasets)), pw.SizedBox(width: 24), pw.Expanded(child: pw.Wrap(spacing: 16, runSpacing: 12, children: legendItems)) ] ), pw.SizedBox(height: 32), ], pw.Text("Kuber AI Insights", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)), pw.Divider(), pw.Container(padding: const pw.EdgeInsets.all(12), decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)), border: pw.Border.all(color: PdfColors.blue200)), child: pw.Text(aiText, style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 12)), ), pw.SizedBox(height: 32), pw.Text("Transaction History", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)), pw.Divider(), pw.SizedBox(height: 8), pw.TableHelper.fromTextArray(context: context, border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5), headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100), headerHeight: 28, cellHeight: 22, cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft, 2: pw.Alignment.center, 3: pw.Alignment.centerRight}, headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), cellStyle: const pw.TextStyle(fontSize: 10), headers: ['Date', 'Narration', 'Category', 'Amount (Rs)'], data: txs.map((tx) { final isDebit = (tx['debit'] ?? 0) > 0; final amount = isDebit ? "-${tx['debit']}" : "+${tx['credit']}"; return [tx['date'] ?? '', tx['narration'] ?? 'Unknown', tx['category'] ?? '', amount]; }).toList(), ), ];
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