import 'dart:convert';

SubscriberCheck subscriberCheckFromJSON(String jsonString) =>
    SubscriberCheck.fromJson(json.decode(jsonString));

SubscriberCheckResult subscriberCheckResultFromJSON(String jsonString) =>
    SubscriberCheckResult.fromJson(json.decode(jsonString));

class SubscriberCheck {
  String checkId;
  String checkUrl;

  SubscriberCheck({required this.checkId, required this.checkUrl});

  factory SubscriberCheck.fromJson(Map<String, dynamic> json) =>
      SubscriberCheck(checkId: json["check_id"], checkUrl: json["check_url"]);
}

class SubscriberCheckResult {
  bool match;
  bool simChanged;

  SubscriberCheckResult({required this.match, required this.simChanged});

  factory SubscriberCheckResult.fromJson(Map<String, dynamic> json) =>
      SubscriberCheckResult(match: json["match"], simChanged: !json["no_sim_change"]);
}
