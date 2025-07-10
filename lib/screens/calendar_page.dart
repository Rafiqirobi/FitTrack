import 'package:flutter/material.dart';

class WorkoutEntry {
  final String name;
  final int duration;

  WorkoutEntry({required this.name, required this.duration});
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
final Color neonGreen = const Color(0xFFCCFF00);
final Color darkBg = const Color(0xFF121212);
final Color cardBg = const Color(0xFF1E1E1E);


  DateTime _focusedMonth = DateTime.now();

  final Map<DateTime, List<WorkoutEntry>> _loggedWorkouts = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: Text(
          'Your Calendar',
          style: TextStyle(
            color: neonGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: darkBg,
        centerTitle: true,
        iconTheme: IconThemeData(color: neonGreen),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            // Header with month & navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: neonGreen),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month - 1,
                      );
                    });
                  },
                ),
                Text(
                  '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                  style: TextStyle(
                    color: neonGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward, color: neonGreen),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Weekday headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              color: neonGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 8),


            // Calendar grid
            Expanded(
              child: _buildCalendarGrid(),
            ),
            _buildProgressChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

    final totalBoxes = ((firstWeekday - 1 + daysInMonth) / 7).ceil() * 7;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: totalBoxes,
      itemBuilder: (context, index) {
        final dayNum = index - (firstWeekday - 2);

        if (dayNum < 1 || dayNum > daysInMonth) {
          return Container(); // Empty cell
        }

        final thisDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
        final isWorkoutDay = _loggedWorkouts.keys.any((d) =>
            d.year == thisDate.year &&
            d.month == thisDate.month &&
            d.day == thisDate.day);

        return GestureDetector(
          onTap: () {
            _showLogWorkoutModal(thisDate);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isWorkoutDay ? neonGreen : cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: neonGreen.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                '$dayNum',
                style: TextStyle(
                  color: isWorkoutDay ? darkBg : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _monthName(int month) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return months[month - 1];
  }

  void _showLogWorkoutModal(DateTime date) {
    final nameController = TextEditingController();
    final durationController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Log Workout for ${date.day}/${date.month}/${date.year}',
                style: TextStyle(
                  color: neonGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Workout Name',
                  labelStyle: TextStyle(color: neonGreen),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: neonGreen),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: neonGreen),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Duration (minutes)',
                  labelStyle: TextStyle(color: neonGreen),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: neonGreen),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: neonGreen),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: darkBg, backgroundColor: neonGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Workout'),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final duration = int.tryParse(durationController.text) ?? 0;

                    if (name.isNotEmpty && duration > 0) {
                      setState(() {
                        final logDate = DateTime(date.year, date.month, date.day);
                        _loggedWorkouts.putIfAbsent(logDate, () => []);
                        _loggedWorkouts[logDate]!.add(
                          WorkoutEntry(name: name, duration: duration),
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

Map<String, int> _getWeeklyTotals() {
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));

  Map<String, int> totals = {
    'Mon': 0,
    'Tue': 0,
    'Wed': 0,
    'Thu': 0,
    'Fri': 0,
    'Sat': 0,
    'Sun': 0,
  };

  _loggedWorkouts.forEach((date, entries) {
    if (date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)))) {
      final dayName = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][date.weekday - 1];
      final totalDuration = entries.fold<int>(0, (sum, e) => sum + e.duration);
      totals[dayName] = (totals[dayName] ?? 0) + totalDuration;
    }
  });

  return totals;
}

Widget _buildProgressChart() {
  final weeklyTotals = _getWeeklyTotals();

  final maxMinutes = weeklyTotals.values.fold<int>(0, (max, v) => v > max ? v : max);
  const barMaxHeight = 100.0;

  return Container(
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Progress',
          style: TextStyle(
            color: neonGreen,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: barMaxHeight + 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weeklyTotals.entries.map((entry) {
              final barHeight = maxMinutes > 0
                  ? (entry.value / maxMinutes) * barMaxHeight
                  : 0.0;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: barHeight,
                      width: 12,
                      decoration: BoxDecoration(
                        color: neonGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}


}
