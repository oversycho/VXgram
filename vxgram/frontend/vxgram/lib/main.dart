import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/env.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/comments/data/datasources/comment_remote_data_source_impl.dart';
import 'features/comments/data/repositories/comment_repository_impl.dart';
import 'features/comments/domain/comment_repository.dart';
import 'features/feed/data/datasources/post_remote_data_source_impl.dart';
import 'features/feed/data/repositories/post_repository_impl.dart';
import 'features/feed/domain/post_repository.dart';
import 'features/profile/data/datasources/profile_remote_data_source_impl.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/profile_repository.dart';
import 'features/settings/settings_cubit.dart';
import 'features/share/data/datasources/share_remote_data_source_impl.dart';
import 'features/share/data/repositories/share_repository_impl.dart';
import 'features/share/domain/share_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Env.configured) {
    runApp(const MaterialApp(home: Scaffold(body: SafeArea(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text(
        'Supabase is not configured.\n\nOpen lib/core/env.dart and paste your Project URL and anon key '
        '(Supabase -> Project Settings -> API), then restart the app.', textAlign: TextAlign.center)))))));
    return;
  }
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
  final prefs = await SharedPreferences.getInstance();
  final client = Supabase.instance.client;

  // Composition root: the ONLY place that knows concrete classes.
  // Variables are typed as the interfaces so context.read<AuthRepository>() resolves.
  final AuthRepository authRepo = AuthRepositoryImpl(AuthRemoteDataSourceImpl(client));
  final PostRepository postRepo = PostRepositoryImpl(PostRemoteDataSourceImpl(client));
  final CommentRepository commentRepo = CommentRepositoryImpl(CommentRemoteDataSourceImpl(client));
  final ShareRepository shareRepo = ShareRepositoryImpl(ShareRemoteDataSourceImpl(client));
  final ProfileRepository profileRepo = ProfileRepositoryImpl(ProfileRemoteDataSourceImpl(client));

  runApp(MultiRepositoryProvider(
    providers: [RepositoryProvider<AuthRepository>.value(value: authRepo), RepositoryProvider<PostRepository>.value(value: postRepo), RepositoryProvider<ProfileRepository>.value(value: profileRepo),
      RepositoryProvider<CommentRepository>.value(value: commentRepo), RepositoryProvider<ShareRepository>.value(value: shareRepo)],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit(prefs)),
        BlocProvider(create: (_) => AuthBloc(authRepo)..add(const AuthStarted())),
      ],
      child: const VxApp(),
    ),
  ));
}
