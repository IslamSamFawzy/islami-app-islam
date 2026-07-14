part of 'radio_bloc.dart';

abstract class RadioEvent extends Equatable {
  const RadioEvent();

  @override
  List<Object?> get props => [];
}

/// Loads both radios and reciters (cache first, then a background refresh).
class LoadRadioDataEvent extends RadioEvent {
  const LoadRadioDataEvent();
}

/// Internal: re-fetches from the network after cache was rendered, and
/// re-emits only if the fresh data differs.
class _RefreshRadioDataEvent extends RadioEvent {
  const _RefreshRadioDataEvent();
}

/// Switches between the Radio and Reciters tabs.
class SelectTabEvent extends RadioEvent {
  final RadioTab tab;

  const SelectTabEvent(this.tab);

  @override
  List<Object?> get props => [tab];
}

/// Plays the item with [id] from [url] (or toggles it if already current).
class PlayItemEvent extends RadioEvent {
  final String id;
  final String url;

  const PlayItemEvent({required this.id, required this.url});

  @override
  List<Object?> get props => [id, url];
}

/// Internal: forwards audio player state changes.
class _PlayerStateChangedEvent extends RadioEvent {
  final bool isPlaying;

  const _PlayerStateChangedEvent(this.isPlaying);

  @override
  List<Object?> get props => [isPlaying];
}
