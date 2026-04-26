import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_history_provider.g.dart';

class NavigationHistory {
  final List<String> history;
  final int currentIndex;

  NavigationHistory({
    required this.history,
    required this.currentIndex,
  });

  NavigationHistory copyWith({
    List<String>? history,
    int? currentIndex,
  }) {
    return NavigationHistory(
      history: history ?? this.history,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  bool get canGoBack => currentIndex > 0;
  bool get canGoForward => currentIndex < history.length - 1;

  String? get previousRoute => canGoBack ? history[currentIndex - 1] : null;
  String? get nextRoute => canGoForward ? history[currentIndex + 1] : null;
  String get currentRoute => history[currentIndex];
}

@riverpod
class NavigationHistoryNotifier extends _$NavigationHistoryNotifier {
  @override
  NavigationHistory build() {
    return NavigationHistory(
      history: ['/'],
      currentIndex: 0,
    );
  }

  void push(String route) {
    final currentHistory = state.history;
    final currentIdx = state.currentIndex;

    // If we're not at the end of history, remove forward history
    final newHistory = currentHistory.sublist(0, currentIdx + 1);
    
    // Don't add duplicate consecutive routes
    if (newHistory.isEmpty || newHistory.last != route) {
      newHistory.add(route);
      state = NavigationHistory(
        history: newHistory,
        currentIndex: newHistory.length - 1,
      );
    }
  }

  void goBack() {
    if (state.canGoBack) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void goForward() {
    if (state.canGoForward) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void replace(String route) {
    final newHistory = List<String>.from(state.history);
    newHistory[state.currentIndex] = route;
    state = state.copyWith(history: newHistory);
  }

  void clear() {
    state = NavigationHistory(
      history: ['/'],
      currentIndex: 0,
    );
  }
}
