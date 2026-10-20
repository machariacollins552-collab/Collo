import '../core/format.dart';

/// One weight reading for one calendar day.
class WeightEntry {
  const WeightEntry({required this.dateKey, required this.kg});

  /// `yyyy-mm-dd`
  final String dateKey;
  final double kg;

  DateTime get date => parseDateKey(dateKey) ?? DateTime.now();

  Map<String, dynamic> toJson() => <String, dynamic>{'d': dateKey, 'kg': kg};

  static WeightEntry? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final d = json['d'];
    final kg = json['kg'];
    if (d is! String || kg is! num) return null;
    if (parseDateKey(d) == null) return null;
    return WeightEntry(dateKey: d, kg: kg.toDouble());
  }
}
