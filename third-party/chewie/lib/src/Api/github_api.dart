import 'package:dio/dio.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class GithubApi {
  static Future<List<ReleaseItem>> getReleases(String user, String repo) async {
    String url = "https://api.github.com/repos/$user/$repo/releases";
    try {
      final response = await Dio().get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          final List<ReleaseItem> items =
              (data).map((e) => ReleaseItem.fromJson(e)).toList();
          return items;
        }
      }
    } catch (e, t) {
      ILogger.error("Failed to load releases for $url", e, t);
    }
    return [];
  }
}
