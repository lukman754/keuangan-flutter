import 'package:flutter/material.dart';
import 'package:flutter_tugas_uas/Components/custom_bottom_nav.dart';
import 'package:flutter_tugas_uas/Components/page_header.dart';
import 'package:flutter_tugas_uas/Components/custom_dialogs.dart';
import 'package:flutter_tugas_uas/Database/database_helper.dart';
import 'package:flutter_tugas_uas/Services/auth_service.dart';
import 'package:intl/intl.dart';

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'Semua';
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final db = DatabaseHelper.instance;
      // Get all transactions for the selected month
      final transactions = await db.getTransactions(
        userId,
        year: _selectedDate.year,
        month: _selectedDate.month,
      );

      setState(() {
        _userId = userId;
        _transactions = transactions;
        _filterTransactions();
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

  void _changeMonth(int delta) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + delta);
    });
    _loadTransactions();
  }

  void _filterTransactions() {
    if (_selectedFilter == 'Semua') {
      _filteredTransactions = _transactions;
    } else {
      final type = _selectedFilter == 'Pengeluaran' ? 'expense' : 'income';
      _filteredTransactions = _transactions
          .where((t) => t['type'] == type)
          .toList();
    }
  }

  Future<void> _deleteTransaction(int transactionId, String description) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Transaksi'),
        content: Text('Yakin ingin menghapus transaksi "$description"?'),
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
        await db.deleteTransaction(transactionId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil dihapus')),
          );
        }

        _loadTransactions();
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
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount is String ? double.parse(amount) : amount);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final formatter = DateFormat('d MMM yyyy', 'id');
      return formatter.format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final formatter = DateFormat('d MMM yyyy, HH:mm:ss', 'id');
      return formatter.format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final formatter = DateFormat('HH:mm:ss', 'id');
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

  // Group transactions by date
  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate() {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (var transaction in _filteredTransactions) {
      final date = _formatDate(transaction['date'] as String);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(transaction);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = _groupTransactionsByDate();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E88E5),
        onPressed: () {
          CustomDialogs.showAddTransaction(
            context,
            onSuccess: _loadTransactions,
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
      body: Column(
        children: [
          PageHeader(
            title: 'Transaksi',
            subtitle: 'Riwayat transaksi Anda',
            icon: Icons.receipt_long,
            extra: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy', 'id').format(_selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _changeMonth(1),
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTransactions,
                    child: Column(
                      children: [
                        // Filter Buttons
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(child: _buildFilterChip('Semua')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildFilterChip('Pengeluaran')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildFilterChip('Pemasukan')),
                            ],
                          ),
                        ),

                        // Transaction List
                        Expanded(
                          child: _filteredTransactions.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.receipt_long_outlined,
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
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    100,
                                  ),
                                  itemCount: groupedTransactions.length,
                                  itemBuilder: (context, index) {
                                    final date = groupedTransactions.keys
                                        .elementAt(index);
                                    final transactions =
                                        groupedTransactions[date]!;

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Date Header
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            date,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF263238),
                                            ),
                                          ),
                                        ),
                                        // Transactions for this date
                                        ...transactions.map(
                                          (transaction) =>
                                              _buildTransactionItem(
                                                transaction,
                                              ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _filterTransactions();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E88E5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E88E5) : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
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
      child: Column(
        children: [
          Row(
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
                      '${transaction['category_name']} • ${_formatTime(transaction['date'] as String)}',
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    CustomDialogs.showEditTransaction(
                      context,
                      transaction,
                      onSuccess: _loadTransactions,
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
                  onTap: () => _deleteTransaction(
                    transaction['id'] as int,
                    transaction['description'] as String,
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
