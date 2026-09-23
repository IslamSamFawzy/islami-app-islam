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

/// Filters the active tab's list by [query].
class SearchRadioEvent extends RadioEvent {
  final String query;

  const SearchRadioEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Plays the item with [id] from [url] (or toggles it if already current).
class PlayItemEvent extends RadioEvent {
  final String id;
  final String url;

  const PlayItemEvent({required this.id, required this.url});

  @override
  List<Object?> get props => [id, url];
}

/// Internal: forwards connectivity changes (drives the offline strip and
/// triggers a refresh on reconnect).
class _ConnectivityChangedEvent extends RadioEvent {
  final bool online;

  const _ConnectivityChangedEvent(this.online);

  @override
  List<Object?> get props => [online];
}

/// Internal: forwards what the shared [PlaybackController] is on.
class _PlaybackChangedEvent extends RadioEvent {
  final PlaybackStatus status;

  const _PlaybackChangedEvent(this.status);

  @override
  List<Object?> get props => [status];
}
