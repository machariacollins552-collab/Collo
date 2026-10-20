/// A FitCoach reply the user chose to keep. Saved plans work offline.
class SavedPlan {
  const SavedPlan({
    required this.id,
    required this.title,
    required this.body,
    required this.savedAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'body': body,
        'at': savedAt.millisecondsSinceEpoch,
      };

  static SavedPlan? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final title = json['title'];
    final body = json['body'];
    final at = json['at'];
    if (id is! String || title is! String || body is! String || at is! num) return null;
    return SavedPlan(
      id: id,
      title: title,
      body: body,
      savedAt: DateTime.fromMillisecondsSinceEpoch(at.toInt()),
    );
  }
}
