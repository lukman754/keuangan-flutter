import 'package:flutter/material.dart';
import 'package:flutter_tugas_uas/Components/custom_bottom_nav.dart';
import 'package:flutter_tugas_uas/Components/page_header.dart';
import 'package:flutter_tugas_uas/Components/custom_dialogs.dart';
import 'package:flutter_tugas_uas/Database/database_helper.dart';
import 'package:flutter_tugas_uas/Services/auth_service.dart';
import 'package:intl/intl.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  List<Map<String, dynamic>> _budgets = [];
  Map<String, dynamic>? _budgetSummary;
  bool _isLoading = true;
  int? _userId;

  // Current month and year
  late int _currentMonth;
  late int _currentYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = now.month;
    _currentYear = now.year;
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);

    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final db = DatabaseHelper.instance;

      // Get budgets for current month
      final budgets = await db.getBudgets(userId, _currentYear, _currentMonth);

      // Get budget summary
      final summary = await db.getBudgetSummary(
        userId,
        _currentYear,
        _currentMonth,
      );

      setState(() {
        _userId = userId;
        _budgets = budgets;
        _budgetSummary = summary;
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

  Future<void> _deleteBudget(int budgetId, String categoryName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Budget'),
        content: Text('Yakin ingin menghapus budget "$categoryName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final db = DatabaseHelper.instance;
        await db.deleteBudget(budgetId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget berhasil dihapus')),
          );
        }

        _loadBudgets();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  String _formatCurrency(dynamic amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount is String ? double.parse(amount) : amount);
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
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
    };
    return iconMap[iconName] ?? Icons.category;
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final totalBudget = _budgetSummary?['total_budget'] ?? 0;
    final totalUsed = _budgetSummary?['total_used'] ?? 0;
    final remaining = totalBudget - totalUsed;
    final usagePercentage = totalBudget > 0
        ? (totalUsed / totalBudget * 100)
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E88E5),
        onPressed: () {
          CustomDialogs.showAddBudget(context, onSuccess: _loadBudgets);
        },
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
      body: Column(
        children: [
          PageHeader(
            title: 'Budget',
            subtitle: '${_getMonthName(_currentMonth)} $_currentYear',
            icon: Icons.account_balance_wallet,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadBudgets,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                      children: [
                        // Summary Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E88E5).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Budget',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatCurrency(totalBudget),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Terpakai',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatCurrency(totalUsed),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Sisa',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatCurrency(remaining),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: usagePercentage / 100,
                                  backgroundColor: Colors.white30,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    usagePercentage > 90
                                        ? Colors.red
                                        : usagePercentage > 70
                                        ? Colors.orange
                                        : Colors.white,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${usagePercentage.toStringAsFixed(1)}% terpakai',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Budget List Title
                        const Text(
                          'Budget per Kategori',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF263238),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Budget List
                        if (_budgets.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: const [
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Belum ada budget',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...List.generate(
                            _budgets.length,
                            (index) => _buildBudgetItem(_budgets[index]),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetItem(Map<String, dynamic> budget) {
    final budgetAmount = budget['budget_amount'] as num;
    final usedAmount = budget['used_amount'] as num;
    final remaining = budgetAmount - usedAmount;
    final percentage = budgetAmount > 0 ? (usedAmount / budgetAmount * 100) : 0;

    final color = _getColorFromHex(budget['color'] as String);
    final icon = _getIconFromString(budget['icon'] as String);

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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget['category_name'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatCurrency(usedAmount)} / ${_formatCurrency(budgetAmount)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: percentage > 90
                      ? Colors.red
                      : percentage > 70
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 90
                    ? Colors.red
                    : percentage > 70
                    ? Colors.orange
                    : color,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    CustomDialogs.showEditBudget(
                      context,
                      budget,
                      onSuccess: _loadBudgets,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.edit, color: Colors.blue, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _deleteBudget(
                    budget['id'] as int,
                    budget['category_name'] as String,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.delete, color: Colors.redAccent, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Hapus',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
