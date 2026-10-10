import '../../../../core/failure.dart';
import '../../domain/saved_repository.dart';
import '../datasources/saved_remote_data_source.dart';

class SavedRepositoryImpl implements SavedRepository {
  SavedRepositoryImpl(this._ds);
  final SavedRemoteDataSource _ds;
  @override
  Future<Set<String>> savedIds() => guard(_ds.savedIds);
  @override
  Future<bool> toggle(String postId) => guard(() => _ds.toggle(postId));
}
