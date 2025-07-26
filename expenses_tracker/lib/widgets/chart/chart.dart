import 'package:flutter/material.dart';
import 'package:expenses_tracker/widgets/chart/chart_bar.dart';
import 'package:expenses_tracker/models/expense.dart';

class Chart extends StatefulWidget {
  const Chart({super.key, required this.expenses});

  final List<Expense> expenses;

  @override
  State<Chart> createState() => _ChartState();
}

class _ChartState extends State<Chart> with TickerProviderStateMixin {
  late AnimationController _containerController;
  late AnimationController _titleController;
  late Animation<double> _containerAnimation;
  late Animation<double> _titleAnimation;
  late Animation<Offset> _titleSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    _containerController = AnimationController(
      duration: const Duration(milliseconds: 600), // Reduced
      vsync: this,
    );
    
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 500), // Reduced
      vsync: this,
    );

    _containerAnimation = CurvedAnimation(
      parent: _containerController,
      curve: Curves.easeOut, // Simpler curve
    );

    _titleAnimation = CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOut, // Simpler curve
    );

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3), // Reduced movement
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _containerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _titleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _containerController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  List<ExpenseBucket> get buckets {
    return [
      ExpenseBucket.forCategory(widget.expenses, Category.food),
      ExpenseBucket.forCategory(widget.expenses, Category.leisure),
      ExpenseBucket.forCategory(widget.expenses, Category.transportation),
      ExpenseBucket.forCategory(widget.expenses, Category.donation),
      ExpenseBucket.forCategory(widget.expenses, Category.others),
      ExpenseBucket.forCategory(widget.expenses, Category.health),
      ExpenseBucket.forCategory(widget.expenses, Category.grocery),
    ];
  }

  double get maxTotalExpense {
    double maxTotalExpense = 0;
    for (final bucket in buckets) {
      if (bucket.totalExpenses > maxTotalExpense) {
        maxTotalExpense = bucket.totalExpenses;
      }
    }
    return maxTotalExpense;
  }

  double get totalExpenses {
    return buckets.fold(0.0, (sum, bucket) => sum + bucket.totalExpenses);
  }

  // Category icons map
  final Map<Category, IconData> categoryIcons = {
    Category.food: Icons.lunch_dining,
    Category.leisure: Icons.movie,
    Category.transportation: Icons.directions_car,
    Category.donation: Icons.volunteer_activism,
    Category.others: Icons.category,
    Category.health: Icons.local_hospital,
    Category.grocery: Icons.local_grocery_store,
  };

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _containerAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _containerAnimation.value,
          child: Opacity(
            opacity: _containerAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(12), // Reduced from 16
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16), // Reduced from 20
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withAlpha(20), // Reduced opacity
                    theme.colorScheme.secondary.withAlpha(10),
                    theme.colorScheme.primary.withAlpha(5),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(30), // Reduced
                    blurRadius: 12, // Reduced from 20
                    offset: const Offset(0, 4), // Reduced from 8
                    spreadRadius: 1, // Reduced from 2
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16), // Added top padding to prevent cutoff
                child: Column(
                  children: [
                    // Animated title
                    SlideTransition(
                      position: _titleSlideAnimation,
                      child: AnimatedBuilder(
                        animation: _titleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _titleAnimation.value,
                            child: Opacity(
                              opacity: _titleAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withAlpha(30),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withAlpha(100),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.bar_chart_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Expense Overview',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Total amount display
                    AnimatedBuilder(
                      animation: _titleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _titleAnimation.value,
                          child: Opacity(
                            opacity: _titleAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? theme.colorScheme.surface.withAlpha(200)
                                    : Colors.white.withAlpha(150),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Total: \$${totalExpenses.toStringAsFixed(2)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Chart bars (removed title display)
                    Container(
                      height: 140, // Reduced from 200
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: buckets.map((bucket) {
                          return ChartBar(
                            fill: maxTotalExpense == 0
                                ? 0
                                : bucket.totalExpenses / maxTotalExpense,
                            category: bucket.category.name, // Pass category name for delay calculation
                            amount: bucket.totalExpenses,
                          );
                        }).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Category icons with smooth animations
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: buckets.asMap().entries.map((entry) {
                          final index = entry.key;
                          final bucket = entry.value;
                          
                          return Expanded(
                            child: AnimatedBuilder(
                              animation: _titleAnimation,
                              builder: (context, child) {
                                // Simplified staggered animation
                                final delay = index * 0.05; // Reduced delay
                                final animationValue = (_titleAnimation.value - delay).clamp(0.0, 1.0);
                                
                                return Opacity(
                                  opacity: animationValue,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    padding: const EdgeInsets.all(6), // Reduced padding
                                    decoration: BoxDecoration(
                                      color: (isDarkMode
                                              ? theme.colorScheme.secondary
                                              : theme.colorScheme.primary)
                                          .withAlpha(15), // Reduced opacity
                                      borderRadius: BorderRadius.circular(8), // Reduced radius
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          categoryIcons[bucket.category],
                                          color: isDarkMode
                                              ? theme.colorScheme.secondary
                                              : theme.colorScheme.primary,
                                          size: 16, // Reduced from 20
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          bucket.category.name.substring(0, 3).toUpperCase(), // Shortened
                                          style: TextStyle(
                                            fontSize: 7, // Reduced
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode
                                                ? theme.colorScheme.secondary
                                                : theme.colorScheme.primary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
