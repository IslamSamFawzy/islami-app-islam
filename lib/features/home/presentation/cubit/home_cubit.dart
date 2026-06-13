import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the index of the currently selected bottom-navigation tab.
class HomeCubit extends Cubit<int> {
  HomeCubit() : super(0);

  void changeTab(int index) => emit(index);
}
