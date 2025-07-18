import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_model.dart'; // Make sure this path is correct

class BrowseScreen extends StatefulWidget {
  @override
  _BrowseScreenState createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  List<Workout> _workouts = [];
  bool _loading = true;
  String _selectedCategory = 'All';
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // ✅ CHANGE: Make keys lowercase to match Firestore data
  final Map<String, Map<String, dynamic>> categoryData = {
    'All': {
      'image': 'lib/assets/all.jpeg',
      'icon': Icons.all_inclusive,
    },
    'arms': { // Changed from 'Arms'
      'image': 'lib/assets/arm.jpeg',
      'icon': Icons.fitness_center,
    },
    'chest': { // Changed from 'Chest'
      'image': 'lib/assets/chest', // This looks like a path, not a full .jpeg extension, check this.
      'icon': Icons.accessibility_new,
    },
    'abs': { // Changed from 'Abs'
      'image': 'lib/assets/abs.jpeg',
      'icon': Icons.grid_on,
    },
    'legs': { // Changed from 'Legs'
      'image': 'lib/assets/leg.jpeg',
      'icon': Icons.directions_run,
    },
    'back': { // Changed from 'Back'
      'image': 'lib/assets/back.jpeg',
      'icon': Icons.airline_seat_individual_suite,
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchWorkouts();
  }

  Future<void> _fetchWorkouts({String? category}) async {
    setState(() {
      _loading = true;
      // When setting _selectedCategory, ensure it's in the correct case for display
      _selectedCategory = category ?? 'All';
    });

    QuerySnapshot snapshot;

    try {
      if (category == null || category == 'All') {
        snapshot = await FirebaseFirestore.instance.collection('workouts').get();
      } else {
        // The `category` variable passed here will now be lowercase, matching Firestore
        snapshot = await FirebaseFirestore.instance
            .collection('workouts')
            .where('category', isEqualTo: category) // This now correctly uses the lowercase category
            .get();
      }

      final newWorkouts = snapshot.docs
          .where((doc) => doc.data() != null)
          .map((doc) => Workout.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
          .toList();

      // Animate list changes
      // Remove all items with animation
      if (_workouts.isNotEmpty) {
        for (var i = _workouts.length - 1; i >= 0; i--) {
          final removed = _workouts.removeAt(i);
          _listKey.currentState?.removeItem(
            i,
            (context, animation) => _buildRemovedItem(removed, animation),
          );
        }
      }

      // Add new items with animation
      // A small delay can help the animation look smoother, especially on removal
      await Future.delayed(Duration(milliseconds: 300));
      for (var i = 0; i < newWorkouts.length; i++) {
        _workouts.insert(i, newWorkouts[i]);
        _listKey.currentState?.insertItem(i);
      }

    } catch (e) {
      print('Error fetching workouts: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildRemovedItem(Workout workout, Animation<double> animation) {
    // You might want to make this look consistent with _buildWorkoutCard if it's shown
    // or just a simpler representation.
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        margin: EdgeInsets.only(bottom: 12),
        child: ListTile(
          title: Text(workout.name),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.primaryColor;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Browse Workouts',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: primaryColor),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal Category Cards
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: categoryData.length,
                    itemBuilder: (context, index) {
                      final categoryKey = categoryData.keys.elementAt(index); // This is the lowercase key
                      final data = categoryData[categoryKey]!;
                      final isSelected = _selectedCategory == categoryKey; // Compare with lowercase key

                      // For display, you might want to capitalize the category name
                      String displayCategoryName = categoryKey == 'All'
                          ? 'All'
                          : '${categoryKey[0].toUpperCase()}${categoryKey.substring(1)}';

                      return GestureDetector(
                        onTap: () {
                          // Pass the lowercase category key to _fetchWorkouts
                          _fetchWorkouts(category: categoryKey == 'All' ? null : categoryKey);
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: 100,
                          margin: EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor : cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? primaryColor : theme.dividerColor,
                              width: 1.5,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ] : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                data['icon'],
                                color: isSelected ? (isDark ? Colors.black : Colors.white) : primaryColor,
                                size: 32,
                              ),
                              SizedBox(height: 8),
                              Text(
                                displayCategoryName, // Use the capitalized display name
                                style: TextStyle(
                                  color: isSelected ? (isDark ? Colors.black : Colors.white) : textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    // Display capitalized category name for the header
                    _selectedCategory == 'All' ? 'All Workouts' : '${_selectedCategory[0].toUpperCase()}${_selectedCategory.substring(1)} Workouts',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),

                Expanded(
                  child: AnimatedList(
                    key: _listKey,
                    initialItemCount: _workouts.length,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (context, index, animation) {
                      final workout = _workouts[index];
                      return _buildWorkoutCard(workout, animation, context);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  IconData _getCategoryIcon(String category) {
    // Ensure this also works with lowercase categories from workout objects
    switch (category.toLowerCase()) { // ✅ Keep .toLowerCase() here for robustness
      case 'chest':
        return Icons.fitness_center;
      case 'arms':
        return Icons.accessibility;
      case 'abs':
        return Icons.grid_on;
      case 'legs':
        return Icons.directions_run;
      case 'back':
        return Icons.airline_seat_recline_normal;
      default:
        return Icons.sports_gymnastics;
    }
  }

  Widget _buildWorkoutCard(Workout workout, Animation<double> animation, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87);

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      )),
      child: FadeTransition(
        opacity: animation,
        child: Card(
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.only(bottom: 16),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/workoutDetail',
                arguments: workout.id,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: primaryColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      _getCategoryIcon(workout.category),
                      color: primaryColor,
                      size: 30,
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
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              '${workout.duration} min',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.local_fire_department_outlined, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              '${workout.calories} kcal',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: textColor.withOpacity(0.5),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}