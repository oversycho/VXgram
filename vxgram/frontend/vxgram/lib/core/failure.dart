import 'package:supabase_flutter/supabase_flutter.dart';

class AppFailure implements Exception {
  AppFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Wraps backend errors into AppFailure so blocs never see SDK exceptions.
Future<T> guard<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on AuthException catch (e) {
    throw AppFailure(e.message);
  } on PostgrestException catch (e) {
    throw AppFailure(e.message);
  } on StorageException catch (e) {
    throw AppFailure(e.message);
  } catch (e) {
    throw AppFailure(e.toString());
  }
}
