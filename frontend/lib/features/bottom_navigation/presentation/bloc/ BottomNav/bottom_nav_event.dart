abstract class BottomNavEvent {
  const BottomNavEvent();
}

class BottomNavTabChanged extends BottomNavEvent {
  final int index;

  const BottomNavTabChanged(this.index);
}