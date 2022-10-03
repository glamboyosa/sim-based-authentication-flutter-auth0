class SubscriberCheck {
  final String id;
  final String url;

  SubscriberCheck({required this.id, required this.url});

  factory SubscriberCheck.fromJson(Map<dynamic, dynamic> json) {
    return SubscriberCheck(
      id: json['check_id'],
      url: json['check_url'],
    );
  }
}

class SubscriberCheckResult {
  final String id;
  bool match = false;
  bool noSimChange = true;

  SubscriberCheckResult(
      {required this.id, required this.match, required this.noSimChange});

  factory SubscriberCheckResult.fromJson(Map<dynamic, dynamic> json) {
    return SubscriberCheckResult(
      id: json['check_id'],
      match: json['match'] ?? false,
      noSimChange: json['no_sim_change'] ?? true,
    );
  }
}
