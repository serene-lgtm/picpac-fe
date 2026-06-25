class ApiConfig {
  const ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'PICPAC_API_BASE_URL',
    defaultValue: 'http://localhost:9090',
  );
}
