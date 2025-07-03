import 'package:flutter/material.dart';

class BrowseScreen extends StatelessWidget {
  // Categories
  final List<String> categories = [
    'Strength',
    'Cardio',
    'Flexibility',
    'HIIT',
    'Yoga',
  ];

  // Workout preview data
  final List<Map<String, String>> workouts = [
    {'title': 'Full Body Burn', 'subtitle': 'HIIT • 20 min'},
    {'title': 'Morning Yoga', 'subtitle': 'Flexibility • 15 min'},
    {'title': 'Core Crusher', 'subtitle': 'Strength • 25 min'},
    {'title': 'Cardio Blast', 'subtitle': 'Cardio • 30 min'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Browse Workouts', style: theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ✅ Search Bar
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                style: TextStyle(color: theme.primaryColor),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: theme.primaryColor),
                  hintText: 'Search workouts',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor ?? Colors.grey,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ✅ Categories Header
            Text(
              'Categories',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // ✅ Categories Scroll
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.primaryColor),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      categories[index],
                      style: TextStyle(color: theme.primaryColor),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ✅ Recommended Workouts Header
            Text(
              'Recommended Workouts',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // ✅ Workout Cards
            Column(
              children: workouts.map((workout) {
                return Card(
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      workout['title'] ?? '',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      workout['subtitle'] ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor ?? Colors.grey,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: theme.primaryColor,
                      size: 18,
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/workoutDetail',
                        arguments: workout['title'],
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
