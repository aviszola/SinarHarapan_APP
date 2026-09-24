def srgb_to_lin(val):
    c = val / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def relative_luminance(hex_str):
    hex_str = hex_str.lstrip('#')
    r = int(hex_str[0:2], 16)
    g = int(hex_str[2:4], 16)
    b = int(hex_str[4:6], 16)
    return 0.2126 * srgb_to_lin(r) + 0.7152 * srgb_to_lin(g) + 0.0722 * srgb_to_lin(b)

def contrast_ratio(hex1, hex2):
    l1 = relative_luminance(hex1)
    l2 = relative_luminance(hex2)
    lighter = max(l1, l2)
    darker = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)

colors = {
    "White": "#FFFFFF",
    "Navy 900": "#001B4E",
    "Status Available (Spec §6.3)": "#16A34A",
    "Status Dirty (Spec §6.3)": "#CA8A04",
    "Status Available (Spec §2.3)": "#22C55E",
    "Status Dirty (Spec §2.3)": "#EAB308",
    "Primary Orange Spec": "#FF6600",
    "Darker Orange Alternative 1": "#EA580C",
    "Darker Orange Alternative 2 (AAA/AA)": "#C2410C",
}

print("=== RELATIVE LUMINANCE VALUES ===")
for name, h in colors.items():
    print(f"{name:<35} ({h}): L = {relative_luminance(h):.4f}")

print("\n=== CONTRAST RATIO CALCULATIONS ===")
pairs = [
    ("Available (#16A34A) di atas White (#FFFFFF)", "#16A34A", "#FFFFFF"),
    ("Dirty (#CA8A04) di atas White (#FFFFFF)", "#CA8A04", "#FFFFFF"),
    ("Available (§2.3 #22C55E) di atas White (#FFFFFF)", "#22C55E", "#FFFFFF"),
    ("Dirty (§2.3 #EAB308) di atas White (#FFFFFF)", "#EAB308", "#FFFFFF"),
    ("White (#FFFFFF) di atas Orange (#FF6600)", "#FFFFFF", "#FF6600"),
    ("White (#FFFFFF) di atas Orange (#EA580C)", "#FFFFFF", "#EA580C"),
    ("Navy 900 (#001B4E) di atas Orange (#FF6600)", "#001B4E", "#FF6600"),
    ("White (#FFFFFF) di atas Dark Orange (#C2410C)", "#FFFFFF", "#C2410C"),
]

for desc, c1, c2 in pairs:
    cr = contrast_ratio(c1, c2)
    pass_normal = "PASS" if cr >= 4.5 else "FAIL"
    pass_large = "PASS" if cr >= 3.0 else "FAIL"
    print(f"{desc}")
    print(f"  CR = {cr:.2f}:1 | Teks Normal (<18pt): {pass_normal} | Teks Besar (>=18pt / >=14pt bold): {pass_large}\n")
