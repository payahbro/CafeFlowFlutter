class AppConfig {
  const AppConfig._();

  static const String backendOrigin = String.fromEnvironment(
    'BACKEND_ORIGIN',
    defaultValue: 'http://34.101.80.186:8080',
  );

  static const String apiBaseUrl = '$backendOrigin/api/v1';

  static const String productBaseUrl = apiBaseUrl;

  static const String orderBaseUrl = apiBaseUrl;

  static const String paymentBaseUrl = apiBaseUrl;

  static const String adminBaseUrl = apiBaseUrl;

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kangzprbrstwuuejpmso.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imthbmd6cHJicnN0d3V1ZWpwbXNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1MjY3ODgsImV4cCI6MjA5MTEwMjc4OH0.Ioo0A7Kw3HMQQd7k5W5r6xUlBpvi4o_T3NdCtSag3y4',
  );

  static const String supabaseAuthBaseUrl = '$supabaseUrl/auth/v1';
}
