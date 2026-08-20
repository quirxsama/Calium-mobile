import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:calium_stream/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:calium_stream/features/auth/domain/repositories/auth_repository.dart';
import 'package:calium_stream/features/auth/domain/usecases/login_usecase.dart';
import 'package:calium_stream/features/auth/domain/usecases/register_usecase.dart';
import 'package:calium_stream/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:calium_stream/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:calium_stream/features/home/data/datasources/home_remote_datasource.dart';
import 'package:calium_stream/features/home/data/repositories/home_repository_impl.dart';
import 'package:calium_stream/features/home/domain/repositories/home_repository.dart';
import 'package:calium_stream/features/home/domain/usecases/get_home_feed_usecase.dart';
import 'package:calium_stream/features/home/presentation/bloc/home_bloc.dart';
import 'package:calium_stream/features/explore/data/datasources/explore_remote_datasource.dart';
import 'package:calium_stream/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:calium_stream/features/explore/domain/repositories/explore_repository.dart';
import 'package:calium_stream/features/explore/domain/usecases/get_explore_catalog_usecase.dart';
import 'package:calium_stream/features/explore/presentation/bloc/explore_bloc.dart';
import 'package:calium_stream/features/social/data/datasources/social_remote_datasource.dart';
import 'package:calium_stream/features/social/data/repositories/social_repository_impl.dart';
import 'package:calium_stream/features/social/domain/repositories/social_repository.dart';
import 'package:calium_stream/features/social/presentation/bloc/social_bloc.dart';
import 'package:calium_stream/features/anime_details/data/datasources/anime_detail_remote_datasource.dart';
import 'package:calium_stream/features/anime_details/data/repositories/anime_detail_repository_impl.dart';
import 'package:calium_stream/features/anime_details/domain/repositories/anime_detail_repository.dart';
import 'package:calium_stream/features/anime_details/domain/usecases/get_anime_detail_usecase.dart';
import 'package:calium_stream/features/anime_details/domain/usecases/get_cast_usecase.dart';
import 'package:calium_stream/features/player/data/datasources/player_remote_datasource.dart';
import 'package:calium_stream/features/player/data/repositories/player_repository_impl.dart';
import 'package:calium_stream/features/player/domain/repositories/player_repository.dart';
import 'package:calium_stream/features/player/domain/usecases/get_video_sources_usecase.dart';
import 'package:calium_stream/features/player/presentation/cubit/player_cubit.dart';
import 'package:calium_stream/features/search/data/datasources/search_remote_datasource.dart';
import 'package:calium_stream/features/search/data/repositories/search_repository_impl.dart';
import 'package:calium_stream/features/search/domain/repositories/search_repository.dart';
import 'package:calium_stream/features/search/domain/usecases/search_anime_usecase.dart';
import 'package:calium_stream/features/search/presentation/bloc/search_bloc.dart';
import 'package:calium_stream/features/library/data/datasources/library_local_datasource.dart';
import 'package:calium_stream/features/library/data/datasources/library_remote_datasource.dart';
import 'package:calium_stream/features/library/data/repositories/library_repository_impl.dart';
import 'package:calium_stream/features/library/domain/repositories/library_repository.dart';
import 'package:calium_stream/features/library/domain/usecases/get_favorites_usecase.dart';
import 'package:calium_stream/features/library/domain/usecases/get_history_usecase.dart';
import 'package:calium_stream/features/library/domain/usecases/toggle_favorite_usecase.dart';
import 'package:calium_stream/features/library/presentation/bloc/library_bloc.dart';
import 'package:calium_stream/features/calendar/data/datasources/calendar_remote_datasource.dart';
import 'package:calium_stream/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:calium_stream/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:calium_stream/features/calendar/domain/usecases/get_calendar_usecase.dart';
import 'package:calium_stream/features/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:calium_stream/features/user_lists/data/datasources/user_lists_remote_datasource.dart';
import 'package:calium_stream/features/user_lists/data/repositories/user_lists_repository_impl.dart';
import 'package:calium_stream/features/user_lists/domain/repositories/user_lists_repository.dart';
import 'package:calium_stream/features/user_lists/presentation/bloc/user_lists_bloc.dart';
import 'package:calium_stream/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:calium_stream/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:calium_stream/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:calium_stream/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:calium_stream/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:calium_stream/features/profile/domain/repositories/profile_repository.dart';
import 'package:calium_stream/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:calium_stream/core/services/sync_remote_datasource.dart';
import 'package:calium_stream/core/services/sync_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ─── External ─────────────────────────────────────────────
  const secureStorage = FlutterSecureStorage();
  sl.registerLazySingleton<FlutterSecureStorage>(() => secureStorage);
  sl.registerLazySingleton<DioClient>(() => DioClient(secureStorage: sl()));

  // ─── Auth ─────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      secureStorage: sl(),
    ),
  );
  sl.registerLazySingleton(() => LoginUseCase(repository: sl()));
  sl.registerLazySingleton(() => RegisterUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(repository: sl()));
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      getCurrentUserUseCase: sl(),
      authRepository: sl(),
    ),
  );

  // ─── Home ─────────────────────────────────────────────────
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetHomeFeedUseCase(repository: sl()));
  sl.registerFactory(
    () => HomeBloc(
      getHomeFeed: sl(),
      getAnimeDetailUseCase: sl(),
    ),
  );

  // ─── Explore ──────────────────────────────────────────────
  sl.registerLazySingleton<ExploreRemoteDataSource>(
    () => ExploreRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<ExploreRepository>(
    () => ExploreRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetExploreCatalogUseCase(repository: sl()));
  sl.registerFactory(
    () => ExploreBloc(getExploreCatalogUseCase: sl()),
  );

  // ─── Social ───────────────────────────────────────────────
  sl.registerLazySingleton<SocialRemoteDataSource>(
    () => SocialRemoteDataSourceImpl(
      dioClient: sl(),
      secureStorage: sl(),
    ),
  );
  sl.registerLazySingleton<SocialRepository>(
    () => SocialRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory(
    () => SocialBloc(repository: sl()),
  );

  // ─── Anime Details ────────────────────────────────────────
  sl.registerLazySingleton<AnimeDetailRemoteDataSource>(
    () => AnimeDetailRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<AnimeDetailRepository>(
    () => AnimeDetailRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAnimeDetailUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetCastUseCase(repository: sl()));

  // ─── Player ───────────────────────────────────────────────
  sl.registerLazySingleton<PlayerRemoteDataSource>(
    () => PlayerRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<PlayerRepository>(
    () => PlayerRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetVideoSourcesUseCase(repository: sl()));
  sl.registerFactory(
    () => PlayerCubit(getVideoSourcesUseCase: sl()),
  );

  // ─── Search ───────────────────────────────────────────────
  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => SearchAnimeUseCase(repository: sl()));
  sl.registerFactory(
    () => SearchBloc(searchAnimeUseCase: sl()),
  );

  // ─── Library ──────────────────────────────────────────────
  sl.registerLazySingleton<LibraryLocalDataSource>(
    () => LibraryLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<LibraryRemoteDataSource>(
    () => LibraryRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<LibraryRepository>(
    () => LibraryRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetFavoritesUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetHistoryUseCase(repository: sl()));
  sl.registerLazySingleton(() => ToggleFavoriteUseCase(repository: sl()));
  sl.registerFactory(
    () => LibraryBloc(
      getFavoritesUseCase: sl(),
      getHistoryUseCase: sl(),
      toggleFavoriteUseCase: sl(),
      libraryRepository: sl(),
    ),
  );

  // ─── Calendar ─────────────────────────────────────────────
  sl.registerLazySingleton<CalendarRemoteDataSource>(
    () => CalendarRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<CalendarRepository>(
    () => CalendarRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetCalendarUseCase(repository: sl()));
  sl.registerFactory(
    () => CalendarBloc(getCalendarUseCase: sl()),
  );

  // ─── User Lists ───────────────────────────────────────────
  sl.registerLazySingleton<UserListsRemoteDataSource>(
    () => UserListsRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<UserListsRepository>(
    () => UserListsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory(
    () => UserListsBloc(repository: sl()),
  );

  // ─── Profile ──────────────────────────────────────────────
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(
      dioClient: sl(),
      secureStorage: sl(),
    ),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory(
    () => ProfileCubit(repository: sl()),
  );

  // ─── Settings ─────────────────────────────────────────────
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory(
    () => SettingsBloc(repository: sl()),
  );

  // ─── Sync Service (Background Realtime Sync) ───────────────
  sl.registerLazySingleton<SyncRemoteDataSource>(
    () => SyncRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<SyncService>(
    () => SyncService(
      remoteDataSource: sl(),
      secureStorage: sl(),
    ),
  );
}

