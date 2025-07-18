import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_model.dart';

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

  final Map<String, Map<String, dynamic>> categoryData = {
    'All': {
      'image': 'lib/assets/all.jpeg',
      'icon': Icons.all_inclusive,
    },
    'Arm': {
      'image': 'lib/assets/arm.jpeg',
      'icon': Icons.fitness_center,
    },
    'Chest': {
      'image': 'lib/assets/chest.jpeg',
      'icon': Icons.accessibility_new,
    },
    'Abs': {
      'image': 'lib/assets/abs.jpeg',
      'icon': Icons.grid_on,
    },
    'Legs': {
      'image': 'lib/assets/leg.jpeg',
      'icon': Icons.directions_run,
    },
    'Back': {
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
      _selectedCategory = category ?? 'All';
    });

    QuerySnapshot snapshot;
    
    try {
      if (category == null || category == 'All') {
        snapshot = await FirebaseFirestore.instance.collection('workouts').get();
      } else {
        // Ensure category names match exactly (case-sensitive)
        snapshot = await FirebaseFirestore.instance
            .collection('workouts')
            .where('category', isEqualTo: category)
            .get();
      }

      final newWorkouts = snapshot.docs
          .where((doc) => doc.data() != null)
          .map((doc) => Workout.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
          .toList();

      // Animate list changes
      if (_workouts.isNotEmpty) {
        // Remove all items with animation
        for (var i = _workouts.length - 1; i >= 0; i--) {
          final removed = _workouts.removeAt(i);
          _listKey.currentState?.removeItem(
            i,
            (context, animation) => _buildRemovedItem(removed, animation),
          );
        }
      }

      // Add new items with animation
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
    final size = MediaQuery.of(context).size;
    
    final primaryColor = isDark ? Color(0xFF00F0FF) : Color(0xFF0066FF);
    final backgroundColor = isDark ? Color(0xFF121212) : Color(0xFFFAFAFA);
    final cardColor = isDark ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal Category Cards
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: categoryData.length,
                    itemBuilder: (context, index) {
                      final category = categoryData.keys.elementAt(index);
                      final data = categoryData[category]!;
                      
                      return GestureDetector(
                        onTap: () {
                          // Add a slight delay to make animation more visible
                          Future.delayed(Duration(milliseconds: 50), () {
                            _fetchWorkouts(category: category == 'All' ? null : category);
                          });
                        },
                        child: Container(
                          width: size.width * 0.7,
                          margin: EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  data['image'],
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      data['icon'],
                                      color: primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  bottom: 16,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category == 'All' ? 'All Workouts' : '$category Workouts',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    _selectedCategory == 'All' ? 'All Workouts' : '$_selectedCategory Workouts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
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
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: primaryColor.withOpacity(0.1),
                                ),
                                child: Icon(
                                  _getCategoryIcon(workout.category),
                                  color: primaryColor,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                workout.name,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: textColor.withOpacity(0.5),
                                size: 16,
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/workoutDetail',
                                  arguments: workout.id,
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'arm':
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
}