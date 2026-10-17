import 'package:frontend/features/bottom_navigation/domain/entities/navigation_items.dart';



class GetNavigationItems {
  const GetNavigationItems();

  List<NavigationItem> call() {
    return const [
      NavigationItem(index: 0, label: 'Home'),
      NavigationItem(index: 1, label: 'Meetings'),
      NavigationItem(index: 2, label: 'Profile'),
    ];
  }
}