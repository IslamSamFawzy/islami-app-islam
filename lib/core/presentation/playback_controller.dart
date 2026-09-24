import 'package:equatable/equatable.dart';

import '../services/audio_player_service.dart';

/// What one screen's player row should show: which of *its* items is loaded,
/// and whether that item is playing.
class PlaybackStatus extends Equatable {
  /// Empty when the shared player is on nothing, or on another screen's item.
  final String currentId;

  final bool isPlaying;

  const PlaybackStatus({this.currentId = '', this.isPlaying = false});

  bool isCurrent(String id) => currentId.isNotEmpty && currentId == id;

  @override
  List<Object?> get props => [currentId, isPlaying];
}

/// One screen's view of the shared player: the "tap the current item to pause,
/// tap another to start it" rule, and the rule that a screen only ever stops
/// audio it started.
///
/// It keeps no state of its own. [AudioPlayerService] holds the single tag
/// saying what is loaded, and this derives everything from it, so when another
/// screen takes the player over, this one stops claiming it at once.
///
/// [owner] namespaces the tag. It must identify the screen *and* what it is
/// listing — a reciter's sura list passes its reciter id, or two reciters
/// would each think sura 2 was theirs.
class PlaybackController {
  final AudioPlayerService audioPlayerService;
  final String owner;

  PlaybackController({required this.audioPlayerService, required this.owner});

  /// The shared player's view, narrowed to this screen.
  PlaybackStatus get status => _statusOf(audioPlayerService.status);

  /// Every change, already narrowed — for a bloc or cubit to mirror into its
  /// own state. Losing the player to another screen arrives as an empty status.
  Stream<PlaybackStatus> get statusStream =>
      audioPlayerService.statusStream.map(_statusOf).distinct();

  bool isCurrent(String id) => audioPlayerService.status.tag == _tagFor(id);

  /// Pauses or resumes whatever is loaded.
  Future<void> togglePause() => audioPlayerService.togglePause();

  /// A tap on a streamed item: pause/resume when it is already current, start
  /// streaming it otherwise.
  Future<void> toggleUrl({required String id, required String url}) {
    return isCurrent(id)
        ? togglePause()
        : audioPlayerService.playUrl(url, tag: _tagFor(id));
  }

  /// A tap on a local file.
  Future<void> toggleFile({required String id, required String path}) {
    return isCurrent(id)
        ? togglePause()
        : audioPlayerService.playFile(path, tag: _tagFor(id));
  }

  /// Stops when one of *this screen's* items is loaded and matches [test] —
  /// before deleting the file that is playing, say. Returns whether it stopped
  /// anything.
  Future<bool> stopWhere(bool Function(String id) test) async {
    final id = _idIn(audioPlayerService.status.tag);
    if (id == null || !test(id)) return false;
    await audioPlayerService.stop();
    return true;
  }

  /// Stops the audio only if the player is still on something this screen
  /// started, so leaving a screen never cuts off playback owned elsewhere.
  Future<void> close() async {
    if (_idIn(audioPlayerService.status.tag) != null) {
      await audioPlayerService.stop();
    }
  }

  String _tagFor(String id) => '$owner#$id';

  /// The item id inside [tag] when this screen started it, else `null`.
  String? _idIn(String tag) =>
      tag.startsWith('$owner#') ? tag.substring(owner.length + 1) : null;

  PlaybackStatus _statusOf(AudioStatus status) {
    final id = _idIn(status.tag);
    return id == null
        ? const PlaybackStatus()
        : PlaybackStatus(currentId: id, isPlaying: status.isPlaying);
  }
}
