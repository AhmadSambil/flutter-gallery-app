class ApiConfig {
  static const String baseUrl = "http://192.168.0.105/flutter_api";
  static const String header_apikey = "my_secret_api_key_123";

  static const String loginUrl = "$baseUrl/login.php";
  static const String getpostUrl = "$baseUrl/get_posts.php";
  static const String uploadpostUrl = "$baseUrl/upload_post.php";
}