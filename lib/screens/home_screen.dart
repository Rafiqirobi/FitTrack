import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _messageShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_messageShown) {
      final message = ModalRoute.of(context)?.settings.arguments as String?;
      if (message != null && message.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        });
        _messageShown = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'FitTrack',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              Text(
                'Welcome back!',
                style: TextStyle(
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Ready to crush your fitness goals?',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 30),

              // Quick Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Today\'s Goal',
                      '30 min',
                      Icons.flag_outlined,
                      Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'This Week',
                      '4 workouts',
                      Icons.calendar_today_outlined,
                      Colors.orange.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),

              // Quick Start Card
              Text(
                'Quick Start',
                style: TextStyle(
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.8),
                      Theme.of(context).primaryColor.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/workoutDetail',
                        arguments: 'Quick Start Workout',
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                Icons.flash_on,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                                size: 32,
                              ),
                              Icon(
                                Icons.play_arrow,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                                size: 32,
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Quick Start Workout',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'HIIT • 20 minutes • All levels',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.black87 : Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30),

              // Workout Categories
              Text(
                'Workout Categories',
                style: TextStyle(
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildCategoryCard('Strength', Icons.fitness_center, Colors.red),
                  _buildCategoryCard('Cardio', Icons.directions_run, Colors.blue),
                  _buildCategoryCard('Yoga', Icons.self_improvement, Colors.green),
                  _buildCategoryCard('HIIT', Icons.whatshot, Colors.orange),
                ],
              ),

              SizedBox(height: 30),

              // Today's Motivation
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Today\'s Motivation',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.headlineMedium?.color,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '"The only bad workout is the one that didn\'t happen."',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
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
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).textTheme.headlineMedium?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(context, '/browse');
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
