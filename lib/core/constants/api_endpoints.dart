class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String authLogin = '/api/auth/login/';
  static const String authRefresh = '/api/auth/refresh/';
  static const String authRegister = '/api/auth/register/';
  static const String authMe = '/api/auth/me/';
  static const String authLogout = '/api/auth/logout/';

  // Driver app
  static const String authDriverProfile = '/api/auth/driver/profile/';
  static const String authDriverFeed = '/api/auth/driver/feed/';
  static const String authDriverTripsHistory = '/api/auth/driver/trips/history/';

  // Driver management (admin)
  static const String authDrivers = '/api/auth/drivers/';
  static const String authDriversStats = '/api/auth/drivers/stats/';
  static const String authDashboardSummary = '/api/auth/dashboard-summary/';

  // Trips
  static const String trips = '/api/trips/';
  static const String tripsStart = '/api/trips/start/';
  static const String tripsCurrent = '/api/trips/current/';
  static const String tripsStats = '/api/trips/stats/';

  static String tripById(int tripId) => '/api/trips/$tripId/';

  static String tripStop(int tripId) => '/api/trips/$tripId/stop/';

  static String tripResume(int tripId) => '/api/trips/$tripId/resume/';

  static String tripFinish(int tripId) => '/api/trips/$tripId/finish/';

  static String tripCancel(int tripId) => '/api/trips/$tripId/cancel/';

  static String tripLocation(int tripId) => '/api/trips/$tripId/location/';

  static String tripEvents(int tripId) => '/api/trips/$tripId/events/';

  // Alerts
  static const String alerts = '/api/alerts/';
  static const String alertsStats = '/api/alerts/stats/';

  // Emergencies
  static const String emergencies = '/api/emergencies/';

  // Fleet
  static const String vehicles = '/api/vehicles/';
  static const String vehiclesStats = '/api/vehicles/stats/';

  // Reports
  static const String reports = '/api/reports/';
  static const String reportsStats = '/api/reports/stats/';
}
