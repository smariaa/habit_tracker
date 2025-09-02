import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/quote.dart';

class QuotesProvider extends ChangeNotifier {
  List<Quote> _quotes = [];
  bool _isLoading = false;

  List<Quote> get quotes => _quotes;
  bool get isLoading => _isLoading;

  final List<Quote> _defaultQuotes = [
    Quote(
        id: '1',
        text: 'The best way to get started is to quit talking and begin doing.',
        author: 'Walt Disney'),
    Quote(
        id: '2',
        text: 'Don’t let yesterday take up too much of today.',
        author: 'Will Rogers'),
  ];

  Future<void> loadInitialQuotes() async {
    if (_quotes.isEmpty) await fetchQuotes();
  }

  Future<void> fetchQuotes() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse('https://type.fit/api/quotes');

    try {
      final resp = await http.get(url);

      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List<dynamic>;
        _quotes = list.take(50).map((j) {
          final text = j['text'] ?? '';
          final author = j['author'] ?? 'Unknown';
          final id = '${DateTime.now().millisecondsSinceEpoch}_${text.hashCode}';
          return Quote(id: id, text: text, author: author);
        }).toList();

        if (_quotes.isEmpty) _quotes = _defaultQuotes;
      } else {
        _quotes = _defaultQuotes;
      }
    } catch (e) {
      _quotes = _defaultQuotes;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
