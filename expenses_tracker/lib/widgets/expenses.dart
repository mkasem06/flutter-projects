import 'package:expenses_tracker/widgets/chart/chart.dart';
import 'package:expenses_tracker/widgets/expenses_list/expenses_list.dart';
import 'package:expenses_tracker/widgets/new_expense.dart';
import 'package:expenses_tracker/database/expense_database.dart';
import 'package:flutter/material.dart';
import 'package:expenses_tracker/models/expense.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key, this.newExpense});
  final Expense? newExpense;

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> with TickerProviderStateMixin {
  final List<Expense> registeredExpenses = [];
  bool isLoading = true;
  late AnimationController _fabAnimationController;
  late AnimationController _loadingAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _fabAnimation =
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _fabAnimationController,
            curve: Curves.elasticOut,
          ),
        );

    _loadingAnimation =
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _loadingAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    loadExpenses();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  Future<void> loadExpenses() async {
    try {
      final loadedExpenses = await ExpenseDatabase.getAllExpenses();
      setState(() {
        registeredExpenses.clear();
        registeredExpenses.addAll(loadedExpenses);
        isLoading = false;
      });
      _fabAnimationController.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _fabAnimationController.forward();
    }
  }

  void openAddButtonOverlay() {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: NewExpense(addNewExpense),
      ),
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

    await ExpenseDatabase.deleteExpense(expense.title, expense.date);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.onError,
            ),
            const SizedBox(width: 8),
            const Text('Expense Removed'),
          ],
        ),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () async {
            setState(() {
              registeredExpenses.insert(expenseIndex, expense);
            });
            await ExpenseDatabase.insertExpense(expense);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AnimationLimiter(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Start adding expenses now!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: openAddButtonOverlay,
              label: const Text('Add Expense'),
              icon: const Icon(Icons.add),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _loadingAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_loadingAnimation.value * 0.1),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Loading your expenses...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Expense Tracker'),
        ),
        body: Center(child: _buildLoadingIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
      ),
      body: width < 600
          ? Column(
              children: [
                AnimationConfiguration.staggeredList(
                  position: 0,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Chart(expenses: registeredExpenses),
                    ),
                  ),
                ),
                Expanded(
                  child: registeredExpenses.isEmpty
                      ? _buildEmptyState()
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
                  child: AnimationConfiguration.staggeredList(
                    position: 0,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      horizontalOffset: -50.0,
                      child: FadeInAnimation(
                        child: Chart(expenses: registeredExpenses),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: registeredExpenses.isEmpty
                      ? _buildEmptyState()
                      : ExpensesList(
                          expenses: registeredExpenses,
                          onRemoveExpense: removeExpense,
                        ),
                ),
              ],
            ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: openAddButtonOverlay,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
