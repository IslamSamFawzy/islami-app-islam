/// Whether the user has been through the intro.
///
/// Its own small feature because two others share it: Intro writes it on
/// Finish, Splash reads it to pick the first screen.
abstract class OnboardingRepository {
  Future<bool> hasSeenOnboarding();

  Future<void> markOnboardingSeen();
}
