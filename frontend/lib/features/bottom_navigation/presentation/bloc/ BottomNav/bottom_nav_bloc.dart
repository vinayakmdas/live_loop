import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/bottom_navigation/domain/usecases/get_navigation_items.dart';

import 'bottom_nav_event.dart';
import 'bottom_nav_state.dart';

class BottomNavBloc extends Bloc<BottomNavEvent, BottomNavState> {
  final GetNavigationItems getNavigationItems;

  BottomNavBloc({
    required this.getNavigationItems,
  }) : super(
          BottomNavState(
            selectedIndex: 0,
            items: getNavigationItems(),
          ),
        ) {
    on<BottomNavTabChanged>(_onTabChanged);
  }

  void _onTabChanged(
    BottomNavTabChanged event,
    Emitter<BottomNavState> emit,
  ) {
    if (event.index < 0 ||
        event.index >= state.items.length ||
        event.index == state.selectedIndex) {
      return;
    }

    emit(
      state.copyWith(
        selectedIndex: event.index,
      ),
    );
  }
}