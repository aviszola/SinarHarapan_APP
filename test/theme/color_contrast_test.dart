// ignore_for_file: avoid_print
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinarharapan_app/app/theme.dart';

/// WCAG 2.1 Color Contrast Contract Test
/// Strictly enforces WCAG AA:
/// - Normal text (<18pt or <14pt bold): Ratio >= 4.5:1
/// - Large text (>=18pt or >=14pt bold): Ratio >= 3.0:1
/// - Graphical objects and UI components: Ratio >= 3.0:1

double getLuminance(Color color) {
  // Use modern Flutter color channel accessors (color.r, color.g, color.b are 0.0-1.0)
  final r = color.r;
  final g = color.g;
  final b = color.b;

  final rLinear = r <= 0.04045 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4);
  final gLinear = g <= 0.04045 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4);
  final bLinear = b <= 0.04045 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4);

  return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;
}

double getContrastRatio(Color foreground, Color background) {
  final l1 = getLuminance(foreground);
  final l2 = getLuminance(background);

  final lighter = max(l1, l2);
  final darker = min(l1, l2);

  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('1. Status Badges (§6.3) — Normal text >= 4.5:1', () {
    test('Available badge: availableText on availableBg', () {
      final ratio =
          getContrastRatio(AppColors.availableText, AppColors.availableBg);
      print('Available badge: $ratio:1');
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('Occupied badge: occupiedText on occupiedBg', () {
      final ratio =
          getContrastRatio(AppColors.occupiedText, AppColors.occupiedBg);
      print('Occupied badge: $ratio:1');
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('Dirty badge: dirtyText on dirtyBg', () {
      final ratio = getContrastRatio(AppColors.dirtyText, AppColors.dirtyBg);
      print('Dirty badge: $ratio:1');
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('Maintenance badge: maintenanceText on maintenanceBg', () {
      final ratio = getContrastRatio(
          AppColors.maintenanceText, AppColors.maintenanceBg);
      print('Maintenance badge: $ratio:1');
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });

  group('2. Buttons & Interactivity — >= 4.5:1', () {
    test('Primary button: navy900 text on orange600 bg', () {
      final ratio = getContrastRatio(AppColors.navy900, AppColors.orange600);
      print('Primary button (navy900 on orange600): $ratio:1');
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('Secondary button: white text on navy700 bg', () {
      final ratio = getContrastRatio(Colors.white, AppColors.navy700);
      print('Secondary button (white on navy700): $ratio:1');
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('Outline button: navy700 text on white bg', () {
      final ratio = getContrastRatio(AppColors.navy700, AppColors.surface);
      print('Outline button (navy700 on white): $ratio:1');
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });

  group('3. Typography on Backgrounds — >= 4.5:1', () {
    test('Body text: textPrimary on surface', () {
      final ratio =
          getContrastRatio(AppColors.textPrimary, AppColors.surface);
      print('TextPrimary on surface: $ratio:1');
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('Secondary text: textSecondary on surface', () {
      final ratio =
          getContrastRatio(AppColors.textSecondary, AppColors.surface);
      print('TextSecondary on surface: $ratio:1');
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('Header text: white text on navy900 bg', () {
      final ratio = getContrastRatio(Colors.white, AppColors.navy900);
      print('White text on navy900: $ratio:1');
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('Orange text on white: orange800 on surface', () {
      final ratio = getContrastRatio(AppColors.orange800, AppColors.surface);
      print('Orange800 on surface: $ratio:1');
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('Orange text on orange100: orange800 on orange100', () {
      final ratio =
          getContrastRatio(AppColors.orange800, AppColors.orange100);
      print('Orange800 on orange100: $ratio:1');
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });

  group('4. Status Dots & UI Elements (on white) — >= 3.0:1', () {
    test('Status Available dot: statusAvailable on white', () {
      final ratio = getContrastRatio(AppColors.statusAvailable, Colors.white);
      print('StatusAvailable dot: $ratio:1');
      expect(ratio, greaterThanOrEqualTo(3.0));
    });

    test('Status Occupied dot: statusOccupied on white', () {
      final ratio = getContrastRatio(AppColors.statusOccupied, Colors.white);
      print('StatusOccupied dot: $ratio:1');
      expect(ratio, greaterThanOrEqualTo(3.0));
    });

    test('Status Dirty dot: statusDirty on white', () {
      final ratio = getContrastRatio(AppColors.statusDirty, Colors.white);
      print('StatusDirty dot: $ratio:1');
      expect(ratio, greaterThanOrEqualTo(3.0));
    });
  });

  group('5. Brand & Status Tokens Immutability (Exact Values)', () {
    test('Brand Navy900 is locked at #001B4E', () {
      expect(AppColors.navy900.toARGB32(), equals(0xFF001B4E));
    });

    test('Brand Navy700 is locked at #0A2A6E', () {
      expect(AppColors.navy700.toARGB32(), equals(0xFF0A2A6E));
    });

    test('Brand Orange600 is locked at #FF6600', () {
      expect(AppColors.orange600.toARGB32(), equals(0xFFFF6600));
    });

    test('AvailableText is Green-800 (#166534)', () {
      expect(AppColors.availableText.toARGB32(), equals(0xFF166534));
    });

    test('OccupiedText is Red-700 (#B91C1C)', () {
      expect(AppColors.occupiedText.toARGB32(), equals(0xFFB91C1C));
    });

    test('DirtyText is Amber-800 (#92400E)', () {
      expect(AppColors.dirtyText.toARGB32(), equals(0xFF92400E));
    });

    test('MaintenanceText is Gray-600 (#4B5563)', () {
      expect(AppColors.maintenanceText.toARGB32(), equals(0xFF4B5563));
    });

    test('Orange800 is #9A3412', () {
      expect(AppColors.orange800.toARGB32(), equals(0xFF9A3412));
    });
  });
}
