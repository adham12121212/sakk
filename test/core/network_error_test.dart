import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sakk/core/logger/crash_reporting.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('CrashReporting.isNetworkError', () {
    test('offline and timeout errors are network errors', () {
      expect(
        CrashReporting.isNetworkError(
          const SocketException("Failed host lookup: 'x.supabase.co'"),
        ),
        isTrue,
      );
      expect(CrashReporting.isNetworkError(TimeoutException('slow')), isTrue);
      expect(
        CrashReporting.isNetworkError(AuthRetryableFetchException()),
        isTrue,
      );
      expect(
        CrashReporting.isNetworkError(http.ClientException('offline')),
        isTrue,
      );
      expect(
        CrashReporting.isNetworkError(
          Exception("Failed host lookup: 'x.supabase.co'"),
        ),
        isTrue,
      );
    });

    test('real bugs stay fatal', () {
      expect(CrashReporting.isNetworkError(StateError('bad')), isFalse);
      expect(CrashReporting.isNetworkError(ArgumentError('bad')), isFalse);
      expect(CrashReporting.isNetworkError(const FormatException()), isFalse);
    });
  });
}
