import 'package:expenses_tracker/models/expense.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';

Future<Database> getDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  final db = await sql.openDatabase(
    path.join(dbPath, 'expenses.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE user_expenses(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, amount REAL, date TEXT, category TEXT)',
      );
    },
    version: 1,
  );
  return db;
}

class ExpenseDatabase {
  static Future<void> insertExpense(Expense expense) async {
    final db = await getDatabase();
    await db.insert(
      'user_expenses',
      {
        'title': expense.title,
        'amount': expense.amount,
        'date': expense.date.toIso8601String(),
        'category': expense.category.name,
      },
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static Future<List<Expense>> getAllExpenses() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('user_expenses');

    return List.generate(maps.length, (i) {
      return Expense(
        title: maps[i]['title'],
        amount: maps[i]['amount'],
        date: DateTime.parse(maps[i]['date']),
        category: Category.values.firstWhere(
          (cat) => cat.name == maps[i]['category'],
          orElse: () => Category.others,
        ),
      );
    });
  }

  static Future<void> deleteExpense(String title, DateTime date) async {
    final db = await getDatabase();
    await db.delete(
      'user_expenses',
      where: 'title = ? AND date = ?',
      whereArgs: [title, date.toIso8601String()],
    );
  }

  static Future<void> updateExpense(
    Expense oldExpense,
    Expense newExpense,
  ) async {
    final db = await getDatabase();
    await db.update(
      'user_expenses',
      {
        'title': newExpense.title,
        'amount': newExpense.amount,
        'date': newExpense.date.toIso8601String(),
        'category': newExpense.category.name,
      },
      where: 'title = ? AND date = ?',
      whereArgs: [oldExpense.title, oldExpense.date.toIso8601String()],
    );
  }

  static Future<void> clearAllExpenses() async {
    final db = await getDatabase();
    await db.delete('user_expenses');
  }
}
