import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';

class DashboardScreen extends StatelessWidget {
  
  final Map<String, dynamic> analysisData;

  const DashboardScreen({super.key, required this.analysisData});

  @override
  Widget build(BuildContext context) {
    
    final String totalIncome = analysisData['total_income']?.toString() ?? '0.00';
    final String totalExpenses = analysisData['total_expenses']?.toString() ?? '0.00';
    final String aiInsight = analysisData['ai_insight'] ?? 'AI is analyzing your spending patterns...';
    
    
    final List<dynamic> rawTxns = analysisData['transactions'] ?? [];

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -50, left: -50,
            child: Container(
              width: 250, height: 250,
             decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00F2FE).withOpacity(0.05),
              boxShadow: [
               BoxShadow(
                color: const Color(0xFF00F2FE).withOpacity(0.08),
               blurRadius: 100,
               ),
              ],
             ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  FadeInUp(duration: const Duration(milliseconds: 400), 
                    child: _buildIncomeExpenseCard(totalIncome, totalExpenses)),
                  const SizedBox(height: 24),
                  FadeInUp(duration: const Duration(milliseconds: 600), 
                    child: _buildAIInsightCard(context, aiInsight)),
                  const SizedBox(height: 24),
                  FadeInUp(duration: const Duration(milliseconds: 700), 
                    child: _buildRecentTransactions(rawTxns)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Financial Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('AI Analysis Complete', style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildIncomeExpenseCard(String income, String expense) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Income', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                Text('₹$income', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.1)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Expenses', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text('₹$expense', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightCard(BuildContext context, String insight) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary.withOpacity(0.15), const Color(0xFF00F2FE).withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFF00F2FE), size: 20),
              SizedBox(width: 8),
              Text('AI Smart Insight', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 10),
          Text(insight, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<dynamic> txns) {
    if (txns.isEmpty) return const Text("No transactions found.");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Categorized Ledger', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: txns.length,
          itemBuilder: (context, index) {
            final item = txns[index];
            // Adjust these keys based on what your teammate's API actually returns!
            final title = item['narration'] ?? 'Unknown';
            final date = item['date'] ?? '';
            final amount = item['amount']?.toString() ?? '0.0';
            final isDebit = item['type'] == 'DEBIT';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF18181C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(date, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    isDebit ? '-₹$amount' : '+₹$amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDebit ? Colors.white.withOpacity(0.9) : Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}