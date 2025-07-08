class Workout {
  final String name;
  final String imageAsset;
  final String description;
  final int duration; // in 
  final String? videoAsset;

  

  Workout({
    required this.name,
    required this.imageAsset,
    required this.description,
    required this.duration,
    this.videoAsset,
    
  });
}
