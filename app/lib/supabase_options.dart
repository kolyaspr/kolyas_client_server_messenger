/// Настройки подключения к Supabase.
/// ВАЖНО: замените значения своими ключами из Supabase Dashboard → Project Settings → API
class SupabaseOptions {
  // Project URL: Settings → API → Project URL
  static const String supabaseUrl = 'https://smnvkmlovgedafwcjvaw.supabase.co';

  // Anon key: Settings → API → anon public
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNtbnZrbWxvdmdlZGFmd2NqdmF3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE0NTM1OTAsImV4cCI6MjA5NzAyOTU5MH0.X4o8bbVCuSHhZv24LWKKEyOW6LYID6ct0rgjwww5ucw';

  // Bucket для файлов (создать в Supabase Storage)
  static const String filesBucket = 'chat-files';

  // Bucket для аудио
  static const String audioBucket = 'chat-audio';

  // Redirect URI для Google OAuth (должен совпадать с настройками в Google Cloud Console)
  static const String googleRedirectUri =
      'io.supabase.flutterquickstart://login-callback';
}
