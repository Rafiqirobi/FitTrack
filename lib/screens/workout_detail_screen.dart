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

  Future<void> _editStepDialog(String workoutId, int index, Map<String, dynamic> stepData, List steps) async {
    final durationController = TextEditingController(text: stepData['duration']?.toString() ?? '');
    final setsController = TextEditingController(text: stepData['sets']?.toString() ?? '');
    final repsController = TextEditingController(text: stepData['reps']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardBg,
          title: Text('Edit Step', style: TextStyle(color: neonGreen)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInput('Duration (sec)', durationController),
              _buildInput('Sets', setsController),
              _buildInput('Reps', repsController),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
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
              child: Text('Save', style: TextStyle(color: neonGreen)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: neonGreen),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: Text('WORKOUT DETAILS'),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: neonGreen),
        titleTextStyle: TextStyle(color: neonGreen, fontSize: 18, fontWeight: FontWeight.w700),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: neonGreen),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('workouts').doc(workoutId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: neonGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading workout: ${snapshot.error}', style: TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Workout not found.', style: TextStyle(color: Colors.white70)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List steps = data['steps'] ?? [];
          final String? mainImageUrl = data['imageUrl']; // Get the main image URL

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Main Workout Image (using Image.asset)
                if (mainImageUrl != null && mainImageUrl.isNotEmpty)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset( // <--- CHANGED TO Image.asset
                          mainImageUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 220,
                              width: double.infinity,
                              color: cardBg,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, color: Colors.white54, size: 50),
                                    SizedBox(height: 8),
                                    Text('Failed to load local image', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                    Text('Check pubspec.yaml and path', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      FloatingActionButton(
                        onPressed: () => Navigator.pushNamed(context, '/workoutTimer', arguments: data),
                        backgroundColor: neonGreen,
                        child: Icon(Icons.play_arrow, color: darkBg),
                      )
                    ],
                  )
                else
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardBg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, color: Colors.white54, size: 50),
                          SizedBox(height: 8),
                          Text('No image available', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),

                SizedBox(height: 20),
                Text(
                  data['name'] ?? 'Workout',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat('Calories', '${data['calories'] ?? 'N/A'} kcal'), // Using calories here
                    _buildStat('Focus', data['category'] ?? 'Full Body'),
                    _buildStat('Rest', '${data['restTime'] ?? 'N/A'}s'), // Using restTime here
                  ],
                ),
                SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('STEP-BY-STEP GUIDE', style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 10),
                ...List.generate(steps.length, (i) => _buildStepCard(workoutId, i, steps[i], steps)),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/workoutTimer', arguments: data),
                  child: Text('START WORKOUT NOW'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: neonGreen,
                    foregroundColor: darkBg,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: 6),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: 4),
            Text(value, style: TextStyle(color: neonGreen, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(String workoutId, int index, Map<String, dynamic> step, List steps) {
    final int? duration = step['duration'];
    final int? sets = step['sets'];
    final int? reps = step['reps'];

    String subtitle = '';
    if (duration != null && duration > 0) { // Check if duration is valid
      subtitle = '$duration seconds';
    } else if (sets != null && reps != null && (sets > 0 || reps > 0)) { // Check if sets/reps are valid
      subtitle = '$sets x $reps';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: neonGreen.withOpacity(0.1),
          child: Text('${index + 1}', style: TextStyle(color: neonGreen)),
        ),
        title: Text(step['text'] ?? 'Step', style: TextStyle(color: Colors.white)), // Using 'text' for step description
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: TextStyle(color: accentColor)) : null,
        trailing: IconButton(
          icon: Icon(Icons.edit, color: neonGreen),
          onPressed: () => _editStepDialog(workoutId, index, step, steps),
        ),
      ),
    );
  }
}