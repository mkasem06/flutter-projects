import 'package:expenses_tracker/widgets/chart/chart.dart';
import 'package:expenses_tracker/widgets/expenses_list/expenses_list.dart';
import 'package:expenses_tracker/widgets/new_expense.dart';
import 'package:expenses_tracker/database/expense_database.dart';
import 'package:flutter/material.dart';
import 'package:expenses_tracker/models/expense.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key, this.newExpense});
  final Expense? newExpense;

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  final List<Expense> registeredExpenses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    try {
      final loadedExpenses = await ExpenseDatabase.getAllExpenses();
      setState(() {
        registeredExpenses.clear();
        registeredExpenses.addAll(loadedExpenses);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // print('Error loading expenses: $e');
    }
  }

  void openAddButtonOverlay() {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (ctx) => NewExpense(addNewExpense),
    );
  }

  void addNewExpense(Expense expense) {
    setState(() {
      registeredExpenses.add(expense);
    });
  }

  void removeExpense(Expense expense) async {
    final expenseIndex = registeredExpenses.indexOf(expense);
    setState(() {
      registeredExpenses.remove(expense);
    });

    // Remove from database
    await ExpenseDatabase.deleteExpense(expense.title, expense.date);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Expense Removed'),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            setState(() {
              registeredExpenses.insert(expenseIndex, expense);
            });
            // Re-add to database
            await ExpenseDatabase.insertExpense(expense);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Show loading indicator while loading expenses
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Expense Tracker'),
          actions: [
            IconButton(
              onPressed: openAddButtonOverlay,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            onPressed: openAddButtonOverlay,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: width < 600
          ? Column(
              children: [
                Chart(expenses: registeredExpenses),
                Expanded(
                  child: registeredExpenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Start adding expenses now!',
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              ElevatedButton.icon(
                                onPressed: openAddButtonOverlay,
                                label: const Text('Add Expense'),
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        )
                      : ExpensesList(
                          expenses: registeredExpenses,
                          onRemoveExpense: removeExpense,
                        ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Chart(expenses: registeredExpenses),
                ),
                Expanded(
                  child: registeredExpenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Start adding expenses now!',
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              ElevatedButton.icon(
                                onPressed: openAddButtonOverlay,
                                label: const Text('Add Expense'),
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        )
                      : ExpensesList(
                          expenses: registeredExpenses,
                          onRemoveExpense: removeExpense,
                        ),
                ),
              ],
            ),
    );
  }
}
