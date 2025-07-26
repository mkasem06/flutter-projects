import 'package:expenses_tracker/models/expense.dart';
import 'package:expenses_tracker/database/expense_database.dart';
import 'package:flutter/material.dart';

class NewExpense extends StatefulWidget {
  const NewExpense(this.onAddExpense, {super.key});
  final void Function(Expense expense) onAddExpense;

  @override
  State<NewExpense> createState() => _NewExpenseState();
}

class _NewExpenseState extends State<NewExpense> with TickerProviderStateMixin {
  final textController = TextEditingController();
  final amountController = TextEditingController();
  DateTime? selectedDate;
  Category selectedCategory = Category.others;
  
  late AnimationController _slideController;
  late AnimationController _fieldController;
  late AnimationController _bounceController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fieldAnimation;
  late Animation<double> _bounceAnimation;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fieldController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fieldAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fieldController,
      curve: Curves.easeOutBack,
    ));
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fieldController.forward();
      }
    });
  }

  void selectDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2000, 1, 1),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
      // Add bounce animation when date is selected
      _bounceController.forward().then((_) {
        _bounceController.reverse();
      });
    }
  }

  void submitExpense() async {
    if (_isSubmitting) return; // Prevent multiple submissions
    
    setState(() {
      _isSubmitting = true;
    });
    
    final enteredAmount = double.tryParse(amountController.text);
    final amountIsInvalid = enteredAmount == null || enteredAmount <= 0;
    if (textController.text.trim().isEmpty ||
        amountIsInvalid ||
        selectedDate == null) {
      
      setState(() {
        _isSubmitting = false;
      });
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Invalid Input'),
          content: const Text(
            'Please make sure to fill all missing fields',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Got it!'),
            ),
          ],
        ),
      );
      return;
    }

    final newExpense = Expense(
      title: textController.text,
      amount: double.parse(amountController.text),
      date: selectedDate!,
      category: selectedCategory,
    );

    // Save to database
    await ExpenseDatabase.insertExpense(newExpense);

    // Add to UI
    widget.onAddExpense(newExpense);
    
    // Animate out before closing - ensure controllers are still valid
    if (mounted && !_slideController.isAnimating) {
      await _slideController.reverse();
    }
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    textController.dispose();
    amountController.dispose();
    _slideController.dispose();
    _fieldController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: EdgeInsets.only(bottom: keyboardSpace),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                AnimatedBuilder(
                  animation: _fieldAnimation,
                  builder: (context, child) {
                    final animationValue = _fieldAnimation.value.clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: animationValue,
                      child: Opacity(
                        opacity: animationValue,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withAlpha(25),
                                Theme.of(context).colorScheme.secondary.withAlpha(13),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            'Add New Expense',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // Title field
                _buildAnimatedField(
                  delay: 0.1,
                  child: TextField(
                    controller: textController,
                    maxLength: 50,
                    decoration: InputDecoration(
                      label: const Text('Title'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
                
                // Amount and date row
                _buildAnimatedField(
                  delay: 0.2,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          maxLength: 7,
                          decoration: InputDecoration(
                            prefix: const Text('\$'),
                            label: const Text('Amount'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 56, // Match TextField height
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                color: Theme.of(context).colorScheme.surface,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedDate == null
                                          ? 'Select date'
                                          : formatter.format(selectedDate!),
                                      style: TextStyle(
                                        color: selectedDate == null 
                                          ? Theme.of(context).colorScheme.onSurface.withAlpha(150)
                                          : Theme.of(context).colorScheme.onSurface,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  AnimatedBuilder(
                                    animation: _bounceAnimation,
                                    builder: (context, child) {
                                      final scaleValue = _bounceAnimation.value.clamp(0.5, 2.0);
                                      return Transform.scale(
                                        scale: scaleValue,
                                        child: IconButton(
                                          onPressed: selectDate,
                                          icon: Icon(
                                            Icons.calendar_month_outlined,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20), // Space for counter text
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Category dropdown
                _buildAnimatedField(
                  delay: 0.3,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: DropdownButton(
                      isExpanded: true,
                      underline: Container(),
                      borderRadius: BorderRadius.circular(15),
                      value: selectedCategory,
                      items: Category.values
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 25),
                
                // Action buttons
                _buildAnimatedField(
                  delay: 0.4,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : submitExpense,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 3,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Submit Expense'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            if (mounted && !_slideController.isAnimating) {
                              await _slideController.reverse();
                            }
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedField({required double delay, required Widget child}) {
    return AnimatedBuilder(
      animation: _fieldAnimation,
      builder: (context, _) {
        // Ensure the animation value is always between 0.0 and 1.0
        final rawValue = _fieldAnimation.value - delay;
        final animationValue = rawValue.clamp(0.0, 1.0);
        
        return Transform.translate(
          offset: Offset(0, (1 - animationValue) * 30),
          child: Opacity(
            opacity: animationValue.clamp(0.0, 1.0), // Extra safety clamp
            child: child,
          ),
        );
      },
    );
  }
}
