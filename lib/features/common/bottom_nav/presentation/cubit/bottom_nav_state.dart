part of 'bottom_nav_cubit.dart';

class BottomNavState {
  const BottomNavState({this.hideNavBar = false});
  final bool hideNavBar;
}

class BottomNavInitial extends BottomNavState {
  const BottomNavInitial({super.hideNavBar});
}

class ChangeIndex extends BottomNavState {
  const ChangeIndex({super.hideNavBar});
}

class ToggleNavBarVisibility extends BottomNavState {
  const ToggleNavBarVisibility({required super.hideNavBar});
}
