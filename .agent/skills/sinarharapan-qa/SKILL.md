---
name: sinarharapan-qa
description: Autonomous Quality Assurance, Testing, and Motion/UI Verification Skill for Sinar Harapan PMS (Flutter/Dart). Provides evidence-based testing, regression detection, static analysis, and chat-only reporting.
---

# Sinar Harapan PMS — Autonomous QA Skill

This skill defines the standardized, reproducible Quality Assurance workflow for Sinar Harapan Property Management System (PMS).

## Core Principles
1. **No Execution, No Pass**: Never report a test or validation as passing without running the actual command and capturing the exact output.
2. **No Evidence, No Claim**: Every claim regarding status, performance, animation, or stability must reference terminal output, log files, or code line references.
3. **Strict Separation of Verified vs Unverified**: Clearly distinguish between PASS, FAIL, BLOCKED, NOT VERIFIED, and NOT APPLICABLE.
4. **Zero Production Mutation**: QA engineers test, audit, and report — never modify production application code during audit phases.
5. **No Repository Media Artifacts**: Never create, store, or track screenshot, image, or video files in the repository. Tests must not write images to git-tracked folders.
6. **No Screen Recording by Agent**: The agent never records the screen or extracts video frames. Visual recording is performed by the user. If visual proof is not directly verifiable in headless code, mark as NOT VERIFIED.
7. **Zero Credential Exposure**: Never write, hardcode, or store real or plaintext credentials anywhere in the repository.
8. **Data Protection**: Never delete user data or operational records without explicit user approval.
9. **Chat-Only Concise Reporting**: QA reporting is presented directly in chat in a concise format (no new .md files or documents in `docs/`).

## Standard QA Workflow

### 1. Repository & Git Integrity Audit
- Verify Git branch, HEAD commit hash, and working tree clean status:
  - `git status --short`
  - `git branch --show-current`
  - `git log -n 5 --oneline`
- Inspect target commit diff and whitespace integrity:
  - `git show --stat <commit>`
  - `git show --check <commit>`
- Ensure no accidental out-of-scope changes, debug leftovers, or tracked image artifacts.

### 2. Static Analysis & Code Quality
- Check toolchains:
  - `flutter --version`
- Run static analysis:
  - `flutter analyze`
- Verify lint rules (`analysis_options.yaml`), unused imports, deprecation warnings, and type safety.

### 3. Automated Test Execution
- Run project test suites:
  - `flutter test`
- Track exit codes and total test counts (`+PASS`, `-FAIL`).
- Tests must execute in memory or headless mode without writing screenshot/image files to the repository.

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
- **Visual Verification Gate**:
  - Verify interaction logic via widget tests (`tester.pump`, `tester.pumpAndSettle`).
  - If visual confirmation requires physical device viewing or screen capture, mark as `NOT VERIFIED (Menunggu Rekaman Pengguna)`.

### 5. Regression Scope Verification
- Verify that non-target modules (Authentication, Manager Dashboard, Financial Reports, Audit Log, OCR, etc.) remain intact.
- Check repository write boundaries and API contracts.

### 6. Evidence-Based Reporting (Chat Only)
- Present concise QA reports directly in chat (maximum 15 lines per scope).
- Do NOT generate or update `.md` report files in `docs/` or repo root.
- Structure: Environment, Test Suite breakdown, Defect triage (Critical/High/Medium/Low), Unverified items, and Final Quality Gate status.