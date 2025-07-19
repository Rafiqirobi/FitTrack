import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:FitTrack/services/firestore_service.dart';

class WorkoutDetailScreen extends StatefulWidget {
  @override
  _WorkoutDetailScreenState createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  bool _isFavorite = false;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoadingFavoriteStatus = true;

  @override
  void initState() {
    super.initState();
    // Load favorite status after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutId = ModalRoute.of(context)!.settings.arguments as String;
      _loadFavoriteStatus(workoutId);
    });
  }

  Future<void> _loadFavoriteStatus(String workoutId) async {
    try {
      final isFavorite = await _firestoreService.isWorkoutFavorited(workoutId);
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
          _isLoadingFavoriteStatus = false;
        });
      }
    } catch (e) {
      print('Error loading favorite status: $e');
      if (mounted) {
        setState(() {
          _isLoadingFavoriteStatus = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(String workoutId) async {
    try {
      await _firestoreService.toggleWorkoutFavorite(workoutId);
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      print('Error toggling favorite status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite status: $e')),
        );
      }
    }
  }

  Future<void> _editStepDialog(String workoutId, int index, Map<String, dynamic> stepData, List steps) async {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    
    final durationController = TextEditingController(text: stepData['duration']?.toString() ?? '');
    final setsController = TextEditingController(text: stepData['sets']?.toString() ?? '');
    final repsController = TextEditingController(text: stepData['reps']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit Step',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInput('Duration (sec)', durationController, theme),
              SizedBox(height: 16),
              _buildInput('Sets', setsController, theme),
              SizedBox(height: 16),
              _buildInput('Reps', repsController, theme),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: textColor.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                steps[index]['duration'] = int.tryParse(durationController.text);
                steps[index]['sets'] = int.tryParse(setsController.text);
                steps[index]['reps'] = int.tryParse(repsController.text);

                await FirebaseFirestore.instance
                    .collection('workouts')
                    .doc(workoutId)
                    .update({'steps': steps});

                Navigator.pop(context);
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInput(String label, TextEditingController controller, ThemeData theme) {
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final primaryColor = theme.primaryColor;
    
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: textColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor.withOpacity(0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDarkMode ? Colors.white : Colors.black87);
    
    final workoutId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'WORKOUT DETAILS',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        actions: [
          IconButton(
            icon: _isLoadingFavoriteStatus 
                ? SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(
                      color: primaryColor, 
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border, 
                    color: _isFavorite ? Colors.red : primaryColor,
                  ),
            onPressed: _isLoadingFavoriteStatus ? null : () => _toggleFavorite(workoutId),
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('workouts').doc(workoutId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading workout: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Workout not found.',
                style: TextStyle(color: textColor.withOpacity(0.7)),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List steps = data['steps'] ?? [];
          final String? mainImageUrl = data['imageUrl'];

          return Container(
            decoration: BoxDecoration(
              gradient: isDarkMode 
                ? LinearGradient(
                    colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main Workout Image
                  _buildWorkoutImage(mainImageUrl, data, primaryColor, cardColor, backgroundColor),
                  
                  SizedBox(height: 20),
                  
                  // Workout Title
                  Text(
                    data['name'] ?? 'Workout',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Workout Stats
                  Row(
                    children: [
                      _buildStat('Calories', '${data['calories'] ?? 'N/A'} kcal', primaryColor, cardColor, textColor),
                      SizedBox(width: 12),
                      _buildStat('Focus', data['category'] ?? 'Full Body', primaryColor, cardColor, textColor),
                      SizedBox(width: 12),
                      _buildStat('Rest', '${data['restTime'] ?? 'N/A'}s', primaryColor, cardColor, textColor),
                    ],
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Steps Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'STEP-BY-STEP GUIDE',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Steps List
                  ...List.generate(
                    steps.length,
                    (i) => _buildStepCard(workoutId, i, steps[i], steps, primaryColor, cardColor, textColor),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Start Workout Button
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/workoutTimer', arguments: data),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'START WORKOUT NOW',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkoutImage(String? mainImageUrl, Map<String, dynamic> data, Color primaryColor, Color cardColor, Color backgroundColor) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: mainImageUrl != null && mainImageUrl.isNotEmpty
                ? Image.asset(
                    mainImageUrl,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder('Failed to load image', cardColor);
                    },
                  )
                : _buildImagePlaceholder('No image available', cardColor),
          ),
          
          // Play Button Overlay
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pushNamed(context, '/workoutTimer', arguments: data),
              icon: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
              iconSize: 60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(String message, Color cardColor) {
    return Container(
      height: 250,
      width: double.infinity,
      color: cardColor.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              color: Colors.white54,
              size: 60,
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color primaryColor, Color cardColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(String workoutId, int index, Map<String, dynamic> step, List steps, Color primaryColor, Color cardColor, Color textColor) {
    final int? duration = step['duration'];
    final int? sets = step['sets'];
    final int? reps = step['reps'];

    String subtitle = '';
    if (duration != null && duration > 0) {
      subtitle = '$duration seconds';
    } else if (sets != null && reps != null && (sets > 0 || reps > 0)) {
      subtitle = '$sets x $reps';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          step['text'] ?? 'Step ${index + 1}',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: subtitle.isNotEmpty 
            ? Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : null,
        trailing: Container(
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(Icons.edit, color: primaryColor),
            onPressed: () => _editStepDialog(workoutId, index, step, steps),
          ),
        ),
      ),
    );
  }
}
