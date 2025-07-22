import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_model.dart'; // Make sure this path is correct

class BrowseScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const BrowseScreen({Key? key, this.onToggleTheme}) : super(key: key);

  @override
  _BrowseScreenState createState() => _BrowseScreenState();
}


class _BrowseScreenState extends State<BrowseScreen> with TickerProviderStateMixin {
  List<Workout> _workouts = [];
  List<Workout> _allWorkouts = []; // Store all workouts for search
  List<Workout> _filteredWorkouts = []; // Store filtered workouts
  bool _loading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isSearching = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final TextEditingController _searchController = TextEditingController();

  // Animation Controllers
  // Controller for the Category List (horizontal scroll)
  late AnimationController _categoryListController;
  late Animation<Offset> _categoryListSlideAnimation;
  late Animation<double> _categoryListFadeAnimation;

  // Controller for the "All Workouts" header
  late AnimationController _headerTextController;
  late Animation<Offset> _headerTextSlideAnimation;
  late Animation<double> _headerTextFadeAnimation;

  final Map<String, Map<String, dynamic>> categoryData = {
    'All': {
      'image': 'lib/assets/all.jpeg',
      'icon': Icons.all_inclusive,
    },
    'arms': {
      'image': 'lib/assets/arm.jpeg',
      'icon': Icons.fitness_center,
    },
    'chest': {
      'image': 'lib/assets/chest.jpeg', // Fixed: Ensure .jpeg extension
      'icon': Icons.accessibility_new,
    },
    'abs': {
      'image': 'lib/assets/abs.jpeg',
      'icon': Icons.grid_on,
    },
    'leg': {
      'image': 'lib/assets/leg.jpeg',
      'icon': Icons.directions_run,
    },
    'back': {
      'image': 'lib/assets/back.jpeg',
      'icon': Icons.airline_seat_individual_suite,
    },
    'strength': {
      'image': 'lib/assets/all.jpeg',
      'icon': Icons.sports_gymnastics,
    },
    'yoga': {
      'image': 'lib/assets/all.jpeg',
      'icon': Icons.self_improvement,
    },
    'cardio': {
      'image': 'lib/assets/leg.jpeg',
      'icon': Icons.favorite,
    },
    'hiit': {
      'image': 'lib/assets/all.jpeg',
      'icon': Icons.local_fire_department,
    },
  };

  @override
  void initState() {
   
    super.initState();

    // Initialize Category List Animations
    _categoryListController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _categoryListSlideAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0), // Starts slightly from the right
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _categoryListController,
      curve: Curves.easeOutCubic,
    ));
    _categoryListFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _categoryListController, curve: Curves.easeIn));

    // Initialize Header Text Animations
    _headerTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerTextSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.2, 0), // Starts slightly from the left
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerTextController,
      curve: Curves.easeOutCubic,
    ));
    _headerTextFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _headerTextController, curve: Curves.easeIn));

    // Start initial animations after a small delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _categoryListController.forward();
      _headerTextController.forward();
      _fetchWorkouts(); // Fetch workouts after initial animations are set up
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check for route arguments to set initial category
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null) {
      final String? initialCategory = args['initialCategory'];
      final bool autoSelectFirst = args['autoSelectFirst'] ?? false;
      
      if (initialCategory != null && initialCategory != _selectedCategory) {
        // Set the selected category and fetch workouts
        Future.delayed(const Duration(milliseconds: 200), () {
          _fetchWorkouts(category: initialCategory);
          
          // If autoSelectFirst is true, try to navigate to the first workout
          if (autoSelectFirst) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_workouts.isNotEmpty) {
                Navigator.pushNamed(
                  context,
                  '/workoutDetail',
                  arguments: _workouts.first.id,
                );
              }
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _categoryListController.dispose();
    _headerTextController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
        snapshot = await FirebaseFirestore.instance
            .collection('workouts')
            .where('category', isEqualTo: category)
            .get();
      }

      final newWorkouts = snapshot.docs
          .where((doc) => doc.data() != null)
          .map((doc) => Workout.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
          .toList();

      // Store all workouts for search functionality
      _allWorkouts = List.from(newWorkouts);
      
      // Apply current search filter if active
      _filteredWorkouts = _searchQuery.isEmpty 
          ? List.from(newWorkouts)
          : newWorkouts.where((workout) {
              return workout.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                     workout.category.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();

      // Animate list changes
      // 1. Remove all current items with animation
      if (_workouts.isNotEmpty) {
        for (var i = _workouts.length - 1; i >= 0; i--) {
          final removed = _workouts.removeAt(i);
          _listKey.currentState?.removeItem(
            i,
            (context, animation) => _buildRemovedItem(removed, animation),
            duration: const Duration(milliseconds: 250), // Consistent removal duration
          );
        }
      }

      // 2. Add new items with animation after a short delay
      await Future.delayed(const Duration(milliseconds: 300)); // Delay for removal animation to finish

      // Re-add items one by one to trigger individual item animations
      for (var i = 0; i < _filteredWorkouts.length; i++) {
        _workouts.insert(i, _filteredWorkouts[i]);
        _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 350)); // Consistent insert duration
      }

    } catch (e) {
      print('Error fetching workouts: $e');
      // Consider showing a user-friendly error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load workouts. Please try again.'),
        backgroundColor: Colors.red[400]),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // Search functionality
  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _filteredWorkouts = query.isEmpty 
          ? List.from(_allWorkouts)
          : _allWorkouts.where((workout) {
              return workout.name.toLowerCase().contains(query.toLowerCase()) ||
                     workout.category.toLowerCase().contains(query.toLowerCase());
            }).toList();
      
      // Update the displayed workouts
      _workouts.clear();
      _workouts.addAll(_filteredWorkouts);
    });
  }

  // Pull to refresh functionality
  Future<void> _refreshWorkouts() async {
    await _fetchWorkouts(category: _selectedCategory == 'All' ? null : _selectedCategory);
  }

  // Widget to build the item when it's being removed
  Widget _buildRemovedItem(Workout workout, Animation<double> animation) {
    // This provides a consistent visual for removed items, fading and shrinking
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: _buildWorkoutCardContent(workout, context), // Use the content builder
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
        title: _isSearching 
            ? TextField(
                controller: _searchController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search workouts...',
                  hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                  border: InputBorder.none,
                ),
                onChanged: _performSearch,
                autofocus: true,
              )
            : Text(
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
            icon: Icon(
              _isSearching ? Icons.close : Icons.search, 
              color: primaryColor,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _performSearch(''); // Clear search
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (widget.onToggleTheme != null)
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: primaryColor,
              ),
              onPressed: widget.onToggleTheme,
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshWorkouts,
        color: primaryColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Animated Horizontal Category Cards
          FadeTransition(
            opacity: _categoryListFadeAnimation,
            child: SlideTransition(
              position: _categoryListSlideAnimation,
              child: SizedBox(
                height: 140,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: categoryData.length,
                  itemBuilder: (context, index) {
                    final categoryKey = categoryData.keys.elementAt(index);
                    final data = categoryData[categoryKey]!;
                    final isSelected = _selectedCategory == categoryKey;

                    String displayCategoryName = categoryKey == 'All'
                        ? 'All'
                        : '${categoryKey[0].toUpperCase()}${categoryKey.substring(1)}';

                    return GestureDetector(
                      onTap: () {
                        // Pass the lowercase category key to _fetchWorkouts
                        _fetchWorkouts(category: categoryKey == 'All' ? null : categoryKey);
                      },
                      child: AnimatedContainer(
                        // Smooth animation for color, border, and shadow changes
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: 100,
                        margin: EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? primaryColor : theme.dividerColor.withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4), // Slightly more intense shadow for selection
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ] : [
                            // Subtle shadow for unselected cards
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.05 : 0.08),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
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
                              displayCategoryName,
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
            ),
          ),

          // Animated Category Header Text
          FadeTransition(
            opacity: _headerTextFadeAnimation,
            child: SlideTransition(
              position: _headerTextSlideAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  _selectedCategory == 'All' ? 'All Workouts' : '${_selectedCategory[0].toUpperCase()}${_selectedCategory.substring(1)} Workouts',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),

          // AnimatedList for Workouts
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : _filteredWorkouts.isEmpty
                  ? Center(
                      child: Text(
                        'No workouts found for this category.',
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                    )
                  : AnimatedList(
                      key: _listKey,
                      initialItemCount: _filteredWorkouts.length,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemBuilder: (context, index, animation) {
                        final workout = _filteredWorkouts[index];
                        return _buildWorkoutCard(workout, animation, context);
                      },
                    ),
          ),
        ],
      ),
    ), 
  ); 
  } 

  // Helper function to get category icon (moved outside build for cleanliness)
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'arms':
        return Icons.accessibility;
      case 'abs':
        return Icons.grid_on;
      case 'leg':
        return Icons.directions_run;
      case 'back':
        return Icons.airline_seat_recline_normal;
      case 'strength':
        return Icons.sports_gymnastics;
      case 'yoga':
        return Icons.self_improvement;
      case 'cardio':
        return Icons.favorite;
      case 'hiit':
        return Icons.local_fire_department;
      default:
        return Icons.sports_gymnastics; 
    }
  }

  // This widget now builds the animated workout card
  Widget _buildWorkoutCard(Workout workout, Animation<double> animation, BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.2), // Items slide up from slightly below
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic, // Smooth entry
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn), // Fades in
        child: _buildWorkoutCardContent(workout, context), // Use the content builder
      ),
    );
  }

  // Extracted content of the workout card for reusability (for AnimatedList removeItem)
  Widget _buildWorkoutCardContent(Workout workout, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87);

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4, // Retained a small elevation for depth
      shadowColor: Colors.black.withOpacity(0.1), // Subtle shadow
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
    );
  }
}