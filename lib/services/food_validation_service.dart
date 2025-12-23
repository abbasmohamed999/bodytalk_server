// lib/services/food_validation_service.dart
// On-device food detection gate using Google ML Kit Image Labeling

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// Result of food validation
class FoodValidationResult {
  final bool isFood;
  final String? errorMessage;
  final List<String> detectedLabels;
  final double confidence;

  FoodValidationResult({
    required this.isFood,
    this.errorMessage,
    this.detectedLabels = const [],
    this.confidence = 0.0,
  });
}

/// Service to validate if an image contains food using ML Kit Image Labeling
class FoodValidationService {
  static final FoodValidationService _instance =
      FoodValidationService._internal();
  factory FoodValidationService() => _instance;
  FoodValidationService._internal();

  late final ImageLabeler _imageLabeler;
  bool _isInitialized = false;

  /// Food-related labels that indicate the image contains food
  static const Set<String> _foodLabels = {
    // General food terms
    'food', 'dish', 'meal', 'cuisine', 'recipe', 'ingredient',
    // Fruits
    'fruit', 'apple', 'banana', 'orange', 'grape', 'strawberry', 'watermelon',
    'mango', 'pineapple', 'peach', 'pear', 'cherry', 'berry', 'lemon', 'lime',
    // Vegetables
    'vegetable', 'salad', 'lettuce', 'tomato', 'cucumber', 'carrot', 'broccoli',
    'spinach', 'onion', 'potato', 'pepper', 'corn', 'cabbage', 'cauliflower',
    // Proteins
    'meat', 'chicken', 'beef', 'pork', 'fish', 'seafood', 'shrimp', 'steak',
    'egg', 'sausage', 'bacon', 'lamb', 'turkey', 'salmon', 'tuna',
    // Grains & Carbs
    'bread', 'rice', 'pasta', 'noodle', 'cereal', 'grain', 'wheat', 'oat',
    'pizza', 'sandwich', 'burger', 'hot dog', 'taco', 'burrito', 'wrap',
    // Dairy
    'cheese', 'milk', 'yogurt', 'butter', 'cream', 'dairy',
    // Desserts
    'dessert', 'cake', 'cookie', 'pie', 'ice cream', 'chocolate', 'candy',
    'pastry', 'donut', 'muffin', 'cupcake', 'brownie', 'pudding',
    // Beverages (food-related)
    'juice', 'smoothie', 'soup', 'broth', 'coffee', 'tea',
    // Prepared foods
    'breakfast', 'lunch', 'dinner', 'snack', 'appetizer', 'entree',
    'plate', 'bowl', 'platter', 'buffet',
    // Specific dishes
    'sushi', 'curry', 'stew', 'grill', 'roast', 'fry', 'bake',
    'hummus', 'falafel', 'kebab', 'shawarma', 'biryani', 'couscous',
    // Kitchen context
    'kitchen', 'restaurant', 'dining', 'table setting',
  };

  /// Labels that indicate NON-food images (screens, devices, etc.)
  static const Set<String> _nonFoodLabels = {
    'screen',
    'monitor',
    'laptop',
    'computer',
    'phone',
    'tablet',
    'television',
    'tv',
    'display',
    'keyboard',
    'mouse',
    'electronic',
    'device',
    'gadget',
    'screenshot',
    'website',
    'app',
    'interface',
    'text',
    'document',
    'paper',
    'car',
    'vehicle',
    'building',
    'architecture',
    'street',
    'road',
    'person',
    'face',
    'portrait',
    'selfie',
    'clothing',
    'fashion',
    'furniture',
  };

  /// Minimum confidence threshold for food detection
  static const double _confidenceThreshold = 0.4;

  /// Initialize the image labeler
  Future<void> initialize() async {
    if (_isInitialized) return;

    final options = ImageLabelerOptions(confidenceThreshold: 0.3);
    _imageLabeler = ImageLabeler(options: options);
    _isInitialized = true;
    debugPrint('✅ FoodValidationService initialized');
  }

  /// Validate if the image contains food
  Future<FoodValidationResult> validateFoodImage(
    File imageFile, {
    required String locale,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final inputImage = InputImage.fromFile(imageFile);
      final labels = await _imageLabeler.processImage(inputImage);

      debugPrint('🏷️ ML Kit detected ${labels.length} labels');

      final detectedLabels = <String>[];
      double maxFoodConfidence = 0.0;
      bool hasNonFoodIndicator = false;
      double maxNonFoodConfidence = 0.0;

      for (final label in labels) {
        final labelText = label.label.toLowerCase();
        final confidence = label.confidence;

        detectedLabels
            .add('${label.label} (${(confidence * 100).toStringAsFixed(1)}%)');
        debugPrint('  - $labelText: ${(confidence * 100).toStringAsFixed(1)}%');

        // Check for food-related labels
        for (final foodLabel in _foodLabels) {
          if (labelText.contains(foodLabel) && confidence > maxFoodConfidence) {
            maxFoodConfidence = confidence;
          }
        }

        // Check for non-food indicators
        for (final nonFoodLabel in _nonFoodLabels) {
          if (labelText.contains(nonFoodLabel) && confidence > 0.5) {
            hasNonFoodIndicator = true;
            if (confidence > maxNonFoodConfidence) {
              maxNonFoodConfidence = confidence;
            }
          }
        }
      }

      debugPrint(
          '📊 Max food confidence: ${(maxFoodConfidence * 100).toStringAsFixed(1)}%');
      debugPrint(
          '📊 Has non-food indicator: $hasNonFoodIndicator (${(maxNonFoodConfidence * 100).toStringAsFixed(1)}%)');

      // Decision logic:
      // 1. If strong non-food indicator detected (screen/device) with high confidence → reject
      // 2. If food confidence is below threshold → reject
      // 3. Otherwise → accept

      if (hasNonFoodIndicator && maxNonFoodConfidence > 0.6) {
        return FoodValidationResult(
          isFood: false,
          errorMessage: _getErrorMessage(locale, 'screen_detected'),
          detectedLabels: detectedLabels,
          confidence: maxNonFoodConfidence,
        );
      }

      if (maxFoodConfidence < _confidenceThreshold) {
        return FoodValidationResult(
          isFood: false,
          errorMessage: _getErrorMessage(locale, 'not_food'),
          detectedLabels: detectedLabels,
          confidence: maxFoodConfidence,
        );
      }

      // Food detected!
      return FoodValidationResult(
        isFood: true,
        detectedLabels: detectedLabels,
        confidence: maxFoodConfidence,
      );
    } catch (e) {
      debugPrint('❌ FoodValidationService error: $e');
      // On error, allow the image to proceed (fail-open for UX)
      return FoodValidationResult(
        isFood: true,
        detectedLabels: ['Error during validation'],
        confidence: 0.0,
      );
    }
  }

  /// Get localized error message
  String _getErrorMessage(String locale, String errorType) {
    switch (errorType) {
      case 'screen_detected':
        switch (locale) {
          case 'fr':
            return "Cette photo semble être une capture d'écran ou un appareil. Veuillez prendre une photo d'un vrai repas.";
          case 'ar':
            return 'تبدو هذه الصورة كلقطة شاشة أو جهاز. يرجى التقاط صورة لوجبة حقيقية.';
          default:
            return "This photo appears to be a screenshot or device. Please capture a real meal photo.";
        }
      case 'not_food':
      default:
        switch (locale) {
          case 'fr':
            return "Cette photo ne semble pas être de la nourriture. Veuillez capturer une photo claire d'un repas.";
          case 'ar':
            return 'لا تبدو هذه الصورة كطعام. يرجى التقاط صورة واضحة للوجبة.';
          default:
            return "This photo doesn't look like food. Please capture a clear meal photo.";
        }
    }
  }

  /// Dispose of resources
  void dispose() {
    if (_isInitialized) {
      _imageLabeler.close();
      _isInitialized = false;
    }
  }
}
