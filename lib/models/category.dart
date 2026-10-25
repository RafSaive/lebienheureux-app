import '../util/html_text.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.count = 0,
    this.parent = 0,
  });

  final int id;
  final String name;
  final String slug;
  final int count;
  final int parent;

  factory Category.fromWp(Map<String, dynamic> json) => Category(
    id: json['id'] as int,
    name: decodeEntities(json['name'] as String? ?? ''),
    slug: json['slug'] as String? ?? '',
    count: json['count'] as int? ?? 0,
    parent: json['parent'] as int? ?? 0,
  );

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as int,
    name: json['name'] as String,
    slug: json['slug'] as String? ?? '',
    count: json['count'] as int? ?? 0,
    parent: json['parent'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'count': count,
    'parent': parent,
  };
}
