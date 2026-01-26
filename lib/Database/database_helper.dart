import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add is_default column to categories table
      await db.execute(
        'ALTER TABLE categories ADD COLUMN is_default INTEGER DEFAULT 0',
      );

      // Optionally mark existing categories as default if they match common names
      // but for now, we'll let existing ones stay as is OR mark all as non-default.
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        name $textType,
        email $textType UNIQUE,
        password $textType,
        created_at $textType,
        updated_at $textType
      )
    ''');

    // Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        user_id $intType,
        name $textType,
        type $textType CHECK(type IN ('income', 'expense')),
        icon $textType,
        color $textType,
        is_default INTEGER DEFAULT 0,
        created_at $textType,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Create budgets table
    await db.execute('''
      CREATE TABLE budgets (
        id $idType,
        user_id $intType,
        category_id $intType,
        amount $realType,
        month $intType CHECK(month >= 1 AND month <= 12),
        year $intType,
        created_at $textType,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
        UNIQUE(user_id, category_id, month, year)
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        user_id $intType,
        category_id $intType,
        amount $realType,
        type $textType CHECK(type IN ('income', 'expense')),
        description $textType,
        date $textType,
        created_at $textType,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute('''
      CREATE INDEX idx_transactions_user_date 
      ON transactions(user_id, date)
    ''');

    await db.execute('''
      CREATE INDEX idx_categories_user_type 
      ON categories(user_id, type)
    ''');

    await db.execute('''
      CREATE INDEX idx_budgets_user_period 
      ON budgets(user_id, year, month)
    ''');
  }

  // ==================== USER OPERATIONS ====================

  Future<int> createUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.update('users', user, where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CATEGORY OPERATIONS ====================

  Future<int> createCategory(Map<String, dynamic> category) async {
    final db = await instance.database;
    return await db.insert('categories', category);
  }

  Future<List<Map<String, dynamic>>> getCategories(
    int userId, {
    String? type,
  }) async {
    final db = await instance.database;
    if (type != null) {
      return await db.query(
        'categories',
        where: 'user_id = ? AND type = ?',
        whereArgs: [userId, type],
        orderBy: 'name ASC',
      );
    }
    return await db.query(
      'categories',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'type ASC, name ASC',
    );
  }

  Future<int> updateCategory(int id, Map<String, dynamic> category) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      category,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== BUDGET OPERATIONS ====================

  Future<int> createBudget(Map<String, dynamic> budget) async {
    final db = await instance.database;
    return await db.insert('budgets', budget);
  }

  Future<List<Map<String, dynamic>>> getBudgets(
    int userId,
    int year,
    int month,
  ) async {
    final db = await instance.database;
    return await db.rawQuery(
      '''
      SELECT 
        b.id,
        b.amount as budget_amount,
        c.id as category_id,
        c.name as category_name,
        c.icon,
        c.color,
        COALESCE(SUM(t.amount), 0) as used_amount
      FROM budgets b
      JOIN categories c ON b.category_id = c.id
      LEFT JOIN transactions t ON t.category_id = c.id 
        AND strftime('%Y', t.date) = ?
        AND strftime('%m', t.date) = ?
        AND t.type = 'expense'
      WHERE b.user_id = ?
        AND b.year = ?
        AND b.month = ?
      GROUP BY b.id, b.amount, c.id, c.name, c.icon, c.color
    ''',
      [year.toString(), month.toString().padLeft(2, '0'), userId, year, month],
    );
  }

  Future<Map<String, dynamic>> getBudgetSummary(
    int userId,
    int year,
    int month,
  ) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT 
        COALESCE(SUM(b.amount), 0) as total_budget,
        COALESCE(SUM(t.amount), 0) as total_used
      FROM budgets b
      LEFT JOIN transactions t ON t.category_id = b.category_id
        AND t.user_id = b.user_id
        AND strftime('%Y', t.date) = ?
        AND strftime('%m', t.date) = ?
        AND t.type = 'expense'
      WHERE b.user_id = ?
        AND b.year = ?
        AND b.month = ?
    ''',
      [year.toString(), month.toString().padLeft(2, '0'), userId, year, month],
    );
    return result.first;
  }

  Future<int> updateBudget(int id, Map<String, dynamic> budget) async {
    final db = await instance.database;
    return await db.update('budgets', budget, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBudget(int id) async {
    final db = await instance.database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== TRANSACTION OPERATIONS ====================

  Future<int> createTransaction(Map<String, dynamic> transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction);
  }

  Future<List<Map<String, dynamic>>> getTransactions(
    int userId, {
    String? type,
    int? year,
    int? month,
    int? limit,
  }) async {
    final db = await instance.database;
    String whereClause = 't.user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (type != null) {
      whereClause += ' AND t.type = ?';
      whereArgs.add(type);
    }

    if (year != null && month != null) {
      whereClause +=
          " AND strftime('%Y', t.date) = ? AND strftime('%m', t.date) = ?";
      whereArgs.add(year.toString());
      whereArgs.add(month.toString().padLeft(2, '0'));
    }

    String query =
        '''
      SELECT 
        t.id,
        t.amount,
        t.type,
        t.description,
        t.date,
        c.name as category_name,
        c.icon,
        c.color
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE $whereClause
      ORDER BY t.date DESC, t.created_at DESC
    ''';

    if (limit != null) {
      query += ' LIMIT $limit';
    }

    return await db.rawQuery(query, whereArgs);
  }

  Future<Map<String, dynamic>> getFinancialSummary(int userId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as total_income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as total_expense,
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END), 0) as total_balance
      FROM transactions
      WHERE user_id = ?
    ''',
      [userId],
    );
    return result.first;
  }

  Future<Map<String, dynamic>> getMonthlyFinancialSummary(
    int userId,
    int year,
    int month,
  ) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as total_income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as total_expense
      FROM transactions
      WHERE user_id = ?
        AND strftime('%Y', date) = ?
        AND strftime('%m', date) = ?
    ''',
      [userId, year.toString(), month.toString().padLeft(2, '0')],
    );
    return result.first;
  }

  Future<int> updateTransaction(
    int id,
    Map<String, dynamic> transaction,
  ) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      transaction,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== SEED DATA ====================

  Future<void> seedDefaultCategories(int userId) async {
    final now = DateTime.now().toIso8601String();

    // Default expense categories
    final expenseCategories = [
      {'name': 'Makanan & Minuman', 'icon': 'restaurant', 'color': '#FF5722'},
      {'name': 'Transportasi', 'icon': 'directions_car', 'color': '#2196F3'},
      {'name': 'Belanja', 'icon': 'shopping_cart', 'color': '#9C27B0'},
      {'name': 'Hiburan', 'icon': 'movie', 'color': '#E91E63'},
      {'name': 'Kesehatan', 'icon': 'local_hospital', 'color': '#4CAF50'},
      {'name': 'Pendidikan', 'icon': 'school', 'color': '#FFC107'},
      {'name': 'Tagihan', 'icon': 'receipt', 'color': '#607D8B'},
      {'name': 'Lainnya', 'icon': 'more_horiz', 'color': '#795548'},
    ];

    // Default income categories
    final incomeCategories = [
      {'name': 'Gaji', 'icon': 'work', 'color': '#4CAF50'},
      {'name': 'Bonus', 'icon': 'star', 'color': '#FFD700'},
      {'name': 'Investasi', 'icon': 'trending_up', 'color': '#00BCD4'},
      {'name': 'Lainnya', 'icon': 'more_horiz', 'color': '#8BC34A'},
    ];

    for (var cat in expenseCategories) {
      await createCategory({
        'user_id': userId,
        'name': cat['name'],
        'type': 'expense',
        'icon': cat['icon'],
        'color': cat['color'],
        'is_default': 1,
        'created_at': now,
      });
    }

    for (var cat in incomeCategories) {
      await createCategory({
        'user_id': userId,
        'name': cat['name'],
        'type': 'income',
        'icon': cat['icon'],
        'color': cat['color'],
        'is_default': 1,
        'created_at': now,
      });
    }
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String query, [
    List<dynamic>? arguments,
  ]) async {
    final db = await instance.database;
    return await db.rawQuery(query, arguments);
  }

  // ==================== CLOSE DATABASE ====================

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
