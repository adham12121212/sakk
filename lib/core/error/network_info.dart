import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;

  /// Emits the current connectivity once known, then every change
  /// (true = internet reachable).
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnection _connectionChecker;
  NetworkInfoImpl(this._connectionChecker);

  @override
  Future<bool> get isConnected => _connectionChecker.hasInternetAccess;

  @override
  Stream<bool> get onConnectivityChanged => _connectionChecker.onStatusChange
      .map((status) => status == InternetStatus.connected)
      .distinct();
}
