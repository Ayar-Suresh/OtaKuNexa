// lib/models/category_config.dart
class CategoryConfig {
  final String id;
  final String title;
  final String jsonFileName;
  final int insertAtIndex; // Position to show in the list
  final bool enabled; // Whether this category is active

  CategoryConfig({
    required this.id,
    required this.title,
    required this.jsonFileName,
    required this.insertAtIndex,
    this.enabled = true,
  });
}
