import '../util/html_text.dart';

class Category {
  const Category({required this.id, required this.name, this.count = 0});

  final int id;
  final String name;
  final int count;

  factory Category.fromWp(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: decodeEntities(json['name'] as String? ?? ''),
        count: json['count'] as int? ?? 0,
      );

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String,
        count: json['count'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'count': count};
}
