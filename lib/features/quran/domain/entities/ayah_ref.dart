import 'package:equatable/equatable.dart';

/// Names one ayah.
class AyahRef extends Equatable {
  final int sura;
  final int ayah;

  const AyahRef(this.sura, this.ayah);

  @override
  List<Object?> get props => [sura, ayah];
}
