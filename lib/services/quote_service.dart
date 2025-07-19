import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class Quote {
  final String text;
  final String author;

  Quote({required this.text, required this.author});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      text: json['q'] ?? '',
      author: json['a'] ?? 'Unknown',
    );
  }
}

class QuoteService {
  static const String _baseUrl = 'https://zenquotes.io/api';
  
  // Fallback motivational quotes for fitness (in case API fails)
  static final List<Quote> _fallbackQuotes = [
    Quote(text: "Your body can do it. It's your mind you need to convince!", author: "Fitness Motivation"),
    Quote(text: "Don't stop when you're tired. Stop when you're done!", author: "Fitness Motivation"),
    Quote(text: "The pain you feel today will be the strength you feel tomorrow!", author: "Fitness Motivation"),
    Quote(text: "Success isn't given. It's earned in the gym!", author: "Fitness Motivation"),
    Quote(text: "Champions train, losers complain!", author: "Fitness Motivation"),
    Quote(text: "Push yourself because no one else is going to do it for you!", author: "Fitness Motivation"),
    Quote(text: "Great things never come from comfort zones!", author: "Fitness Motivation"),
    Quote(text: "Make yourself proud!", author: "Fitness Motivation"),
    Quote(text: "The only bad workout is the one that didn't happen!", author: "Fitness Motivation"),
    Quote(text: "Strong is the new beautiful!", author: "Fitness Motivation"),
    Quote(text: "Fitness is not about being better than someone else. It's about being better than you used to be!", author: "Fitness Motivation"),
    Quote(text: "You are stronger than your excuses!", author: "Fitness Motivation"),
    Quote(text: "Every workout gets you one step closer to your goal!", author: "Fitness Motivation"),
    Quote(text: "Train like a beast, look like a beauty!", author: "Fitness Motivation"),
    Quote(text: "The hardest part is showing up!", author: "Fitness Motivation"),
    Quote(text: "Your future self will thank you!", author: "Fitness Motivation"),
    Quote(text: "Believe in yourself and you will be unstoppable!", author: "Fitness Motivation"),
    Quote(text: "Progress, not perfection!", author: "Fitness Motivation"),
    Quote(text: "Make it happen!", author: "Fitness Motivation"),
    Quote(text: "Today's pain is tomorrow's power!", author: "Fitness Motivation"),
  ];

  /// Fetches a random quote from ZenQuotes API
  /// Falls back to local quotes if API fails
  static Future<Quote> getRandomQuote() async {
    try {
      // Try to get quote from ZenQuotes API
      final response = await http.get(
        Uri.parse('$_baseUrl/random'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return Quote.fromJson(data[0]);
        }
      }
      
      // If API fails, return a fallback quote
      return _getFallbackQuote();
    } catch (e) {
      print('Error fetching quote from API: $e');
      // Return a fallback quote on error
      return _getFallbackQuote();
    }
  }

  /// Fetches inspirational quotes from ZenQuotes API
  /// Falls back to local quotes if API fails
  static Future<Quote> getInspirationalQuote() async {
    try {
      // Try to get inspirational quote from ZenQuotes API
      final response = await http.get(
        Uri.parse('$_baseUrl/quotes/inspirational'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          // Get a random quote from the inspirational quotes
          final randomIndex = Random().nextInt(data.length);
          return Quote.fromJson(data[randomIndex]);
        }
      }
      
      // If API fails, return a fallback quote
      return _getFallbackQuote();
    } catch (e) {
      print('Error fetching inspirational quote from API: $e');
      // Return a fallback quote on error
      return _getFallbackQuote();
    }
  }

  /// Gets a random quote from the fallback collection
  static Quote _getFallbackQuote() {
    final random = Random();
    final index = random.nextInt(_fallbackQuotes.length);
    return _fallbackQuotes[index];
  }

  /// Gets today's quote (cached for the day)
  static Future<Quote> getTodayQuote() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/today'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return Quote.fromJson(data[0]);
        }
      }
      
      return _getFallbackQuote();
    } catch (e) {
      print('Error fetching today\'s quote from API: $e');
      return _getFallbackQuote();
    }
  }
}
