class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mymasjid-backend-2.onrender.com/api',
  );
}

// class ApiConfig {
//   static const String baseUrl = String.fromEnvironment(
//     'API_BASE_URL',
//     defaultValue: 'http://localhost:8080/api',
//   );
// }
