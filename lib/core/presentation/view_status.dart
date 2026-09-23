/// The load status of a screen's state.
///
/// Every feature used to declare its own four-value copy of this (`AzkarStatus`,
/// `HadithStatus`, …); they all meant the same thing, so they share this one.
enum ViewStatus {
  /// Nothing has been requested yet.
  initial,

  /// A request is in flight.
  loading,

  /// Data arrived and is ready to show.
  success,

  /// The request failed; the state carries the message.
  failure;

  bool get isInitial => this == ViewStatus.initial;

  bool get isLoading => this == ViewStatus.loading;

  bool get isSuccess => this == ViewStatus.success;

  bool get isFailure => this == ViewStatus.failure;

  /// Nothing to show yet — either the first load has not started or it is still
  /// running. Screens render their spinner on this.
  bool get isBusy => isInitial || isLoading;
}
