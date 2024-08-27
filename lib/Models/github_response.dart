///Release，A release.
class ReleaseItem {
  List<ReleaseAsset> assets;
  String assetsUrl;
  SimpleUser? author;
  String? body;
  String? bodyHtml;
  String? bodyText;
  DateTime createdAt;

  ///true to create a draft (unpublished) release, false to create a published one.
  bool draft;
  String htmlUrl;
  int id;
  String? name;
  String nodeId;

  ///Whether to identify the release as a prerelease or a full release.
  bool prerelease;
  DateTime? publishedAt;
  ReactionRollup? reactions;

  ///The name of the tag.
  String tagName;
  String? tarballUrl;

  ///Specifies the commitish value that determines where the Git tag is created from.
  String targetCommitish;
  String uploadUrl;
  String url;
  String? zipballUrl;

  ReleaseItem({
    required this.assets,
    required this.assetsUrl,
    required this.author,
    this.body,
    this.bodyHtml,
    this.bodyText,
    required this.createdAt,
    required this.draft,
    required this.htmlUrl,
    required this.id,
    required this.name,
    required this.nodeId,
    required this.prerelease,
    required this.publishedAt,
    this.reactions,
    required this.tagName,
    required this.tarballUrl,
    required this.targetCommitish,
    required this.uploadUrl,
    required this.url,
    required this.zipballUrl,
  });

  factory ReleaseItem.fromJson(Map<String, dynamic> json) => ReleaseItem(
        assets: List<ReleaseAsset>.from(
            json["assets"].map((x) => ReleaseAsset.fromJson(x))),
        assetsUrl: json["assets_url"],
        author:
            json["author"] == null ? null : SimpleUser.fromJson(json["author"]),
        body: json["body"],
        bodyHtml: json["body_html"],
        bodyText: json["body_text"],
        createdAt: DateTime.parse(json["created_at"]),
        draft: json["draft"],
        htmlUrl: json["html_url"],
        id: json["id"],
        name: json["name"],
        nodeId: json["node_id"],
        prerelease: json["prerelease"],
        publishedAt: json["published_at"] == null
            ? null
            : DateTime.parse(json["published_at"]),
        reactions: json["reactions"] == null
            ? null
            : ReactionRollup.fromJson(json["reactions"]),
        tagName: json["tag_name"],
        tarballUrl: json["tarball_url"],
        targetCommitish: json["target_commitish"],
        uploadUrl: json["upload_url"],
        url: json["url"],
        zipballUrl: json["zipball_url"],
      );

  Map<String, dynamic> toJson() => {
        "assets": List<dynamic>.from(assets.map((x) => x.toJson())),
        "assets_url": assetsUrl,
        "author": author?.toJson(),
        "body": body,
        "body_html": bodyHtml,
        "body_text": bodyText,
        "created_at": createdAt.toIso8601String(),
        "draft": draft,
        "html_url": htmlUrl,
        "id": id,
        "name": name,
        "node_id": nodeId,
        "prerelease": prerelease,
        "published_at": publishedAt?.toIso8601String(),
        "reactions": reactions?.toJson(),
        "tag_name": tagName,
        "tarball_url": tarballUrl,
        "target_commitish": targetCommitish,
        "upload_url": uploadUrl,
        "url": url,
        "zipball_url": zipballUrl,
      };
}

///Release Asset，Data related to a release.
class ReleaseAsset {
  String browserDownloadUrl;
  String contentType;
  DateTime createdAt;
  int downloadCount;
  int id;
  String? label;

  ///The file name of the asset.
  String name;
  String nodeId;
  int size;

  ///State of the release asset.
  ReleaseAssetState state;
  DateTime updatedAt;
  dynamic uploader;
  String url;

  ReleaseAsset({
    required this.browserDownloadUrl,
    required this.contentType,
    required this.createdAt,
    required this.downloadCount,
    required this.id,
    required this.label,
    required this.name,
    required this.nodeId,
    required this.size,
    required this.state,
    required this.updatedAt,
    required this.uploader,
    required this.url,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) => ReleaseAsset(
        browserDownloadUrl: json["browser_download_url"],
        contentType: json["content_type"],
        createdAt: DateTime.parse(json["created_at"]),
        downloadCount: json["download_count"],
        id: json["id"],
        label: json["label"],
        name: json["name"],
        nodeId: json["node_id"],
        size: json["size"],
        state: stateValues.map[json["state"]]!,
        updatedAt: DateTime.parse(json["updated_at"]),
        uploader: json["uploader"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "browser_download_url": browserDownloadUrl,
        "content_type": contentType,
        "created_at": createdAt.toIso8601String(),
        "download_count": downloadCount,
        "id": id,
        "label": label,
        "name": name,
        "node_id": nodeId,
        "size": size,
        "state": stateValues.reverse[state],
        "updated_at": updatedAt.toIso8601String(),
        "uploader": uploader,
        "url": url,
      };

  @override
  String toString() {
    return 'ReleaseAsset{browserDownloadUrl: $browserDownloadUrl, contentType: $contentType, createdAt: $createdAt, downloadCount: $downloadCount, id: $id, label: $label, name: $name, nodeId: $nodeId, size: $size, state: $state, updatedAt: $updatedAt, uploader: $uploader, url: $url}';
  }
}

///State of the release asset.
enum ReleaseAssetState { OPEN, UPLOADED }

final stateValues = EnumValues(
    {"open": ReleaseAssetState.OPEN, "uploaded": ReleaseAssetState.UPLOADED});

class SimpleUser {
  String avatarUrl;
  String eventsUrl;
  String followersUrl;
  String followingUrl;
  String gistsUrl;
  String? gravatarId;
  String htmlUrl;
  int id;
  String login;
  String nodeId;
  String organizationsUrl;
  String receivedEventsUrl;
  String reposUrl;
  bool siteAdmin;
  String? starredAt;
  String starredUrl;
  String subscriptionsUrl;
  String type;
  String url;

  SimpleUser({
    required this.avatarUrl,
    required this.eventsUrl,
    required this.followersUrl,
    required this.followingUrl,
    required this.gistsUrl,
    required this.gravatarId,
    required this.htmlUrl,
    required this.id,
    required this.login,
    required this.nodeId,
    required this.organizationsUrl,
    required this.receivedEventsUrl,
    required this.reposUrl,
    required this.siteAdmin,
    this.starredAt,
    required this.starredUrl,
    required this.subscriptionsUrl,
    required this.type,
    required this.url,
  });

  factory SimpleUser.fromJson(Map<String, dynamic> json) => SimpleUser(
        avatarUrl: json["avatar_url"],
        eventsUrl: json["events_url"],
        followersUrl: json["followers_url"],
        followingUrl: json["following_url"],
        gistsUrl: json["gists_url"],
        gravatarId: json["gravatar_id"],
        htmlUrl: json["html_url"],
        id: json["id"],
        login: json["login"],
        nodeId: json["node_id"],
        organizationsUrl: json["organizations_url"],
        receivedEventsUrl: json["received_events_url"],
        reposUrl: json["repos_url"],
        siteAdmin: json["site_admin"],
        starredAt: json["starred_at"],
        starredUrl: json["starred_url"],
        subscriptionsUrl: json["subscriptions_url"],
        type: json["type"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "avatar_url": avatarUrl,
        "events_url": eventsUrl,
        "followers_url": followersUrl,
        "following_url": followingUrl,
        "gists_url": gistsUrl,
        "gravatar_id": gravatarId,
        "html_url": htmlUrl,
        "id": id,
        "login": login,
        "node_id": nodeId,
        "organizations_url": organizationsUrl,
        "received_events_url": receivedEventsUrl,
        "repos_url": reposUrl,
        "site_admin": siteAdmin,
        "starred_at": starredAt,
        "starred_url": starredUrl,
        "subscriptions_url": subscriptionsUrl,
        "type": type,
        "url": url,
      };
}

///Reaction Rollup
class ReactionRollup {
  int the1;
  int reactionRollup1;
  int confused;
  int eyes;
  int heart;
  int hooray;
  int laugh;
  int rocket;
  int totalCount;
  String url;

  ReactionRollup({
    required this.the1,
    required this.reactionRollup1,
    required this.confused,
    required this.eyes,
    required this.heart,
    required this.hooray,
    required this.laugh,
    required this.rocket,
    required this.totalCount,
    required this.url,
  });

  factory ReactionRollup.fromJson(Map<String, dynamic> json) => ReactionRollup(
        the1: json["+1"],
        reactionRollup1: json["-1"],
        confused: json["confused"],
        eyes: json["eyes"],
        heart: json["heart"],
        hooray: json["hooray"],
        laugh: json["laugh"],
        rocket: json["rocket"],
        totalCount: json["total_count"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "+1": the1,
        "-1": reactionRollup1,
        "confused": confused,
        "eyes": eyes,
        "heart": heart,
        "hooray": hooray,
        "laugh": laugh,
        "rocket": rocket,
        "total_count": totalCount,
        "url": url,
      };
}

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
