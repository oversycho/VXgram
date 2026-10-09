class Env {
  // Paste your values from Supabase -> Project Settings -> API (or pass --dart-define).
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cxkiaivfkniwotndktfe.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4a2lhaXZma25pd290bmRrdGZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEzODc5NTYsImV4cCI6MjEwNjk2Mzk1Nn0.kfXNSnJycMi6o0t5uX-KrBG3olClngj_PiZrR1qizEE',
  );

  // Base URL used for shareable post links (override with --dart-define=LINK_BASE=...).
  static const linkBase = String.fromEnvironment(
    'LINK_BASE',
    defaultValue: 'https://vxgram.app',
  );

  static String postLink(String id) => '$linkBase/p/$id';

  static bool get configured =>
      supabaseUrl.startsWith('http') && supabaseAnonKey.isNotEmpty;
}
