import 'package:flutter/material.dart';
import 'package:flutter_tugas_uas/Components/custom_bottom_nav.dart';
import 'package:flutter_tugas_uas/Components/page_header.dart';
import 'package:flutter_tugas_uas/Components/custom_dialogs.dart';
import 'package:flutter_tugas_uas/Database/database_helper.dart';
import 'package:flutter_tugas_uas/Services/auth_service.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _financialSummary;
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final db = DatabaseHelper.instance;

      // Get financial summary
      final summary = await db.getFinancialSummary(userId);

      // Get recent transactions (last 5)
      final transactions = await db.getTransactions(userId, limit: 5);

      setState(() {
        _financialSummary = summary;
        _recentTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E88E5),
        onPressed: () =>
            CustomDialogs.showAddTransaction(context, onSuccess: _loadData),
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  PageHeader(
                    title: 'Beranda',
                    subtitle: 'Ringkasan keuangan Anda',
                    icon: Icons.home,
                    extra: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Saldo',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(
                            _financialSummary?['total_balance'] ?? 0,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                      children: [
                        // Summary Cards
                        Row(
                          children: [
                            _buildInfoCard(
                              'Pemasukan',
                              _financialSummary?['total_income'] ?? 0,
                              Icons.trending_up,
                              Colors.green,
                            ),
                            const SizedBox(width: 12),
                            _buildInfoCard(
                              'Pengeluaran',
                              _financialSummary?['total_expense'] ?? 0,
                              Icons.trending_down,
                              Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Transaksi Terakhir',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263238),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/transaksi'),
                              child: const Text('Lihat Semua'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_recentTransactions.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: const [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Belum ada transaksi',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._recentTransactions.map(
                            (t) => _buildTransactionItem(t),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(
    String label,
    dynamic amount,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              _formatCurrency(amount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isIncome = transaction['type'] == 'income';
    final amount = transaction['amount'] as num;
    final color = _getColorFromHex(transaction['color'] as String);
    final icon = _getIconFromString(transaction['icon'] as String);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['description'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction['category_name']} • ${_formatDate(transaction['date'] as String)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'} ${_formatCurrency(amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount is String ? double.parse(amount) : amount);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final formatter = DateFormat('d MMM yyyy, HH:mm:ss', 'id');
      return formatter.format(date);
    } catch (e) {
      return dateStr;
    }
  }

  IconData _getIconFromString(String iconName) {
    const iconMap = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'shopping_cart': Icons.shopping_cart,
      'movie': Icons.movie,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'receipt': Icons.receipt,
      'more_horiz': Icons.more_horiz,
      'work': Icons.work,
      'star': Icons.star,
      'trending_up': Icons.trending_up,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}
