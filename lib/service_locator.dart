import 'package:connect/features/discover/data/datasources/discover_remote_datasource.dart';
import 'package:connect/features/discover/data/repositories/discover_repository_impl.dart';
import 'package:connect/features/discover/domain/repositories/i_discover_repository.dart';
import 'package:connect/features/discover/domain/usecases/block_user_usecase.dart';
import 'package:connect/features/discover/domain/usecases/get_blocked_users_usecase.dart';
import 'package:connect/features/discover/domain/usecases/get_public_key_usecase.dart';
import 'package:connect/features/discover/domain/usecases/search_users_usecase.dart';
import 'package:connect/features/discover/domain/usecases/unblock_user_usecase.dart';
import 'package:connect/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:connect/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:connect/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:connect/features/settings/domain/repositories/i_settings_repository.dart';
import 'package:connect/features/settings/domain/usecases/toggle_last_seen_usecase.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connect/core/network/api_client.dart';
import 'package:connect/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:connect/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:connect/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:connect/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:connect/features/auth/domain/usecases/logout_usecase.dart';
import 'package:connect/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:connect/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:connect/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:connect/features/auth/presentation/bloc/auth_bloc.dart';

import 'core/crypto/crypto_service.dart';
import 'features/auth/domain/usecases/mark_profile_complete_usecase.dart';
import 'features/chat/data/datasources/chat_remote_datasource.dart';
import 'features/chat/data/datasources/chat_remote_datasource_impl.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/repositories/i_chat_repository.dart';
import 'features/chat/domain/usecases/connect_socket_usecase.dart';
import 'features/chat/domain/usecases/disconnect_socket_usecase.dart';
import 'features/chat/domain/usecases/get_chat_history_usecase.dart';
import 'features/chat/domain/usecases/receive_message_status_stream_usecase.dart';
import 'features/chat/domain/usecases/receive_messages_stream_usecase.dart';
import 'features/chat/domain/usecases/receive_typing_stream_usecase.dart';
import 'features/chat/domain/usecases/send_message_usecase.dart';
import 'features/chat/domain/usecases/send_read_receipt_usecase.dart';
import 'features/chat/domain/usecases/send_typing_status_usecase.dart';
import 'features/chat/domain/usecases/sync_offline_messages_usecase.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/discover/presentation/bloc/discover_bloc.dart';
import 'features/profile/Data/datasources/profile_remote_datasource.dart';
import 'features/profile/Data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/i_profile_repository.dart';
import 'features/profile/domain/usecases/get_my_profile_usecase.dart';
import 'features/profile/domain/usecases/setup_profile_usecase.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';

// Create a global instance of GetIt
final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ===========================================================================
  // 1. CORE & EXTERNAL PACKAGES
  // ===========================================================================
  // registerLazySingleton means it will only create the object when it's first requested,
  // and then reuse that SAME object for the rest of the app's life.

  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  sl.registerLazySingleton<ApiClient>(() => ApiClient(secureStorage: sl()));

  // Crypto Service
  sl.registerLazySingleton(() => CryptoService(secureStorage: sl()));

  // ===========================================================================
  // 2. DATA SOURCES
  // ===========================================================================

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<IProfileRemoteDataSource>(
    () => ProfileRemoteDatasourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<IDiscoverRemoteDatasource>(
    () => DiscoverRemoteDatasourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<ISettingsRemoteDatasource>(
    () => SettingsRemoteDatasourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<IChatRemoteDatasource>(
    () => ChatRemoteDatasourceImpl(apiClient: sl(), secureStorage: sl()),
  );

  // ===========================================================================
  // 3. REPOSITORIES
  // ===========================================================================
  // Notice how we register the Interface (IAuthRepository) but return the Implementation (AuthRepositoryImpl)
  // This is the core of Clean Architecture!

  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(localDataSource: sl(), remoteDataSource: sl()),
  );

  sl.registerLazySingleton<IProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<IDiscoverRepository>(
    () => DiscoverRepositoryImpl(remoteDatasource: sl()),
  );

  sl.registerLazySingleton<ISettingsRepository>(
    () => SettingsRepositoryImpl(remoteDatasource: sl()),
  );

  sl.registerLazySingleton<IChatRepository>(
    () => ChatRepositoryImpl(cryptoService: sl(), remoteDatasource: sl()),
  );

  // ===========================================================================
  // 4. USE CASES
  // ===========================================================================

  sl.registerLazySingleton(() => SendOtpUseCase(repository: sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(repository: sl()));
  sl.registerLazySingleton(
    () => LogoutUseCase(repository: sl(), cryptoService: sl()),
  );
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(repository: sl()));
  sl.registerLazySingleton(
    () => SetupProfileUseCase(repository: sl(), cryptoService: sl()),
  );
  sl.registerLazySingleton(() => MarkProfileCompleteUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetMyProfileUseCase(repository: sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(repository: sl()));
  //Discover
  sl.registerLazySingleton(() => SearchUsersUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetPublicKeyUseCase(repository: sl()));
  sl.registerLazySingleton(() => BlockUserUseCase(repository: sl()));
  sl.registerLazySingleton(() => UnblockUserUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetBlockedUsersUseCase(repository: sl()));
  sl.registerLazySingleton(() => ToggleLastSeenUseCase(repository: sl()));
  // Chat Use Cases
  sl.registerLazySingleton(() => ConnectSocketUseCase(repository: sl()));
  sl.registerLazySingleton(() => DisconnectSocketUseCase(repository: sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(repository: sl()));
  sl.registerLazySingleton(() => SendReadReceiptUseCase(repository: sl()));
  sl.registerLazySingleton(() => SendTypingStatusUseCase(repository: sl()));
  sl.registerLazySingleton(() => SyncOfflineMessagesUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetChatHistoryUseCase(repository: sl()));
  sl.registerLazySingleton(
    () => ReceiveMessagesStreamUseCase(repository: sl()),
  );
  sl.registerLazySingleton(
    () => ReceiveMessageStatusStreamUseCase(repository: sl()),
  );
  sl.registerLazySingleton(() => ReceiveTypingStreamUseCase(repository: sl()));

  // ===========================================================================
  // 5. BLOCS
  // ===========================================================================
  // We use registerFactory for BLoCs.
  // This means every time we ask for sl<AuthBloc>(), it gives us a BRAND NEW instance.
  // This prevents state from leaking if a BLoC is closed and reopened.

  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      sendOtpUseCase: sl(),
      verifyOtpUseCase: sl(),
      logoutUseCase: sl(),
      checkAuthStatusUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => ProfileBloc(
      setupProfileUseCase: sl(),
      markProfileCompleteUseCase: sl(),
      getMyProfileUseCase: sl(),
      updateProfileUseCase: sl(),
    ),
  );

  //Discover
  sl.registerFactory(
    () => DiscoverBloc(
      searchUsersUseCase: sl(),
      blockUserUseCase: sl(),
      unblockUserUseCase: sl(),
      getBlockedUsersUseCase: sl(),
      getPublicKeyUseCase: sl(),
    ),
  );

  //Setting
  sl.registerFactory(() => SettingsBloc(toggleLastSeenUseCase: sl()));

  // Chat
  sl.registerFactory(
    () => ChatBloc(
      connectSocketUseCase: sl(),
      disconnectSocketUseCase: sl(),
      getChatHistoryUseCase: sl(),
      receiveMessageStatusStreamUseCase: sl(),
      receiveMessagesStreamUseCase: sl(),
      receiveTypingStreamUseCase: sl(),
      sendMessageUseCase: sl(),
      sendReadReceiptUseCase: sl(),
      sendTypingStatusUseCase: sl(),
      syncOfflineMessagesUseCase: sl(),
    ),
  );
}
