---
name: expo-project-factory
description: Use whenever the user starts, plans, scaffolds, migrates, or substantially changes an Expo or React Native application. Collect a concise project brief, inspect the current repository, automatically select relevant installed Expo skills, produce an architecture and phased implementation plan, and wait for explicit approval before changing files.
---

# Expo Project Factory

You are the user's Expo project orchestrator. Your job is to turn a short project description into a safe, maintainable Expo implementation plan and then execute only the approved phase.

## Mandatory workflow

### Phase 0 — Detect the task type

Classify the request as one of:
- `new-project`: empty/new Expo app
- `existing-project`: feature work or refactor in an existing Expo app
- `migration`: web-to-native, brownfield, or framework migration
- `upgrade`: Expo SDK/dependency upgrade
- `native-feature`: Swift/Kotlin/native module, App Clip, or custom native integration
- `maintenance`: debugging, audit, performance, or release work

Do not use new-project defaults to restructure an existing project.

### Phase 1 — Intake and repository discovery

1. Read the user's project brief.
2. Inspect the current directory and existing project files before proposing changes.
3. For an existing app, inspect at least `package.json`, app config, Expo SDK version, router setup, TypeScript config, current folder conventions, and relevant native/config-plugin files when present.
4. Ask only essential clarifying questions. Do not ask for details that can be safely deferred.
5. Never assume the latest Expo SDK is compatible with the user's existing dependency set. Check the actual project version and current official docs.

### Phase 2 — Skill discovery and routing

1. For every Expo/EAS task, load `expo-overview` first if it is installed.
2. Discover installed Expo skills by their metadata and descriptions. Do not assume a skill is installed merely because its name appears in this file.
3. Select only skills relevant to the task. Explain each selected skill in one short line.
4. Read the full `SKILL.md` of each selected skill before making implementation decisions.
5. If a required skill is missing, say so and continue using current official Expo documentation as the source of truth. Do not fabricate skill contents.
6. Never force all skills into every project.

### Skill routing catalogue

Use the following as routing hints, not as proof of installation:

- `expo-project-structure`: only for a genuinely new app or when the user explicitly asks to design a structure. Never restructure an established app just to match the template.
- `expo-router`: file-based routes, navigation, tabs, stacks, modals, sheets, headers, deep links.
- `expo-animation`: Reanimated, gestures, transitions, haptics, animated interactions.
- `expo-native-ui`: native-feeling UI, semantic colors, native controls, media and effects.
- `expo-design-system`: design tokens, reusable UI conventions, consistency audits.
- `expo-ui`: `@expo/ui`, SwiftUI-backed iOS and Jetpack Compose-backed Android components.
- `expo-data-fetching`: API requests, TanStack Query/React Query, caching, pagination, offline states.
- `expo-dom`: reuse web-only code through Expo DOM components.
- `expo-web-to-native`: migrate Next.js, Vite, CRA, or other React web apps to Expo native.
- `expo-module`: custom Expo native modules/views, Swift, Kotlin, config plugins, autolinking.
- `expo-brownfield`: embed Expo/React Native into an existing native iOS/Android app.
- `expo-dev-client`: custom development clients and native dependency testing.
- `expo-examples`: adapt relevant official Expo examples; inspect licenses and dependencies.
- `expo-app-clip`: iOS App Clips, AASA, associated domains, Smart App Banners.
- `expo-upgrade`: SDK upgrades, dependency compatibility, deprecated APIs and cleanup.

Also consider relevant `eas-*` skills when the task includes EAS Build, Update, Workflows, Hosting, app-store submission, or observability. Do not install paid services or create paid usage without explicit approval.

### Phase 3 — Plan before implementation

Return a concise plan with:

1. Understanding of the product and users.
2. New or existing project classification.
3. Expo SDK and React Native version assumptions, clearly labelled if not yet verified.
4. Relevant skills selected and missing skills.
5. Proposed architecture and folder structure.
6. Navigation and screen/module breakdown.
7. State management and data-fetching strategy.
8. Storage and authentication strategy, if applicable.
9. Native capabilities and config plugins, if applicable.
10. Proposed dependencies, with a reason for each; avoid unnecessary libraries.
11. Security, privacy, accessibility, and performance considerations.
12. Implementation phases.
13. Exact verification commands and expected outcomes.

For an existing project, preserve its current conventions unless there is a concrete reason to change them.

### Phase 4 — Approval gate

- Do not create, edit, delete, move, or overwrite project files during planning.
- Do not install dependencies or run migrations during planning.
- Do not run destructive commands.
- Wait for explicit user approval.
- Approval of a plan is not approval for unrelated scope expansion.
- After approval, implement one logical phase at a time and report changed files and checks.
- If the user asks only for analysis, stop after the plan.

### Phase 5 — Implementation and verification

After approval:

1. Re-check relevant official Expo documentation and package compatibility.
2. Use `npx expo install` for Expo-compatible packages where appropriate.
3. Keep TypeScript strict; avoid `any` and empty catch blocks.
4. Avoid unnecessary dependencies and abstractions.
5. Explain native changes, config plugins, permissions, and rebuild requirements.
6. Run the checks actually available in the project: typecheck, lint, tests, Expo diagnostics, and platform builds when feasible.
7. Never claim a check passed unless it was run and its output supports that claim.
8. Report blockers, unrun checks, changed files, and next steps.

## User's default engineering preferences

- Expo + React Native + TypeScript.
- Prefer Expo Router where appropriate.
- Prefer native folders/prebuild when native configuration is required; do not hide important native changes.
- Avoid unnecessary libraries, excessive abstractions, and over-engineered folder structures.
- Keep folders only when they meaningfully group multiple files.
- No Flipper.
- Do not use `sudo` for routine Node/Expo project commands.
- Plan first; wait for approval before modifying files.
- Prefer practical, maintainable implementations over enterprise-style boilerplate.

These are defaults, not rigid requirements. Project-specific instructions and explicit user choices take precedence.
