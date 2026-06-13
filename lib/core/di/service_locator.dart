import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/audio_player_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

// Quran feature
import '../../features/quran/data/datasources/quran_local_data_source.dart';
import '../../features/quran/data/repositories/quran_repository_impl.dart';
import '../../features/quran/domain/repositories/quran_repository.dart';
import '../../features/quran/domain/usecases/add_recent_sura.dart';
import '../../features/quran/domain/usecases/get_all_suras.dart';
import '../../features/quran/domain/usecases/get_recent_suras.dart';
import '../../features/quran/domain/usecases/get_sura_verses.dart';
import '../../features/quran/presentation/bloc/quran_bloc.dart';
import '../../features/quran/presentation/bloc/details/quran_details_bloc.dart';

// Hadith feature
import '../../features/hadith/data/datasources/hadith_local_data_source.dart';
import '../../features/hadith/data/repositories/hadith_repository_impl.dart';
import '../../features/hadith/domain/repositories/hadith_repository.dart';
import '../../features/hadith/domain/usecases/get_all_hadiths.dart';
import '../../features/hadith/presentation/bloc/hadith_bloc.dart';

// Time feature
import '../../features/time/data/datasources/prayer_remote_data_source.dart';
import '../../features/time/data/repositories/prayer_repository_impl.dart';
import '../../features/time/domain/repositories/prayer_repository.dart';
import '../../features/time/domain/usecases/get_prayer_times.dart';
import '../../features/time/presentation/bloc/time_bloc.dart';

// Radio feature
import '../../features/radio/data/datasources/radio_remote_data_source.dart';
import '../../features/radio/data/repositories/radio_repository_impl.dart';
import '../../features/radio/domain/repositories/radio_repository.dart';
import '../../features/radio/domain/usecases/get_radios.dart';
import '../../features/radio/domain/usecases/get_reciters.dart';
import '../../features/radio/presentation/bloc/radio_bloc.dart';

// Azkar feature
import '../../features/azkar/data/datasources/azkar_local_data_source.dart';
import '../../features/azkar/data/repositories/azkar_repository_impl.dart';
import '../../features/azkar/domain/repositories/azkar_repository.dart';
import '../../features/azkar/domain/usecases/get_azkar.dart';
import '../../features/azkar/presentation/bloc/azkar_bloc.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Registers all dependencies. Call once in `main()` before `runApp`.
Future<void> init() async {
  // ---------------------------------------------------------------------------
  // External / core
  // ---------------------------------------------------------------------------
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // Core services
  sl.registerLazySingleton<AudioPlayerService>(() => AudioPlayerService());
  sl.registerLazySingleton<LocationService>(() => LocationService());

  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();
  sl.registerLazySingleton<NotificationService>(() => notificationService);

  // ---------------------------------------------------------------------------
  // Quran feature
  // ---------------------------------------------------------------------------
  // Bloc (factory: new instance each time it is requested)
  sl.registerFactory(
    () => QuranBloc(
      getAllSuras: sl(),
      getRecentSuras: sl(),
      addRecentSura: sl(),
    ),
  );
  sl.registerFactory(() => QuranDetailsBloc(getSuraVerses: sl()));

  // Use cases (singleton: created once, reused)
  sl.registerLazySingleton(() => GetAllSuras(sl()));
  sl.registerLazySingleton(() => GetSuraVerses(sl()));
  sl.registerLazySingleton(() => GetRecentSuras(sl()));
  sl.registerLazySingleton(() => AddRecentSura(sl()));

  // Repository
  sl.registerLazySingleton<QuranRepository>(
    () => QuranRepositoryImpl(localDataSource: sl()),
  );

  // Data source
  sl.registerLazySingleton<QuranLocalDataSource>(
    () => QuranLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // ---------------------------------------------------------------------------
  // Hadith feature
  // ---------------------------------------------------------------------------
  sl.registerFactory(() => HadithBloc(getAllHadiths: sl()));

  sl.registerLazySingleton(() => GetAllHadiths(sl()));

  sl.registerLazySingleton<HadithRepository>(
    () => HadithRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<HadithLocalDataSource>(
    () => HadithLocalDataSourceImpl(),
  );

  // ---------------------------------------------------------------------------
  // Time feature (prayer times + adhan)
  // ---------------------------------------------------------------------------
  sl.registerFactory(
    () => TimeBloc(
      getPrayerTimes: sl(),
      notificationService: sl(),
      audioPlayerService: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetPrayerTimes(sl()));

  sl.registerLazySingleton<PrayerRepository>(
    () => PrayerRepositoryImpl(
      remoteDataSource: sl(),
      locationService: sl(),
    ),
  );

  sl.registerLazySingleton<PrayerRemoteDataSource>(
    () => PrayerRemoteDataSourceImpl(client: sl()),
  );

  // ---------------------------------------------------------------------------
  // Radio feature
  // ---------------------------------------------------------------------------
  sl.registerFactory(
    () => RadioBloc(
      getRadios: sl(),
      getReciters: sl(),
      audioPlayerService: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetRadios(sl()));
  sl.registerLazySingleton(() => GetReciters(sl()));

  sl.registerLazySingleton<RadioRepository>(
    () => RadioRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<RadioRemoteDataSource>(
    () => RadioRemoteDataSourceImpl(client: sl()),
  );

  // ---------------------------------------------------------------------------
  // Azkar feature
  // ---------------------------------------------------------------------------
  sl.registerFactory(() => AzkarBloc(getAzkar: sl()));

  sl.registerLazySingleton(() => GetAzkar(sl()));

  sl.registerLazySingleton<AzkarRepository>(
    () => AzkarRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<AzkarLocalDataSource>(
    () => AzkarLocalDataSourceImpl(),
  );
}
