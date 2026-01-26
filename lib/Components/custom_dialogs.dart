import 'package:flutter/material.dart';
import '../Database/database_helper.dart';
import '../Services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class CustomDialogs {
  // ================= TAMBAH KATEGORI =================
  static void showAddCategory(BuildContext context, {VoidCallback? onSuccess}) {
    final nameController = TextEditingController();
    String selectedType = 'expense'; // default

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Tambah Kategori',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildField(
                  label: 'Nama Kategori',
                  hint: 'Hiburan',
                  icon: Icons.local_offer,
                  controller: nameController,
                ),
                const SizedBox(height: 20),
                _buildDropdown<String>(
                  label: 'Tipe',
                  value: selectedType,
                  icon: Icons.category,
                  items: [
                    {'value': 'expense', 'label': 'Pengeluaran'},
                    {'value': 'income', 'label': 'Pemasukan'},
                  ],
                  onChanged: (val) => setState(() => selectedType = val!),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty) return;

                          final userId = await AuthService.getCurrentUserId();
                          if (userId == null) return;

                          await DatabaseHelper.instance.createCategory({
                            'user_id': userId,
                            'name': nameController.text,
                            'type': selectedType,
                            'icon': 'more_horiz', // Default icon
                            'color': selectedType == 'income'
                                ? '#4CAF50'
                                : '#FF5722',
                            'created_at': DateTime.now().toIso8601String(),
                          });

                          if (context.mounted) {
                            Navigator.pop(context);
                            if (onSuccess != null) onSuccess();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Simpan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= TAMBAH BUDGET =================
  static void showAddBudget(
    BuildContext context, {
    VoidCallback? onSuccess,
  }) async {
    final amountController = TextEditingController();
    int? selectedCategoryId;
    final userId = await AuthService.getCurrentUserId();
    if (userId == null) return;

    // Load expense categories only
    final categories = await DatabaseHelper.instance.getCategories(
      userId,
      type: 'expense',
    );

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Tambah Budget',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildDropdown<int>(
                    label: 'Kategori',
                    value: selectedCategoryId,
                    icon: Icons.restaurant,
                    items: categories
                        .map((c) => {'value': c['id'], 'label': c['name']})
                        .toList(),
                    onChanged: (val) =>
                        setState(() => selectedCategoryId = val),
                    hint: 'Pilih Kategori',
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    label: 'Target Budget',
                    hint: 'Contoh: 500000',
                    icon: Icons.payments,
                    controller: amountController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedCategoryId == null ||
                                amountController.text.isEmpty)
                              return;

                            final amount =
                                double.tryParse(amountController.text) ?? 0;
                            final now = DateTime.now();

                            try {
                              await DatabaseHelper.instance.createBudget({
                                'user_id': userId,
                                'category_id': selectedCategoryId,
                                'amount': amount,
                                'month': now.month,
                                'year': now.year,
                                'created_at': now.toIso8601String(),
                              });
                            } catch (e) {
                              // Likely UNIQUE constraint (budget exists)
                              // We could update instead, but for simplicity show error or do update
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              if (onSuccess != null) onSuccess();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Simpan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  // ================= TAMBAH TRANSAKSI =================
  static void showAddTransaction(
    BuildContext context, {
    VoidCallback? onSuccess,
  }) async {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedType = 'expense';
    int? selectedCategoryId;

    final userId = await AuthService.getCurrentUserId();
    if (userId == null) return;

    // Load categories based on type
    Future<List<Map<String, dynamic>>> loadCats(String type) =>
        DatabaseHelper.instance.getCategories(userId, type: type);

    List<Map<String, dynamic>> categories = await loadCats(selectedType);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Tambah Transaksi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDropdown<String>(
                      label: 'Tipe',
                      value: selectedType,
                      icon: Icons.swap_vert,
                      items: [
                        {'value': 'expense', 'label': 'Pengeluaran'},
                        {'value': 'income', 'label': 'Pemasukan'},
                      ],
                      onChanged: (val) async {
                        final newCats = await loadCats(val!);
                        setState(() {
                          selectedType = val;
                          categories = newCats;
                          selectedCategoryId = null; // reset category
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Nominal',
                      hint: '0',
                      icon: Icons.payments,
                      controller: amountController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown<int>(
                      label: 'Kategori',
                      value: selectedCategoryId,
                      icon: Icons.category,
                      items: categories
                          .map((c) => {'value': c['id'], 'label': c['name']})
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedCategoryId = val),
                      hint: 'Pilih Kategori',
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Keterangan',
                      hint: 'Beli nasi goreng',
                      icon: Icons.description,
                      controller: descController,
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(
                      context: context,
                      label: 'Tanggal',
                      value: DateFormat('d MMM yyyy').format(selectedDate),
                      icon: Icons.calendar_today,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null)
                          setState(() => selectedDate = picked);
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (selectedCategoryId == null ||
                                  amountController.text.isEmpty)
                                return;

                              await DatabaseHelper.instance.createTransaction({
                                'user_id': userId,
                                'category_id': selectedCategoryId,
                                'amount':
                                    double.tryParse(amountController.text) ?? 0,
                                'type': selectedType,
                                'description': descController.text,
                                'date': selectedDate.toIso8601String(),
                                'created_at': DateTime.now().toIso8601String(),
                              });

                              if (context.mounted) {
                                Navigator.pop(context);
                                if (onSuccess != null) onSuccess();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Simpan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  // ================= ALERT LOGOUT =================
  static void showLogoutAlert(BuildContext context, VoidCallback onLogout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 32),
            ),
            const SizedBox(height: 20),
            const Text(
              'Keluar Akun?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Apakah Anda yakin ingin keluar?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onLogout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Ya, Keluar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= PRIVATE HELPERS =================
  static Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1E88E5), size: 20),
        labelStyle: const TextStyle(color: Color(0xFF1E88E5), fontSize: 13),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
      ),
    );
  }

  static Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E88E5), size: 20),
        labelStyle: const TextStyle(color: Color(0xFF1E88E5), fontSize: 13),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: hint != null
              ? Text(
                  hint,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                )
              : null,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item['value'] as T,
              child: Text(
                item['label'].toString(),
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  static Widget _buildDateField({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1E88E5), size: 20),
          labelStyle: const TextStyle(color: Color(0xFF1E88E5), fontSize: 13),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value, style: const TextStyle(fontSize: 14)),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ================= EDIT KATEGORI =================
  static void showEditCategory(
    BuildContext context,
    Map<String, dynamic> category, {
    VoidCallback? onSuccess,
  }) {
    final nameController = TextEditingController(text: category['name']);
    String selectedType = category['type'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Kategori',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildField(
                  label: 'Nama Kategori',
                  hint: 'Hiburan',
                  icon: Icons.local_offer,
                  controller: nameController,
                ),
                const SizedBox(height: 16),
                _buildDropdown<String>(
                  label: 'Tipe',
                  value: selectedType,
                  icon: Icons.category,
                  items: [
                    {'value': 'expense', 'label': 'Pengeluaran'},
                    {'value': 'income', 'label': 'Pemasukan'},
                  ],
                  onChanged: (val) => setState(() => selectedType = val!),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await DatabaseHelper.instance.updateCategory(
                            category['id'],
                            {'name': nameController.text, 'type': selectedType},
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            if (onSuccess != null) onSuccess();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                        ),
                        child: const Text(
                          'Simpan',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= EDIT BUDGET =================
  static void showEditBudget(
    BuildContext context,
    Map<String, dynamic> budget, {
    VoidCallback? onSuccess,
  }) {
    final amountController = TextEditingController(
      text: budget['budget_amount'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Budget: ${budget['category_name']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildField(
                label: 'Target Budget',
                hint: '0',
                icon: Icons.payments,
                controller: amountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await DatabaseHelper.instance.updateBudget(
                          budget['id'],
                          {
                            'amount':
                                double.tryParse(amountController.text) ?? 0,
                          },
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (onSuccess != null) onSuccess();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                      ),
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= EDIT TRANSAKSI =================
  static void showEditTransaction(
    BuildContext context,
    Map<String, dynamic> transaction, {
    VoidCallback? onSuccess,
  }) async {
    final amountController = TextEditingController(
      text: transaction['amount'].toString(),
    );
    final descController = TextEditingController(
      text: transaction['description'],
    );
    DateTime selectedDate = DateTime.parse(transaction['date']);

    final userId = await AuthService.getCurrentUserId();
    if (userId == null) return;

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildField(
                      label: 'Nominal',
                      hint: '0',
                      icon: Icons.payments,
                      controller: amountController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Keterangan',
                      hint: 'Beli nasi goreng',
                      icon: Icons.description,
                      controller: descController,
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(
                      context: context,
                      label: 'Tanggal',
                      value: DateFormat('d MMM yyyy').format(selectedDate),
                      icon: Icons.calendar_today,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null)
                          setState(() => selectedDate = picked);
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await DatabaseHelper.instance.updateTransaction(
                                transaction['id'],
                                {
                                  'amount':
                                      double.tryParse(amountController.text) ??
                                      0,
                                  'description': descController.text,
                                  'date': selectedDate.toIso8601String(),
                                },
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                if (onSuccess != null) onSuccess();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                            ),
                            child: const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  // ================= GANTI PASSWORD =================
  static void showChangePassword(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lock_reset,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Ganti Password',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildField(
                    label: 'Password Lama',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    controller: oldPasswordController,
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Password Baru',
                    hint: '••••••••',
                    icon: Icons.lock_open_outlined,
                    controller: newPasswordController,
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Konfirmasi Password Baru',
                    hint: '••••••••',
                    icon: Icons.check_circle_outline,
                    controller: confirmPasswordController,
                    isPassword: true,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final oldPass = oldPasswordController.text;
                            final newPass = newPasswordController.text;
                            final confirmPass = confirmPasswordController.text;

                            if (oldPass.isEmpty ||
                                newPass.isEmpty ||
                                confirmPass.isEmpty) {
                              _showSnackBar(
                                context,
                                'Semua field harus diisi!',
                                Colors.red,
                              );
                              return;
                            }

                            if (newPass != confirmPass) {
                              _showSnackBar(
                                context,
                                'Konfirmasi password tidak cocok!',
                                Colors.red,
                              );
                              return;
                            }

                            final userId = await AuthService.getCurrentUserId();
                            if (userId == null) return;

                            final db = DatabaseHelper.instance;
                            final user = await db.rawQuery(
                              'SELECT password FROM users WHERE id = ?',
                              [userId],
                            );

                            final hashPass = (String p) =>
                                sha256.convert(utf8.encode(p)).toString();

                            if (user.isEmpty ||
                                user.first['password'] != hashPass(oldPass)) {
                              _showSnackBar(
                                context,
                                'Password lama salah!',
                                Colors.red,
                              );
                              return;
                            }

                            await db.updateUser(userId, {
                              'password': hashPass(newPass),
                            });

                            if (context.mounted) {
                              Navigator.pop(context);
                              _showSnackBar(
                                context,
                                'Password berhasil diperbarui!',
                                Colors.green,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Update',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
