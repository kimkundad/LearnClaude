class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://learnsbuy.com',
  );
  static const String apiV3   = '$baseUrl/api_v3';

  // Production main site (always production — for public APIs like get_file_app)
  static const String mainUrl = 'https://learnsbuy.com';

  // Node.js chat server (Socket.io + REST)
  static const String chatApi = 'https://chat.learnsbuy.com';

  // teacher user id
  static const int teacherId = 1;

  // Base URL for video thumbnails & course images
  static const String uploadsBase = '$mainUrl/assets/uploads/';

  // Base URL for course PDF files (file_of_course field)
  static const String fileCoursesBase = 'https://www.learnsbuy.com/assets/file_courses/';
}
