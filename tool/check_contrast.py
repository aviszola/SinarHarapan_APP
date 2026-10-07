#!/usr/bin/env python3
"""
WCAG 2.1 Color Contrast Calculator
Calculates contrast ratios for all text/background combinations in Sinar Harapan PMS theme.
"""

def hex_to_rgb(hex_color):
    """Convert hex color (without #) to RGB tuple."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def linearize_srgb(c):
    """Linearize sRGB channel value."""
    c = c / 255.0
    if c <= 0.04045:
        return c / 12.92
    else:
        return pow((c + 0.055) / 1.055, 2.4)

def get_luminance(hex_color):
    """Calculate relative luminance using WCAG 2.1 formula."""
    r, g, b = hex_to_rgb(hex_color)
    r_linear = linearize_srgb(r)
    g_linear = linearize_srgb(g)
    b_linear = linearize_srgb(b)

    return 0.2126 * r_linear + 0.7152 * g_linear + 0.0722 * b_linear

def contrast_ratio(fg_hex, bg_hex):
    """Calculate contrast ratio between foreground and background colors."""
    l1 = get_luminance(fg_hex)
    l2 = get_luminance(bg_hex)

    lighter = max(l1, l2)
    darker = min(l1, l2)

    return (lighter + 0.05) / (darker + 0.05)

# Define all color combinations from theme.dart
colors = {
    # Brand colors
    'navy900': '001B4E',
    'navy700': '0A2A6E',
    'orange600': 'FF6600',
    'orange100': 'FFEBDB',
    'orange800': '9A3412',

    # Status colors (solid on white)
    'statusAvailable': '16A34A',
    'statusOccupied': 'EF4444',
    'statusDirty': 'D97706',

    # Badge backgrounds
    'availableBg': 'DCFCE7',
    'occupiedBg': 'FEE2E2',
    'dirtyBg': 'FEF3C7',
    'maintenanceBg': 'F3F4F6',

    # Badge texts
    'availableText': '166534',
    'occupiedText': 'B91C1C',
    'dirtyText': '92400E',
    'maintenanceText': '4B5563',

    # Neutrals
    'white': 'FFFFFF',
    'textPrimary': '1E2430',
    'textSecondary': '4B5563',
}

# Test cases: (fg, bg, min_ratio, description)
test_cases = [
    # Badge text on badge background (normal text: >= 4.5:1)
    ('availableText', 'availableBg', 4.5, 'Available badge'),
    ('occupiedText', 'occupiedBg', 4.5, 'Occupied badge'),
    ('dirtyText', 'dirtyBg', 4.5, 'Dirty badge'),
    ('maintenanceText', 'maintenanceBg', 4.5, 'Maintenance badge'),

    # Button and text on backgrounds (normal text: >= 4.5:1)
    ('navy900', 'orange600', 4.5, 'Primary button text (navy900 on orange600)'),
    ('white', 'navy700', 4.5, 'Secondary button text (white on navy700)'),
    ('navy700', 'white', 4.5, 'Outline button text (navy700 on white)'),
    ('textPrimary', 'white', 4.5, 'Body text (textPrimary on white)'),
    ('textSecondary', 'white', 4.5, 'Secondary text (textSecondary on white)'),
    ('white', 'navy900', 4.5, 'White text on navy900'),
    ('orange800', 'white', 4.5, 'Orange text on white'),
    ('orange800', 'orange100', 4.5, 'Orange text on orange100 badge'),

    # Status dots on white (UI elements: >= 3:1)
    ('statusAvailable', 'white', 3.0, 'Available status dot'),
    ('statusOccupied', 'white', 3.0, 'Occupied status dot'),
    ('statusDirty', 'white', 3.0, 'Dirty status dot'),
]

# Run tests
print("=" * 80)
print("WCAG 2.1 Contrast Ratio Analysis — Sinar Harapan PMS")
print("=" * 80)
print()

failed = []
passed = []

for fg, bg, min_ratio, desc in test_cases:
    fg_hex = colors[fg]
    bg_hex = colors[bg]
    ratio = contrast_ratio(fg_hex, bg_hex)

    status = "✓ PASS" if ratio >= min_ratio else "✗ FAIL"
    passed.append(ratio) if ratio >= min_ratio else failed.append((desc, ratio, min_ratio))

    print(f"{status} | {desc}")
    print(f"       FG: #{fg_hex} ({fg}) | BG: #{bg_hex} ({bg})")
    print(f"       Ratio: {ratio:.2f}:1 (requires ≥ {min_ratio}:1)")
    print()

# Summary
print("=" * 80)
print(f"SUMMARY: {len(passed)} PASSED, {len(failed)} FAILED")
print("=" * 80)

if failed:
    print("\nFAILED COMBINATIONS:")
    for desc, ratio, min_ratio in failed:
        print(f"  - {desc}: {ratio:.2f}:1 (need {min_ratio}:1)")
    exit(1)
else:
    print("\n✓ All contrast ratios meet WCAG AA requirements!")
    exit(0)
