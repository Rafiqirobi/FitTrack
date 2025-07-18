import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutDetailScreen extends StatefulWidget {
  @override
  _WorkoutDetailScreenState createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  static const Color neonGreen = Color(0xFFCCFF00);
  static const Color darkBg = Color(0xFF121212);
  static const Color cardBg = Color(0xFF1E1E1E);
  static const Color accentColor = Color(0xFF00FFCC);

  bool _isFavorite = false;
  bool _isExpanded = false;

  Future<void> _editDifficulty(String workoutId, String currentDifficulty) async {
    String newDifficulty = currentDifficulty;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardBg,
          title: Text(
            'Set Difficulty',
            style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<String>(
                value: newDifficulty,
                dropdownColor: cardBg,
                iconEnabledColor: neonGreen,
                isExpanded: true,
                items: ['Easy', 'Medium', 'Hard']
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(level, style: TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => newDifficulty = value);
                  }
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('workouts')
                    .doc(workoutId)
                    .update({'difficulty': newDifficulty});
                Navigator.pop(context);
                setState(() {});
              },
              child: Text('Save', style: TextStyle(color: neonGreen)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editStepDialog(String workoutId, int? duration, int? sets, int? reps) async {
    TextEditingController durationController =
        TextEditingController(text: duration?.toString() ?? '');
    TextEditingController setsController =
        TextEditingController(text: sets?.toString() ?? '');
    TextEditingController repsController =
        TextEditingController(text: reps?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardBg,
          title: Text(
            'Edit Workout Details',
            style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Duration (seconds)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: setsController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Sets',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Reps',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('workouts')
                    .doc(workoutId)
                    .update({
                  'duration': durationController.text.isNotEmpty
                      ? int.tryParse(durationController.text)
                      : null,
                  'sets': setsController.text.isNotEmpty
                      ? int.tryParse(setsController.text)
                      : null,
                  'reps': repsController.text.isNotEmpty
                      ? int.tryParse(repsController.text)
                      : null,
                });
                Navigator.pop(context);
                setState(() {});
              },
              child: Text('Save', style: TextStyle(color: neonGreen)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String workoutId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text('WORKOUT DETAILS'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: neonGreen),
        titleTextStyle: const TextStyle(
          color: neonGreen,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : neonGreen,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              // TODO: Save favorite state
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('workouts').doc(workoutId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: neonGreen, strokeWidth: 2.5),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'WORKOUT NOT FOUND',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> steps = data['steps'] ?? [];
          final List<dynamic> equipment = data['equipment'] ?? [];
          final List<dynamic> targetMuscles = data['targetMuscles'] ?? [];

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['imageUrl'] != null && data['imageUrl'] != 'imageUrl')
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 220,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: neonGreen.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            data['imageUrl'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      FloatingActionButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/workoutTimer', arguments: data);
                        },
                        backgroundColor: neonGreen.withOpacity(0.9),
                        child: const Icon(Icons.play_arrow, color: darkBg, size: 32),
                      ),
                    ],
                  ),

                // Summary Card without reps/time
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Workout',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _editDifficulty(workoutId, data['difficulty'] ?? 'Medium'),
                        child: _buildInfoChip(
                          Icons.fitness_center,
                          '${data['difficulty'] ?? 'Medium'} (Edit)',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard('Calories', '${data['calories'] ?? 120} kcal'),
                    _buildStatCard('Focus Area', data['category'] ?? 'Full Body'),
                    _buildStatCard('Rest Time', '${data['restTime'] ?? 30}s'),
                  ],
                ),

                const SizedBox(height: 24),

                // Steps
                const Text(
                  'STEP-BY-STEP GUIDE',
                  style: TextStyle(
                    color: neonGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                ...List.generate(steps.length, (index) {
                  final step = steps[index];
                  return _buildStepCard(
                    workoutId,
                    index + 1,
                    step,
                    data['duration'],
                    data['sets'],
                    data['reps'],
                  );
                }),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: neonGreen,
                      foregroundColor: darkBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'START WORKOUT NOW',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/workoutTimer', arguments: data);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepCard(String workoutId, int stepNumber, String text, int? duration, int? sets, int? reps) {
    String subtitle = '';
    if (duration != null) {
      subtitle = '$duration seconds';
    } else if (sets != null && reps != null) {
      subtitle = '$sets x $reps';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          splashColor: neonGreen.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: neonGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: neonGreen.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    stepNumber.toString(),
                    style: const TextStyle(
                      color: neonGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: neonGreen, size: 20),
                  onPressed: () => _editStepDialog(workoutId, duration, sets, reps),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Chip(
      backgroundColor: cardBg,
      avatar: Icon(icon, size: 16, color: neonGreen),
      label: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: neonGreen,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
