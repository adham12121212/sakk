import 'package:bloc/bloc.dart';
import '../logger/app_logger.dart';

class AppBlocObserver extends BlocObserver {
  final AppLogger _logger;
  AppBlocObserver(this._logger);

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _logger.debug('Bloc created', data: {'bloc': bloc.runtimeType.toString()});
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _logger.info(
      'State changed',
      data: {
        'bloc': bloc.runtimeType.toString(),
        'from': change.currentState.runtimeType.toString(),
        'to': change.nextState.runtimeType.toString(),
      },
    );
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _logger.debug(
      'Event added',
      data: {'bloc': bloc.runtimeType.toString(), 'event': event.runtimeType.toString()},
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    _logger.error(
      'Bloc error',
      error: error,
      stackTrace: stackTrace,
      data: {'bloc': bloc.runtimeType.toString()},
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    _logger.debug('Bloc closed', data: {'bloc': bloc.runtimeType.toString()});
  }
}