import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/navigation_history_provider.dart';

class NavigationControls extends ConsumerWidget {
  const NavigationControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navHistory = ref.watch(navigationHistoryNotifierProvider);
    final router = GoRouter.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: navHistory.canGoBack
                ? () {
                    final previousRoute = navHistory.previousRoute;
                    if (previousRoute != null) {
                      ref.read(navigationHistoryNotifierProvider.notifier).goBack();
                      router.go(previousRoute);
                    }
                  }
                : null,
            tooltip: 'Previous',
            style: IconButton.styleFrom(
              backgroundColor: navHistory.canGoBack
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.grey.shade200,
              foregroundColor: navHistory.canGoBack
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Colors.grey.shade400,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.arrow_forward, size: 20),
            onPressed: navHistory.canGoForward
                ? () {
                    final nextRoute = navHistory.nextRoute;
                    if (nextRoute != null) {
                      ref.read(navigationHistoryNotifierProvider.notifier).goForward();
                      router.go(nextRoute);
                    }
                  }
                : null,
            tooltip: 'Next',
            style: IconButton.styleFrom(
              backgroundColor: navHistory.canGoForward
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.grey.shade200,
              foregroundColor: navHistory.canGoForward
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Colors.grey.shade400,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
          ),
        ],
      ),
    );
  }
}
