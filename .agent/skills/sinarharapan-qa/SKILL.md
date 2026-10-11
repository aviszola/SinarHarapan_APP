---
name: sinarharapan-qa
description: Autonomous Quality Assurance, Testing, and Motion/UI Verification Skill for Sinar Harapan PMS (Flutter/Dart). Provides evidence-based testing, regression detection, static analysis, and reporting.
---

# Sinar Harapan PMS — Autonomous QA Skill

This skill defines the standardized, reproducible Quality Assurance workflow for Sinar Harapan Property Management System (PMS).

## Core Principles
1. **No Execution, No Pass**: Never report a test or validation as passing without running the actual command and capturing the exact output.
2. **No Evidence, No Claim**: Every claim regarding status, performance, animation, or stability must reference terminal output, log files, or code line references.
3. **Strict Separation of Verified vs Unverified**: Clearly distinguish between PASS, FAIL, BLOCKED, NOT VERIFIED, and NOT APPLICABLE.
4. **Zero Production Mutation**: QA engineers test, audit, and report — never modify production application code during audit phases.

## Standard QA Workflow

### 1. Repository & Git Integrity Audit
- Verify Git branch, HEAD commit hash, and working tree clean status:
  - `git status --short`
  - `git branch --show-current`
  - `git log -n 5 --oneline`
- Inspect target commit diff and whitespace integrity:
  - `git show --stat <commit>`
  - `git show --check <commit>`
- Ensure no accidental out-of-scope changes or debug leftovers.

### 2. Static Analysis & Code Quality
- Check toolchains:
  - `flutter --version`
- Run static analysis:
  - `flutter analyze`
- Verify lint rules (`analysis_options.yaml`), unused imports, deprecation warnings, and type safety.

### 3. Automated Test Execution
- Run all project test suites:
  - `flutter test`
- Track exit codes and total test counts (`+PASS`, `-FAIL`).
- If headless/screenshot tests are configured, verify artifact generation without mocks clashing.

### 4. Motion, Accessibility & Interaction Audit
- **Status Badge**:
  - Stable size, zero layout shifts, verified duration (<= 200ms).
  - Reduced-motion compliance (`MediaQuery.maybeDisableAnimationsOf(context)` -> `Duration.zero`).
- **Room Card & Interaction**:
  - Proper state cleanup for pointer events (`onTapDown`, `onTapUp`, `onTapCancel`).
  - No gesture conflict between parent card tap and child action buttons (Check-in/Check-out).
  - Hover feedback, mouse cursor consistency, keyboard focus accessibility.
- **Debounce & Asynchronous Tasks**:
  - Debounce timers (`Timer`) must be cancelled on reset, search text clear, and `dispose()`.
  - TextEditingControllers and AnimationControllers must be disposed properly in state lifecycle.
  - Refresh indicators must handle both success and error states without getting stuck in infinite loading.
- **Dialogs & Overlays**:
  - Dialog dismissibility (`barrierDismissible`) must be strictly configured: `false` for critical transactional forms (prevent data loss), `true` for read-only modals.
  - Entrance and exit transitions must respect reduced motion.

### 5. Regression Scope Verification
- Verify that non-target modules (Authentication, Manager Dashboard, Financial Reports, Audit Log, OCR, etc.) remain intact.
- Check repository write boundaries and API contracts.

### 6. Evidence-Based Reporting
- Produce structured report at `docs/qa/QA_REPORT.md`.
- Detail: Target commit, Environment, Test Suite breakdown, Defect triage (Critical/High/Medium/Low), Coverage gaps, and Final recommendation.

---
name: sinarharapan-ui-design
description: UI/UX design system and layout standards for Sinar Harapan PMS (Flutter). Enforces color immutability, responsive layout, typography, spacing, form patterns, accessibility, and desktop/mobile parity for a hotel frontdesk check-in/check-out application.
---

# Sinar Harapan PMS — UI Design Skill

## Core Principles
1. **Color Immutability**: Never change existing brand colors (navy, orange, neutrals). Only reuse existing theme tokens. Opacity variations of existing colors are allowed; new hex values are not.
2. **Frontdesk-First**: Staff work fast, under bright light, often on tablets/desktops. Prioritize legibility, large targets, and clear status feedback.
3. **Consistency over Novelty**: Reuse shared widgets and tokens; no one-off styles.
4. **Evidence over Opinion**: Verify contrast, overflow, and responsiveness by running, not assuming.

## Design Tokens
- Spacing scale: 4, 8, 12, 16, 24, 32, 48.
- Radius: inputs/buttons 10–12, cards 16, chips 8.
- Type scale: Title 24–26 w700, Heading 18–20 w600, Body 14–15, Label 14 w500, Caption 12, Button 15–16 w600.
- Touch target: ≥ 48x48. Input/button height: 52–56.
- Elevation: minimal; subtle shadow only on floating cards.

## Responsive Rules
- Breakpoints: mobile < 600, tablet 600–899, desktop ≥ 900.
- Test widths: 360, 390, 768, 1280, 1920; text scale 1.0 and 1.3.
- Mobile: single column, `SafeArea`, `SingleChildScrollView`, keyboard-safe.
- Desktop: split or max-width centered layouts; cap content width (forms ≤ 440, content ≤ 1200).
- No RenderFlex overflow at any tested size.

## Form Patterns
- Label above field, 8px gap; 20px between fields.
- Always: focus border, error border, inline error text, disabled state.
- `TextInputAction` and Enter-to-submit; autofill hints; password toggle with tooltip and Semantics.
- Primary button states: normal, hover, pressed, disabled, loading (no double-submit).
- Error feedback inline (icon + text), not SnackBar only.

## Contrast & Accessibility
- WCAG AA: 4.5:1 body text, 3:1 large text and UI components. Compute, don't guess.
- Visible keyboard focus, logical tab order, `Semantics` labels for icon-only controls.
- Respect reduced motion (`MediaQuery.maybeDisableAnimationsOf`).

## Dev/Debug UI
- Any developer shortcut (e.g., "Mode Pengembangan") must be gated by `!kReleaseMode` and visually de-emphasized.

## Verification Checklist
- [ ] `git diff` shows zero color value changes
- [ ] `flutter analyze` no new warnings
- [ ] `flutter test` passes, new widget tests added
- [ ] Screenshots before/after at mobile and desktop widths
- [ ] No overflow at listed widths and 1.3x text scale
- [ ] Controllers/FocusNodes/AnimationControllers disposed

## Anti-Slop Rules
- Every element must justify its function or brand identity; decoration without purpose is removed.
- Forbidden by default: tinted icon-chips, gradients, glassmorphism, layered shadows, decorative entrance animations, generic marketing copy, emoji.
- Motion is functional only (focus, hover, loading), ≤ 150ms, and respects reduced motion.
- Each screen needs one distinctive, hotel-specific identity cue built from existing theme colors only.
- Prefer real operational information (date/time, connection status, shift context) over promotional text.
- Template test: if swapping the logo makes the screen indistinguishable from a generic template, redesign.
- Report must list removed elements and the reason for each.