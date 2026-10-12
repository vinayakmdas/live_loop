import 'package:frontend/features/bottom_navigation/domain/entities/navigation_items.dart';


class BottomNavState {
  final int selectedIndex;
  final List<NavigationItem> items;

  const BottomNavState({
    required this.selectedIndex,
    required this.items,
  });

  BottomNavState copyWith({
    int? selectedIndex,
    List<NavigationItem>? items,
  }) {
    return BottomNavState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      items: items ?? this.items,
    );
  }
}