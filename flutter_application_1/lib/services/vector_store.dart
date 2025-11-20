import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class VectorStore {
  List<Map<String, dynamic>> _qaPairs = [];
  final Map<String, List<double>> _vectors = {};
  List<String> _vocabulary = [];

  Future<void> loadQAFromAssets() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/qa_data.json',
      );
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _qaPairs = jsonList.cast<Map<String, dynamic>>();
      await _buildVocabulary();
      await _vectorizeQuestions();
      print('✅ Loaded ${_qaPairs.length} Q&A pairs');
    } catch (e) {
      print('Error loading QA data: $e');
    }
  }

  Future<void> _buildVocabulary() async {
    final Set<String> vocabSet = {};
    for (var pair in _qaPairs) {
      final words = _preprocessText(pair['question']).split(' ');
      vocabSet.addAll(words);
    }
    _vocabulary = vocabSet.toList();
  }

  Future<void> _vectorizeQuestions() async {
    for (int i = 0; i < _qaPairs.length; i++) {
      final question = _preprocessText(_qaPairs[i]['question']);
      _vectors[i.toString()] = _textToVector(question);
    }
  }

  List<double> _textToVector(String text) {
    final List<double> vector = List<double>.filled(_vocabulary.length, 0.0);
    final words = text.split(' ');

    for (String word in words) {
      final index = _vocabulary.indexOf(word);
      if (index != -1) {
        vector[index] += 1.0;
      }
    }
    return vector;
  }

  String _preprocessText(String text) {
    // Better text normalization
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
  }

  double _cosineSimilarity(List<double> vecA, List<double> vecB) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }

    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  Map<String, dynamic>? findBestMatch(String query, {double threshold = 0.4}) {
    final processedQuery = _preprocessText(query);
    final queryVector = _textToVector(processedQuery);

    double bestScore = 0.0;
    Map<String, dynamic>? bestMatch;
    int bestMatchIndex = -1;

    for (int i = 0; i < _qaPairs.length; i++) {
      final similarity = _cosineSimilarity(
        queryVector,
        _vectors[i.toString()]!,
      );

      // Also check for keyword matches as fallback
      final keywordScore = _calculateKeywordScore(
        processedQuery,
        _qaPairs[i]['question'],
      );
      final combinedScore = (similarity * 0.7) + (keywordScore * 0.3);

      if (combinedScore > bestScore && combinedScore > threshold) {
        bestScore = combinedScore;
        bestMatch = _qaPairs[i];
        bestMatchIndex = i;
      }
    }

    print(
      '🔍 Query: "$query" -> Best match: ${bestMatch?['question']} (Score: ${bestScore.toStringAsFixed(2)})',
    );

    return bestMatch;
  }

  double _calculateKeywordScore(String query, String storedQuestion) {
    final queryWords = query.split(' ');
    final storedWords = _preprocessText(storedQuestion).split(' ');

    int matches = 0;
    for (String qWord in queryWords) {
      if (qWord.length > 2) {
        // Ignore short words
        for (String sWord in storedWords) {
          if (qWord == sWord) {
            matches++;
            break;
          }
        }
      }
    }

    return matches / max(queryWords.length, storedWords.length);
  }

  // NEW: Get similar questions for debugging
  List<Map<String, dynamic>> findSimilarQuestions(
    String query, {
    int limit = 5,
  }) {
    final processedQuery = _preprocessText(query);
    final queryVector = _textToVector(processedQuery);

    final List<Map<String, dynamic>> results = [];

    for (int i = 0; i < _qaPairs.length; i++) {
      final similarity = _cosineSimilarity(
        queryVector,
        _vectors[i.toString()]!,
      );
      final keywordScore = _calculateKeywordScore(
        processedQuery,
        _qaPairs[i]['question'],
      );
      final combinedScore = (similarity * 0.7) + (keywordScore * 0.3);

      results.add({
        'question': _qaPairs[i]['question'],
        'score': combinedScore,
        'index': i,
      });
    }

    results.sort((a, b) => b['score'].compareTo(a['score']));
    return results.take(limit).toList();
  }
}
