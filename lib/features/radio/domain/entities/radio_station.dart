import 'package:equatable/equatable.dart';

/// A Quran radio station (continuous stream).
class RadioStation extends Equatable {
  final int id;
  final String name;
  final String url;

  const RadioStation({
    required this.id,
    required this.name,
    required this.url,
  });

  @override
  List<Object?> get props => [id, name, url];
}
