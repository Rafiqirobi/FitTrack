class Workout {
  String id;      // <-- Add this
  final String name;
  final String description;
  final int duration;
  final String imageUrl;
  final String category;

  Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.imageUrl,
    required this.category,
  });

  factory Workout.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return Workout(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      duration: map['duration'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? ''
    );
  }
}
