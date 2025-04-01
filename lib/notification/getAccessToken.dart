import 'package:googleapis_auth/auth_io.dart';


Future<String> getAccessToken() async {
  // Your service account JSON
  final serviceAccountJson = '''
  {
    "type": "service_account",
    "project_id": "transporteur-aeefc",
    "private_key_id": "6e93199f439abaa20b88bd3685e2eae2477d16ba",
    "private_key": "-----BEGIN PRIVATE KEY-----MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCugB0Qnmei5vgYbrWCWy1UiMJhZTWtIByFToQgBwvlSllZ3ttpWvwqriMJQxrTmjj7TPxFYtSOUGUkdFL17xX4mXagvsRC0vtDtGAqD+tvM8YIHp/Tc5fAeBYEYCPjHIlfOX2i+ln+w4GGB9dqO3TDHipPWHbZiyEasNCy14kHfLeM4mZbqlXJDJy2DA/ZoQ/NGmMwCOU56jR9j7SWxW0Nab0NDrzHyurF9Ovi3U8TRfGk0vrquBGmP8PDTPTLtqK8epA/GNtR/njLU8O0Aij901YseocY9ktZC2Z0zk1bU8evDQhYSrZ1m4/X6YkzeBFX4dKKnTP7tc9Nsj03Ly0jAgMBAAECggEANNOT+PP7a9WAReU+DbiMgIrmTZXWKhMOj0y1svxvHXrkkdBlm/9vV3xgHu2xsV1+4pTryhWhQ3QTKnYMp2c5v4i14PPfdltotZZlhlZLb968lLiwqdLUne+8upZgRuDctXcyEaS4meeVzn2RORfGwUrghCTD1hfIbcwZYgrd8OXPNlmTYkr8bcR3ts1UxfyfY0bWYQCKlsk4lVZ3MVsSLF9VM+oKxnAfDQ0Zk3zlcxX5MdGebYBG/s2MSLZtitdPZaLghdizJThX5As4ienKjPp/DAkK9Q+Xt4vztidUz2mHntLeUcLeB5xsnI0aUCLMf0AP8kuvSXft0fg+0bFsAQKBgQD2Hvzu84AwS81CrXAfqs15zcEmuJ7mwvzesxuuUnsCbiukxPjoxnlJ3Wo1yK263PwumA6LMqlWj3mnkhWUTqnV/GCTtSVeG39BXMljwp/h1XkPPcCdBiWephu2i7tHRiYG11Sz/p63TJebSfaG8DObOCe5jrN+/gsM1kCYq2guPQKBgQC1gTB9PagZMhZnTrzSNGH321h+BFTJT9vLfKIbowXUOq5iWxarvasoYIo2gfKPdsKVh6xHRAxm3lqcuxdL07JyxuKT9jgfGQhWcjds4hOP8pwvucUt0Gh1Rx8Gl8vc6W6x3s99Kv+cwQkP5ZDbEpUFX/pQfTU/dBO/3IblqA7e3wKBgAUeYd5KXCkk+nDfkIxoDfvxhonanxtnhMDQ8stuVbaYOfokSpT0w8MAgtv5f3t6axhA+1RzykfNlhchF6fM9wVHSW7o/oz1f3EJj/quKosU2H6zpxTc8t1Y0Qy73To/QD02L0HLEtv3ENQe9qyZxEj/Ivxd9me2ut4aep9yOSl1AoGAPEifWUmMNmobZM6TCmIZk+AHgTthCcf7YZeQpAs+WWHwH3zPh9UkLvH5lecNMDcqo81/G+BvGg+KGvpM34N9hn+mK6ygsTt4OHYREJn6E1pqI7PY2MGaoDEyDdeG/2WMvYkacyE/6sl2gBAoT4rZcgKRugAMGnosQRI2v7pUzhMCgYEArUG6qA+ol1ieth8tq+qJuu5Jn0KM7nqYuxisYhNuVIn72JLBSHJSDw9Mqg04fPVIFN8mcmEysMjxZ83xRLbUwuQMoD+znCTOAkOdt49znKtWhI+r1Opr1Co0jT6obpJXUEbvHqK07NWXGkxvXOB/zZi/X0tIEJz2C0/P3YS2/Nw=-----END PRIVATE KEY-----",
    "client_email": "firebase-adminsdk-fbsvc@transporteur-aeefc.iam.gserviceaccount.com",
    "client_id": "100472804201778417805",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40transporteur-aeefc.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
  }
  ''';

  final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
  final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  try {
    final client = await clientViaServiceAccount(accountCredentials, scopes);
    final accessToken = client.credentials.accessToken.data;
    client.close();
    return accessToken;
  } catch (e) {
    print('Error getting access token: $e');
    rethrow;
  }
}