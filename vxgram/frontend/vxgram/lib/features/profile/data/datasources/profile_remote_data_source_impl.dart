import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/profile.dart';
import '../models/profile_model.dart';
import 'profile_remote_data_source.dart';

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl(this._c);
  final SupabaseClient _c;
  static const _page = 50;

  String get _uid => _c.auth.currentUser!.id;
  @override
  String? get currentUserId => _c.auth.currentUser?.id;

  List<UserSummaryModel> _users(dynamic res) =>
      (res as List).map((e) => UserSummaryModel.fromJson(Map<String, dynamic>.from(e))).toList();

  @override
  Future<ProfileModel> getProfile(String userId) async {
    final res = await _c.rpc('get_profile', params: {'p_user': userId}) as List;
    if (res.isEmpty) throw Exception('Profile not found');
    return ProfileModel.fromJson(Map<String, dynamic>.from(res.first));
  }

  @override
  Future<FollowStatus> follow(String userId) async =>
      FollowStatus.parse((await _c.rpc('follow_user', params: {'target': userId})) as String?);

  @override
  Future<void> unfollow(String userId) async { await _c.rpc('unfollow_user', params: {'target': userId}); }

  @override
  Future<List<UserSummaryModel>> followers(String userId, int offset) async =>
      _users(await _c.rpc('list_followers', params: {'p_user': userId, 'p_limit': _page, 'p_offset': offset}));

  @override
  Future<List<UserSummaryModel>> following(String userId, int offset) async =>
      _users(await _c.rpc('list_following', params: {'p_user': userId, 'p_limit': _page, 'p_offset': offset}));

  @override
  Future<List<UserSummaryModel>> followRequests() async => _users(await _c.rpc('follow_requests'));

  @override
  Future<void> respondToRequest(String followerId, bool accept) async {
    await _c.rpc('respond_follow_request', params: {'p_follower': followerId, 'p_accept': accept});
  }

  @override
  Future<void> removeFollower(String followerId) async { await _c.rpc('remove_follower', params: {'p_follower': followerId}); }

  @override
  Future<void> updateProfile({String? fullName, String? bio, String? username}) async {
    final data = <String, dynamic>{
      if (fullName != null) 'full_name': fullName.trim(),
      if (bio != null) 'bio': bio.trim(),
      if (username != null) 'username': username.trim().toLowerCase(),
    };
    if (data.isEmpty) return;
    await _c.from('profiles').update(data).eq('id', _uid);
  }

  @override
  Future<void> setPrivate(bool value) async { await _c.from('profiles').update({'is_private': value}).eq('id', _uid); }

  @override
  Future<void> updateAvatar(Uint8List bytes, String ext) async {
    final e = ext.toLowerCase();
    final type = e == 'png' ? 'png' : (e == 'webp' ? 'webp' : 'jpeg');
    final old = await _c.from('profiles').select('avatar_path').eq('id', _uid).single();
    final path = '$_uid/avatar_${DateTime.now().millisecondsSinceEpoch}.${type == 'jpeg' ? 'jpg' : type}';
    await _c.storage.from('avatars').uploadBinary(path, bytes, fileOptions: FileOptions(contentType: 'image/$type'));
    final url = _c.storage.from('avatars').getPublicUrl(path);
    await _c.from('profiles').update({'avatar_url': url, 'avatar_path': path}).eq('id', _uid);
    final prev = old['avatar_path'] as String?;
    if (prev != null) { try { await _c.storage.from('avatars').remove([prev]); } catch (_) {} }
  }
}
