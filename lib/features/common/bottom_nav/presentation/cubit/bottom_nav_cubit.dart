import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sav/core/constants/app_assets.dart';
import 'package:sav/features/common/bottom_nav/data/models/bottom_nav_model.dart';

part 'bottom_nav_state.dart';

class BottomNavCubit extends Cubit<BottomNavState> {
  BottomNavCubit() : super(const BottomNavInitial());

  int currentIndex = 0;
  bool hideNavBar = false;

  void changeIndex({required int index}) {
    if (currentIndex != index) {
      currentIndex = index;
      // Reset hideNavBar when leaving trip screen
      if (index != 2) {
        hideNavBar = false;
      }
      emit(ChangeIndex(hideNavBar: hideNavBar));
    }
  }

  void setHideNavBar(bool hide) {
    if (hideNavBar != hide) {
      hideNavBar = hide;
      emit(ToggleNavBarVisibility(hideNavBar: hide));
    }
  }

  List<BottomNavModel> get bottomNavModels => const [
    BottomNavModel(title: 'Home', iconPath: AppAssets.navHome),
    BottomNavModel(title: 'History', iconPath: AppAssets.navClock),
    BottomNavModel(title: 'Trips', iconPath: AppAssets.navViewBoard),
    BottomNavModel(title: 'Settings', iconPath: AppAssets.navAdjust),
  ];
}
