import 'package:flutter/material.dart';

class ChartBar extends StatefulWidget {
  const ChartBar({
    super.key,
    required this.fill,
    required this.category,
    required this.amount,
  });

  final double fill;
  final String category;
  final double amount;

  @override
  State<ChartBar> createState() => _ChartBarState();
}

class _ChartBarState extends State<ChartBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800), // Reduced duration
      vsync: this,
    );

    _heightAnimation = Tween<double>(
      begin: 0.0,
      end: widget.fill.clamp(0.0, 1.0), // Ensure valid range
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // Simpler curve
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut, // Simpler curve
    ));

    // Simplified delay calculation using category name
    final delay = widget.category.isNotEmpty 
        ? (widget.category.hashCode.abs() % 7) * 50
        : (widget.amount.hashCode.abs() % 7) * 50;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(ChartBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fill != widget.fill && mounted) {
      final newFill = widget.fill.clamp(0.0, 1.0);
      _heightAnimation = Tween<double>(
        begin: _heightAnimation.value.clamp(0.0, 1.0),
        end: newFill,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      
      if (!_animationController.isAnimating) {
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final theme = Theme.of(context);
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bar container
            Expanded(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final heightValue = _heightAnimation.value.clamp(0.0, 1.0);
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: heightValue,
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 4),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                            bottom: Radius.circular(2),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              isDarkMode
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.primary,
                              isDarkMode
                                  ? theme.colorScheme.secondary.withAlpha(150)
                                  : theme.colorScheme.primary.withAlpha(150),
                            ],
                          ),
                          boxShadow: heightValue > 0.1 ? [
                            BoxShadow(
                              color: (isDarkMode
                                      ? theme.colorScheme.secondary
                                      : theme.colorScheme.primary)
                                  .withAlpha(60),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ] : [],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Amount display only (category name removed since it's shown in icons below)
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                final scaleValue = _scaleAnimation.value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: scaleValue,
                  child: Opacity(
                    opacity: scaleValue,
                    child: widget.amount > 0
                        ? Text(
                            '\$${widget.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withAlpha(180),
                            ),
                            textAlign: TextAlign.center,
                          )
                        : const SizedBox.shrink(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
