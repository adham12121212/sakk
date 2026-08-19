import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/auth_data_source/auth_data_source.dart';
import '../../features/auth/data/auth_repo_impl/auth_repo_impl.dart';
import '../../features/auth/domain/auth_repo/auth_repo.dart';
import '../../features/auth/domain/usecase/get_user_usecase.dart';
import '../../features/auth/domain/usecase/signin_usecase.dart';
import '../../features/auth/domain/usecase/signout_usecase.dart';
import '../../features/auth/domain/usecase/signup_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/chat/data/chat_data_source/chat_data_source.dart';
import '../../features/chat/data/chat_repo_impl/chat_repo_impl.dart';
import '../../features/chat/domain/chat_repo/chat_repo.dart';
import '../../features/chat/domain/usecase/send_message_use_case.dart';
import '../../features/chat/presentation/cubit/chat_cubit.dart';
import '../../features/details/presentation/cubit/details_cubit.dart';
import '../../features/notification/data/notification_data_source/notification_data_source.dart';
import '../../features/notification/data/notification_repo_impl/notification_repo_impl.dart';
import '../../features/notification/domain/notification_repo/notification_repo.dart';
import '../../features/notification/domain/usecase/add_notification_use_case.dart';
import '../../features/notification/domain/usecase/delete_notification_use_case.dart';
import '../../features/notification/domain/usecase/get_notification_use_case.dart';
import '../../features/notification/domain/usecase/mark_notification_read_use_case.dart';
import '../../features/notification/presentation/cubit/notification_cubit.dart';
import '../../features/products/data/product_data_source/product_data_source.dart';
import '../../features/products/data/product_repo_impl/product_repo_impl.dart';
import '../../features/products/domain/product_repo/product_repo.dart';
import '../../features/products/domain/usecase/add_product_usecase.dart';
import '../../features/products/domain/usecase/delete_product_usecase.dart';
import '../../features/products/domain/usecase/get_products_usecase.dart';
import '../../features/products/domain/usecase/scan_receipt_usecase.dart';
import '../../features/products/domain/usecase/update_product_usecase.dart';
import '../../features/products/presentation/cubit/product_cubit.dart';
import '../error/network_info.dart';
import '../locale_controller/locale_controller.dart';
import '../logger/app_logger.dart';
import '../logger/console_logger.dart';
import '../service/notification_service.dart';
import '../service/supabase_client.dart';
import '../service/supabase_client_impl.dart';
import '../service/warranty_notification_service.dart';

import '../theme/theme_controller.dart';
import '../util/notified_warranties_tracker.dart';
import '../util/shared_preferences.dart';


GetIt getIt = GetIt.instance;


void setupLocator() {
  getIt.registerLazySingleton<AppLogger>(() => ConsoleLogger());

  getIt.registerLazySingleton<SupabaseService>(
        () => SupabaseServiceImpl(Supabase.instance.client),
  );
  getIt.registerLazySingleton<InternetConnection>(() => InternetConnection());
  getIt.registerLazySingleton<NetworkInfo>(
        () => NetworkInfoImpl(getIt<InternetConnection>()),
  );
  getIt.registerLazySingleton<AuthDataSource>(
        () => AuthDataSourceImpl(getIt<SupabaseService>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
        () => AuthRepoImpl(getIt<AuthDataSource>(), getIt<NetworkInfo>(), getIt<AppLogger>()),
  );
  getIt.registerLazySingleton<SignInUseCase>(
        () => SignInUseCaseImpl(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignupUsecase>(
        () => SignupUsecaseImpl(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignOutUseCase>(
        () => SignOutUseCaseImpl(getIt<AuthRepository>()),
  );
  getIt.registerFactory<AuthCubit>(
        () => AuthCubit(
      getIt<SignupUsecase>(),
      getIt<SignInUseCase>(),
      getIt<SignOutUseCase>(),
    ),
  );
  getIt.registerLazySingleton<GetUserUseCase>(
        () => GetUserUseCaseImpl(getIt<AuthRepository>()),
  );

  // ---- Settings ----
  getIt.registerLazySingleton<ThemeController>(() => ThemeController());
  getIt.registerLazySingleton<LocaleController>(() => LocaleController());

  // ---- Products ----
  getIt.registerLazySingleton<ProductDataSource>(
        () => ProductDataSourceImpl(Supabase.instance.client),
  );
  getIt.registerLazySingleton<ProductRepo>(
        () => ProductRepoImpl(getIt<ProductDataSource>(), getIt<NetworkInfo>(), getIt<AppLogger>()),
  );
  getIt.registerLazySingleton<ScanReceiptUseCase>(
        () => ScanReceiptUseCaseImpl(getIt<ProductRepo>()),
  );
  getIt.registerLazySingleton<AddProductUseCase>(
        () => AddProductUseCaseImpl(getIt<ProductRepo>()),
  );
  getIt.registerLazySingleton<UpdateProductUseCase>(
        () => UpdateProductUsecaseImpl(getIt<ProductRepo>()),
  );
  getIt.registerLazySingleton<DeleteProductUseCase>(
        () => DeleteProductUsecaseImpl(getIt<ProductRepo>()),
  );
  getIt.registerLazySingleton<GetProductsUseCase>(
        () => GetProductsUseCaseImpl(getIt<ProductRepo>()),
  );

  getIt.registerLazySingleton<SearchHistoryService>(() => SearchHistoryServiceImpl());

  getIt.registerLazySingleton<NotificationService>(() => NotificationService.instance);
  getIt.registerLazySingleton<NotifiedWarrantiesTracker>(
        () => NotifiedWarrantiesTrackerImpl(),
  );
  getIt.registerLazySingleton<NotificationDataSource>(
        () => NotificationDataSourceImpl(supabaseService: getIt<SupabaseService>()),
  );
  getIt.registerLazySingleton<NotificationRepo>(
        () => NotificationRepoImpl(
      getIt<NotificationDataSource>(),
      getIt<NetworkInfo>(),
      getIt<AppLogger>(),
    ),
  );
  getIt.registerLazySingleton<GetNotificationsUseCase>(
        () => GetNotificationUseCaseImpl(notificationRepo: getIt<NotificationRepo>()),
  );
  getIt.registerLazySingleton<MarkNotificationAsReadUseCase>(
        () => MarkNotificationAsReadUseCaseImpl(notificationRepo: getIt<NotificationRepo>()),
  );
  getIt.registerLazySingleton<DeleteNotificationUseCase>(
        () => DeleteNotificationUseCaseImpl(notificationRepo: getIt<NotificationRepo>()),
  );
  getIt.registerLazySingleton<AddNotificationUseCase>(
        () => AddNotificationUseCaseImpl(notificationRepo: getIt<NotificationRepo>()),
  );
  getIt.registerFactory<NotificationCubit>(
        () => NotificationCubit(
      getNotificationsUseCase: getIt<GetNotificationsUseCase>(),
      markNotificationAsReadUseCase: getIt<MarkNotificationAsReadUseCase>(),
      deleteNotificationUseCase: getIt<DeleteNotificationUseCase>(),
    ),
  );

  getIt.registerLazySingleton<WarrantyNotificationService>(
        () => WarrantyNotificationService(
      getUserUseCase: getIt<GetUserUseCase>(),
      addNotificationUseCase: getIt<AddNotificationUseCase>(),
      tracker: getIt<NotifiedWarrantiesTracker>(),
      localNotifications: getIt<NotificationService>(),
      logger: getIt<AppLogger>(),
    ),
  );

  getIt.registerLazySingleton<ProductsCubit>(
        () => ProductsCubit(
      getIt<GetProductsUseCase>(),
      getIt<DeleteProductUseCase>(),
      getIt<SearchHistoryService>(),
      getIt<WarrantyNotificationService>(),
    ),
  );

  getIt.registerFactory<DetailsCubit>(
        () => DetailsCubit(
      updateProductUseCase: getIt<UpdateProductUseCase>(),
      productsCubit: getIt<ProductsCubit>(),
    ),
  );

  // ---- Chat ----
  getIt.registerLazySingleton<ChatDataSource>(
        () => ChatDataSourceImpl(Supabase.instance.client),
  );
  getIt.registerLazySingleton<ChatRepo>(
        () => ChatRepoImpl(getIt<ChatDataSource>(), getIt<NetworkInfo>(), getIt<AppLogger>()),
  );
  getIt.registerLazySingleton<SendMessageUseCase>(
        () => SendMessageUseCaseImpl(getIt<ChatRepo>()),
  );
  // Singleton (not factory) so chat history survives switching tabs and
  // coming back — matches ProductsCubit's reasoning elsewhere. Must be
  // provided via BlocProvider.value, not create:, for the same reason.
  getIt.registerLazySingleton<ChatCubit>(
        () => ChatCubit(getIt<SendMessageUseCase>()),
  );
}