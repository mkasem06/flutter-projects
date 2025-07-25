import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final uuid = const Uuid();
final formatter = DateFormat.yMd();

enum Category {
  food,
  transportation,
  leisure,
  donation,
  health,
  grocery,
  others,
}

const categoryIcons = {
  Category.food: Icons.lunch_dining_rounded,
  Category.transportation: Icons.train_outlined,
  Category.leisure: Icons.movie_creation_outlined,
  Category.donation: Icons.handshake_outlined,
  Category.health: Icons.healing_outlined,
  Category.grocery: Icons.shopping_cart_outlined,
  Category.others: Icons.miscellaneous_services_rounded,
};

class Expense {
  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  }) : id = uuid.v4();

  final String title;
  final double amount;
  final String id;
  final DateTime date;
  final Category category;

  String get dateFormatter {
    return formatter.format(date);
  }
}

class ExpenseBucket {
  ExpenseBucket({
    required this.expenses,
    required this.category,
  });
  final Category category;
  final List<Expense> expenses;

  ExpenseBucket.forCategory(List<Expense> allExpenses, this.category)
    : expenses = allExpenses
          .where((expense) => expense.category == category)
          .toList();

  double get totalExpenses {
    double sum = 0;
    for (final expense in expenses) {
      sum += expense.amount;
    }
    return sum;
  }
}
