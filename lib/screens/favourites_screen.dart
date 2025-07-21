import 'package:flutter/material.dart';
import 'dart:async';
import '../models/workout_model.dart';
import '../services/firestore_service.dart';

class FavouritesScreen extends StatefulWidget {
  @override
  _FavouritesScreenState createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  List<Workout> _allFavoriteWorkouts = [];
  bool _isLoading = true;
  StreamSubscription<List<Workout>>? _favoritesSubscription;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAllFavoriteWorkouts();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  // Show delete confirmation dialog
  Future<bool> _confirmDelete(String workoutName) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Favorite'),
          content: Text('Are you sure you want to remove "$workoutName" from favorites?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false; // Return false if dialog is dismissed
  }

  // Handle workout deletion
  Future<void> _handleDelete(Workout workout) async {
    if (await _confirmDelete(workout.name)) {
      await _firestoreService.removeFavoriteWorkout(workout.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${workout.name} removed from favorites'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _loadAllFavoriteWorkouts() {
    _favoritesSubscription?.cancel();
    
    setState(() {
      _isLoading = true;
    });

    _favoritesSubscription = _firestoreService.getFavoriteWorkoutsForCurrentUser().listen(
      (workouts) {
        if (mounted) {
          setState(() {
            _allFavoriteWorkouts = workouts; // Get ALL favorite workouts
            _isLoading = false;
          });
          print('Loaded ${workouts.length} favorite workouts');
        }
      },
      onError: (error) {
        print('Error loading favorite workouts: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  void _navigateToWorkout(String workoutId, String workoutName) {
    Navigator.pushNamed(
      context,
      '/workoutDetail',
      arguments: {
        'workoutId': workoutId,
        'workoutName': workoutName,
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hiit':
        return Icons.flash_on;
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.directions_run;
      case 'flexibility':
        return Icons.accessibility_new;
      case 'yoga':
        return Icons.self_improvement;
      case 'pilates':
        return Icons.balance;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _favoritesSubscription?.cancel();
    super.dispose();
  }

  Widget _buildWorkoutCard(Workout workout, bool isDarkMode) {
    return Dismissible(
      key: Key(workout.id),
      direction: DismissDirection.endToStart, // Only right to left swipe
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(workout.name),
      onDismissed: (_) => _handleDelete(workout),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: Icon(
            _getCategoryIcon(workout.category),
            color: isDarkMode ? Colors.white70 : Colors.black87,
            size: 28,
          ),
          title: Text(
            workout.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            '${workout.duration} mins • ${workout.category}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: isDarkMode ? Colors.white54 : Colors.black54,
          ),
          onTap: () => _navigateToWorkout(workout.id, workout.name),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode 
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                color: isDarkMode ? Colors.white : Colors.black87,
                size: 64,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Favorite Workouts Yet!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Start exploring workouts and add them to your favorites for quick access.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[isDarkMode ? 400 : 600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Favorite Workouts',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading your favorite workouts...',
                        style: TextStyle(
                          color: Colors.grey[isDarkMode ? 400 : 600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : _allFavoriteWorkouts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.favorite_border,
                                color: Theme.of(context).primaryColor,
                                size: 64,
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'No Favorite Workouts Yet!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.headlineMedium?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Start exploring workouts and add them to your favorites for quick access.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[isDarkMode ? 400 : 600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/browse');
                              },
                              icon: Icon(
                                Icons.explore,
                                color: isDarkMode ? Colors.black : Colors.white,
                              ),
                              label: Text(
                                'Explore Workouts',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? Colors.white : Colors.black87,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                shadowColor: isDarkMode 
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats header
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.withOpacity(0.15)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDarkMode 
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.favorite,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_allFavoriteWorkouts.length} Favorite Workouts',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.headlineMedium?.color,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Ready to get started!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[isDarkMode ? 400 : 600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24),
                          
                          // Workouts list
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              itemCount: _allFavoriteWorkouts.length,
                              itemBuilder: (context, index) {
                                final workout = _allFavoriteWorkouts[index];
                                return Dismissible(
                                  key: Key(workout.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  confirmDismiss: (_) => _confirmDelete(workout.name),
                                  onDismissed: (_) => _handleDelete(workout),
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.withOpacity(0.15)),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () => _navigateToWorkout(workout.id, workout.name),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: isDarkMode 
                                                    ? Colors.white.withOpacity(0.1)
                                                    : Colors.black.withOpacity(0.05),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  _getCategoryIcon(workout.category),
                                                  color: isDarkMode ? Colors.white : Colors.black87,
                                                  size: 24,
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      workout.name,
                                                      style: TextStyle(
                                                        color: Theme.of(context).textTheme.headlineMedium?.color,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.category,
                                                          size: 14,
                                                          color: Colors.grey[isDarkMode ? 400 : 600],
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          workout.category.toUpperCase(),
                                                          style: TextStyle(
                                                            color: Colors.grey[isDarkMode ? 400 : 600],
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        SizedBox(width: 16),
                                                        Icon(
                                                          Icons.access_time,
                                                          size: 14,
                                                          color: Colors.grey[isDarkMode ? 400 : 600],
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          '${workout.duration} min',
                                                          style: TextStyle(
                                                            color: Colors.grey[isDarkMode ? 400 : 600],
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 4),
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: isDarkMode 
                                                          ? Colors.white.withOpacity(0.1)
                                                          : Colors.black.withOpacity(0.05),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        'FAVORITE',
                                                        style: TextStyle(
                                                          color: isDarkMode ? Colors.white : Colors.black87,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.chevron_right,
                                                color: isDarkMode ? Colors.white54 : Colors.black54,
                                                size: 24,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
