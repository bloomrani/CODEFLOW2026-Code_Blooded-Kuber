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

    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        backgroundColor: bgColor,
        
        // --- APP BAR ---
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
            style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          centerTitle: true,
          backgroundColor: bgColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
              tooltip: "Generate & Share PDF Report",
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Generating PDF Report..."), duration: Duration(seconds: 1)),
                );
                
                // Triggers the PDF build and share sheet
                await _generateAndSharePDF(
                  totalIncome, 
                  totalExpense, 
                  netSavings, 
                  topCategory, 
                  aiCommentary, 
                  transactions,
                  categoryData 
                );
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
            tabs: const [
              Tab(icon: Icon(Icons.pie_chart_outline_rounded), text: "Overview"),
              Tab(icon: Icon(Icons.auto_awesome_rounded), text: "AI Insights"),
              Tab(icon: Icon(Icons.list_alt_rounded), text: "History"),
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            if (analysisData.isNotEmpty) {
              await ScanVault.saveScan(analysisData);
            }
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const UploadScreen()),
              (route) => false, 
            );
          },
          backgroundColor: analysisData.isNotEmpty ? Colors.redAccent : accentColor,
          icon: Icon(analysisData.isNotEmpty ? Icons.save_rounded : Icons.upload_file, color: Colors.white),
          label: Text(
            analysisData.isNotEmpty ? "Save to Vault" : "New Scan", 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          ),
        ),

        body: TabBarView(
          children: [
            // ==========================================
            // TAB 1: OVERVIEW
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

  // ==========================================
  // 👇 THE FINISHED PDF GENERATOR 👇
  // ==========================================
  Future<void> _generateAndSharePDF(
    double income, 
    double expense, 
    double savings, 
    String topSpend, 
    String aiText, 
    List<dynamic> txs,
    Map<String, dynamic> categories, 
  ) async {
    final pdf = pw.Document();

    // 1. Prepare Pie Chart Data & Dynamic Legend
    final List<PdfColor> pdfColors = [
      PdfColors.blue, PdfColors.orange, PdfColors.purple, 
      PdfColors.red, PdfColors.teal, PdfColors.indigo,
      PdfColors.pink, PdfColors.amber, PdfColors.cyan
    ];
    
    int colorIdx = 0;
    final List<pw.Dataset> pieDatasets = [];
    final List<pw.Widget> legendItems = [];
    
    categories.forEach((key, value) {
      final double val = (value ?? 0).toDouble();
      if (val > 0) {
        final color = pdfColors[colorIdx % pdfColors.length];
        
        pieDatasets.add(
          pw.PieDataSet(
            value: val,
            color: color,
            drawBorder: false,
          )
        );
        
        // 👇 FIX: No fixed width! Let the text breathe dynamically 👇
        legendItems.add(
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min, // Hugs the text exactly
            children: [
              pw.Container(
                width: 10, 
                height: 10, 
                decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle) // Made the legend icons circles for extra polish!
              ),
              pw.SizedBox(width: 6),
              pw.Text('$key (Rs. ${val.toStringAsFixed(0)})', style: const pw.TextStyle(fontSize: 11)),
            ]
          )
        );
        colorIdx++;
      }
    });

    // 2. Build the Multi-Page PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Text("Kuber AI Financial Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.Text("Generated on: ${DateTime.now().toString().substring(0, 16)}", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
            pw.SizedBox(height: 24),

            // Metrics Section
            pw.Text("Financial Overview", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text("Total Income: Rs. ${income.toStringAsFixed(2)}", style: pw.TextStyle(color: PdfColors.green700, fontSize: 14)),
                  pw.SizedBox(height: 4),
                  pw.Text("Total Expense: Rs. ${expense.toStringAsFixed(2)}", style: pw.TextStyle(color: PdfColors.red700, fontSize: 14)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text("Net Savings: Rs. ${savings.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.SizedBox(height: 4),
                  pw.Text("Top Spend: $topSpend", style: const pw.TextStyle(fontSize: 14)),
                ]),
              ],
            ),
            pw.SizedBox(height: 24),

            // PDF Chart + Dynamic Wrap Legend
            if (pieDatasets.isNotEmpty) ...[
              pw.Text("Expense Breakdown", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    height: 140,
                    width: 140,
                    child: pw.Chart(grid: pw.PieGrid(), datasets: pieDatasets),
                  ),
                  pw.SizedBox(width: 24),
                  // 👇 FIX: spacing (horizontal) and runSpacing (vertical) handle the flow automatically 👇
                  pw.Expanded(
                    child: pw.Wrap(spacing: 16, runSpacing: 12, children: legendItems)
                  )
                ]
              ),
              pw.SizedBox(height: 32),
            ],

            // AI Insights Section
            pw.Text("Kuber AI Insights", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Text(aiText, style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 12)),
            ),
            pw.SizedBox(height: 32),

            // Transactions Table
            pw.Text("Transaction History", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 8),
            
            // PDF Table Engine
           // PDF Table Engine
            pw.TableHelper.fromTextArray(
              context: context,
              // 👇 Removed headerRepeat: true here! It's automatic now. 👇
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
              headerHeight: 28,
              cellHeight: 22,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
              },
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headers: ['Date', 'Narration', 'Category', 'Amount (Rs)'],
              data: txs.map((tx) {
                final isDebit = (tx['debit'] ?? 0) > 0;
                final amount = isDebit ? "-${tx['debit']}" : "+${tx['credit']}";
                return [
                  tx['date'] ?? '',
                  tx['narration'] ?? 'Unknown',
                  tx['category'] ?? '',
                  amount
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    // Save and Share
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Kuber_AI_Report.pdf");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: "Check out my AI Financial Report generated by Kuber!");
  }

  // --- HELPER WIDGETS ---
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
              Expanded(child: Text(category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(BuildContext context, Map<String, dynamic> categories) {
    int colorIndex = 0;
    final List<Color> colors = [AppColors.accentBlue, Colors.orangeAccent, Colors.purpleAccent, Colors.redAccent, Colors.tealAccent, Colors.indigoAccent];
    final validCategories = categories.entries.where((e) => (e.value ?? 0) > 0);
    return validCategories.map((entry) {
      return PieChartSectionData(
        color: colors[colorIndex++ % colors.length], value: (entry.value ?? 0).toDouble(), title: entry.key, radius: 45, titlePositionPercentageOffset: 1.5,
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

  void _showTransactionDetails(BuildContext context, Map<String, dynamic> tx, bool isDebit, double amount, String category, String date, Color bgColor, Color textColor, Color subTextColor) {
    final double balance = (tx['balance'] ?? 0).toDouble();
    showModalBottomSheet(
      context: context, backgroundColor: bgColor, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return Padding(
          padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 32.0, bottom: 32.0 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(radius: 36, backgroundColor: isDebit ? Colors.redAccent.withOpacity(0.15) : Colors.greenAccent.withOpacity(0.15), child: Icon(_getCategoryIcon(category), color: isDebit ? Colors.redAccent : Colors.greenAccent, size: 36)),
              const SizedBox(height: 16),
              Text("${isDebit ? '-' : '+'} ₹${amount.toStringAsFixed(2)}", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDebit ? Colors.redAccent : Colors.greenAccent)),
              const SizedBox(height: 8),
              Text(tx['narration'] ?? 'Unknown', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 32),
              Divider(color: subTextColor.withOpacity(0.3), thickness: 1),
              const SizedBox(height: 16),
              _buildDetailRow("Category", category, Icons.category_rounded, textColor, subTextColor),
              const SizedBox(height: 16),
              _buildDetailRow("Date", date.isNotEmpty ? date : "N/A", Icons.calendar_today_rounded, textColor, subTextColor),
              const SizedBox(height: 16),
              _buildDetailRow("Type", isDebit ? "Debit" : "Credit", Icons.swap_horiz_rounded, textColor, subTextColor),
              if (balance > 0) ...[const SizedBox(height: 16), _buildDetailRow("Balance", "₹${balance.toStringAsFixed(2)}", Icons.account_balance_wallet_rounded, textColor, subTextColor)],
              const SizedBox(height: 36),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Close", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))))
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color textColor, Color subTextColor) {
    return Row(children: [Icon(icon, size: 20, color: subTextColor), const SizedBox(width: 12), Text(label, style: TextStyle(fontSize: 14, color: subTextColor, fontWeight: FontWeight.w500)), const Spacer(), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor))]);
  }
}