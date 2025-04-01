
class BaggageConstants {
  // --- Firestore Collection Names ---
  // TODO: Replace with your actual Firestore collection name for baggage
  static const String baggageCollection = "baggage";
  // TODO: Replace with your actual Firestore collection name for users/chauffeurs (where FCM tokens are)
  static const String chauffeursCollection = "users";

  // --- API Configuration ---
  // TODO: Replace with your actual backend API base URL
  // Example: "http://192.168.1.100:3000" or "https://api.yourdomain.com"
  static const String apiBaseUrl = "http://192.168.1.6:4000";

  // TODO: Replace with your actual API endpoints relative to apiBaseUrl
  static const String uploadEndpoint = "/api/upload"; // Example: "/api/v1/baggage/upload"
  // The base path segment where images are served *and* potentially deleted from.
  // Important for constructing viewable URLs and delete URLs.
  // MUST end with '/' if it represents a directory path on the server.
  // Example: "/images/" or "/uploads/public/"
  static const String imageServeEndpointBase = "/image/";

  // --- API Settings ---
  // Timeout duration for network requests to your backend
  static const Duration apiTimeout = Duration(seconds: 30);

  // --- Baggage Rules ---
  // TODO: Adjust these limits according to your app's rules
  static const int maxArticles = 5; // Maximum articles allowed per baggage submission
  static const int maxImagesPerArticle = 3; // Maximum images allowed per article

  // List of valid image file extensions (lowercase)
  static const List<String> validImageExtensions = ['jpg', 'jpeg', 'png'];

  // --- Statuses (Optional but Recommended for consistency) ---
  static const String statusPending = 'En attente';
  static const String statusApproved = 'Approuvé';
  static const String statusRejected = 'Rejeté';
  static const String statusModifiedPending = 'Modifié - En attente';
  // Add any other statuses your application uses

  // --- Private Constructor ---
  // Prevents anyone from accidentally creating an instance of this constants class.
  BaggageConstants._();
}