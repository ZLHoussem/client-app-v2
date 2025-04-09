
class BaggageConstants {
 
  static const String baggageCollection = "baggage";
 
  static const String chauffeursCollection = "users";

  static const String apiBaseUrl = "http://noc80080s4s0wokk4oc4sgog.82.112.242.233.sslip.io/";

  static const String uploadEndpoint = "/api/upload"; 

  static const String imageServeEndpointBase = "/image/";

  static const Duration apiTimeout = Duration(seconds: 30);

  static const int maxArticles = 5; 
  static const int maxImagesPerArticle = 3; 

  static const List<String> validImageExtensions = ['jpg', 'jpeg', 'png'];

  // --- Statuses (Optional but Recommended for consistency) ---
  static const String statusPending = 'En attente';
  static const String statusApproved = 'Approuvé';
  static const String statusRejected = 'Rejeté';
  static const String statusModifiedPending = 'Modifié - En attente';

  BaggageConstants._();
}