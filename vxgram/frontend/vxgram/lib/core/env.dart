class Env {
  // Paste your values from Supabase -> Project Settings -> API (or pass --dart-define).
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'PASTE_YOUR_SUPABASE_URL_HERE');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'PASTE_YOUR_ANON_KEY_HERE');
  static const linkBase = String.fromEnvironment('LINK_BASE', defaultValue: 'https://vxgram.app');
  static String postLink(String id) => '$linkBase/p/$id';
  static bool get configured => supabaseUrl.startsWith('http') && !supabaseAnonKey.startsWith('PASTE');
}
