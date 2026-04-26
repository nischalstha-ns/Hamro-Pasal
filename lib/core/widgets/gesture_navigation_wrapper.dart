import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/navigation_history_provider.dart';

class GestureNavigationWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const GestureNavigationWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<GestureNavigationWrapper> createState() =>
      _GestureNavigationWrapperState();
}

class _GestureNavigationWrapperState
    extends ConsumerState<GestureNavigationWrapper> {
  double _dragDistance = 0;
  bool _isDragging = false;
  double _startPosition = 0;

  @override
  Widget build(BuildContext context) {
    final navHistory = ref.watch(navigationHistoryNotifierProvider);
    final router = GoRouter.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onHorizontalDragStart: (details) {
        _startPosition = details.globalPosition.dx;
        // Only enable gesture from screen edges (first 50px from left or right)
        if (_startPosition < 50 || _startPosition > screenWidth - 50) {
          setState(() {
            _isDragging = true;
            _dragDistance = 0;
          });
        }
      },
      onHorizontalDragUpdate: (details) {
        if (_isDragging) {
          setState(() {
            _dragDistance += details.delta.dx;
          });
        }
      },
      onHorizontalDragEnd: (details) {
        if (_isDragging) {
          final threshold = screenWidth * 0.25;

          if (_dragDistance > threshold && navHistory.canGoBack) {
            final previousRoute = navHistory.previousRoute;
            if (previousRoute != null) {
              ref.read(navigationHistoryNotifierProvider.notifier).goBack();
              router.go(previousRoute);
            }
          } else if (_dragDistance < -threshold && navHistory.canGoForward) {
            final nextRoute = navHistory.nextRoute;
            if (nextRoute != null) {
              ref.read(navigationHistoryNotifierProvider.notifier).goForward();
              router.go(nextRoute);
            }
          }

          setState(() {
            _isDragging = false;
            _dragDistance = 0;
          });
        }
      },
      onHorizontalDragCancel: () {
        setState(() {
          _isDragging = false;
          _dragDistance = 0;
        });
      },
      child: Stack(
        children: [
          widget.child,
          if (_isDragging && _dragDistance.abs() > 30)
            Positioned(
              left: _dragDistance > 0 ? 20 : null,
              right: _dragDistance < 0 ? 20 : null,
              top: MediaQuery.of(context).size.height * 0.4,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: (_dragDistance.abs() / 100).clamp(0.0, 1.0),
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _dragDistance > 0
                              ? Icons.arrow_back_ios_new
                              : Icons.arrow_forward_ios,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _dragDistance > 0 ? 'Back' : 'Forward',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
