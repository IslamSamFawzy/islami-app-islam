import 'package:equatable/equatable.dart';

/// One prayer whose adhan should fire, as the scheduler needs it.
class AdhanTime extends Equatable {
  final String name;
  final DateTime time;

  /// Fajr has its own adhan, so the scheduler is told which one this is.
  final bool isFajr;

  const AdhanTime({
    required this.name,
    required this.time,
    required this.isFajr,
  });

  @override
  List<Object?> get props => [name, time, isFajr];
}
