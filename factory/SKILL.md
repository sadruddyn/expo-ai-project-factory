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

1. Read the user's project brief. A project name and a few sentences are a complete brief; `PROJECT_BRIEF.md` holds it when the intake script was used.
2. Read the personal defaults file at `~/.config/expo-project-factory/defaults.md` if it exists. If it is missing or unreadable, say so in one line and use the built-in defaults at the end of this skill. The user is not expected to have edited this file; see "Remembering the user's stack".
3. Inspect the current directory and existing project files before proposing changes.
4. For an existing app, inspect at least `package.json`, app config, Expo SDK version, router setup, TypeScript config, current folder conventions, and relevant native/config-plugin files when present.
5. Never assume the latest Expo SDK is compatible with the user's existing dependency set. Check the actual project version and current official docs.
6. Read the project's own agent instruction files (`AGENTS.md`, `CLAUDE.md`) when present, and follow them. If one points at version-pinned Expo documentation, for example `https://docs.expo.dev/versions/v57.0.0/`, read the pages relevant to this task for that version before writing the plan, and base every version-specific statement on them, not on memory. Say in the plan which pages you read.

### Filling the gaps in a short brief

The user should not have to restate their stack for every project. Resolve each decision the brief leaves open in this order, and stop at the first source that answers it:

1. The brief and the user's messages in this session.
2. The existing project's code and its own instruction files.
3. The personal defaults file.
4. What the product described in the brief needs (for example, "store-distance alerts" implies location and notifications).
5. The built-in defaults at the end of this skill.

Treat a defaults line that says `not decided` as open: propose the simplest option that fits the product and list it as an assumption with the source `proposed`.

Do not block the plan on questions. Produce the full plan from the best available answers, and ask at most three questions alongside it, only for choices that would be expensive to reverse once the first implementation phase is done (for example, the backend, or whether web is a target). Never ask for something the brief or the defaults file already states.

### Design direction

Users rarely describe a design, and should not have to. Work from what they give:

- **References given** (a Figma link, screenshots, images in the project folder, or "like <some app>"): treat them as the source of truth for layout, colour and type. Read a Figma link through the Figma tools when they are available; if you cannot open it, say so and ask for screenshots instead of guessing. A named app is a reference for layout patterns and tone only: never copy its name, logo, artwork or exact screens.
- **A feel described in words** ("calm and friendly", "bold and playful"): that is direction. Build the proposal on it and say that you did.
- **Nothing given**: do not ask. Propose a direction that fits the product and the platform and put it in the plan: the overall feel in a phrase, the accent colour and how colour is used, light and dark mode, typography, navigation style, and the two or three screens that define the look.

List every design choice the user did not state in the Assumptions. Tell the user once, in the plan, that they can change the direction in a sentence or send a Figma link or screenshots at any time.

The built-in design default (native look, system fonts, one accent colour) is the starting point when the product gives no cue; go beyond it where the product clearly calls for something else, and list that as `proposed`.

For a new app, plan a **design checkpoint**: Phase 1 scaffolds the app and builds only the two or three defining screens, with the real theme and realistic sample data, so the user's first approval produces something they can look at. Show them (screenshots when you can run the app, otherwise the exact command to run it) and wait for the user to confirm or correct the look before building the remaining screens. Skip the checkpoint when the user supplied a complete design.

### Remembering the user's stack

The defaults file fills itself in from what the user approves, so they never have to edit it by hand.

**After a plan is approved.** If the approved plan settled any reusable stack decision that the defaults file does not already record (the file is missing, the line says `not decided`, or the user corrected your proposal), offer once, in the same reply that starts the approved phase:

> Save these as your defaults for future projects?
> - Backend / API: …
> - Database: …

List exactly the lines you would write, one per line, so each can be read and struck out. Write the file only after the user says yes, and write only the lines they did not strike. Do not hold up the approved phase while waiting for the answer.

Leave a decision out of the offer while a question you asked about it is still unanswered. A bare "approved" does not answer an open question; offer that decision later, once the user has settled it.

**When the user states a standing preference.** If the user says something like "from now on use Supabase" or "always use NativeWind", show the line you will change and update it once they confirm. A standing preference applies to future projects; ask before changing the project already in progress to match it.

Rules for writing the file:

- Reusable stack decisions only: platforms, state management, data fetching, styling, design direction, backend, database, authentication, local storage, testing, package manager, and standing constraints. Never save product-specific choices such as a currency, a screen list, or one project's feature scope.
- Change only the lines the user agreed to, keeping each line's existing `- <Decision>:` label. If a decision has no line yet, add one under `## Stack`. Leave every other line, including the user's own notes, exactly as it is.
- If the file does not exist, create it with a `## Stack` heading and one `- <Decision>: <value>` line per saved decision.
- If the user declines, do not ask again in this session. If they say never to ask, add `- Do not offer to save defaults` under "Anything else the agent should always know" and respect that line in future sessions.
- For design, save only standing preferences ("always support dark mode", "keep the native look"). One app's colours, fonts and screens belong to that app and are never offered.
- A one-project override ("this app uses Firebase") is not a standing preference. Do not offer to save it over an existing default.

This is the only file outside the project that this skill may write, and only with the user's explicit yes.

### Phase 2 — Skill discovery and routing

1. For every Expo/EAS task, load `expo-overview` first if it is installed. Skills from the official Expo plugin may appear under a namespace, such as `expo:expo-overview`; treat those as the same skills.
2. Discover installed Expo skills by their metadata and descriptions. Do not assume a skill is installed merely because its name appears in this file.
3. Select only skills relevant to the task. Explain each selected skill in one short line.
4. Read the full `SKILL.md` of each selected skill before making implementation decisions.
5. If a required skill is missing, say so and continue using current official Expo documentation as the source of truth. Do not fabricate skill contents.
6. Never force all skills into every project.
7. If no Expo skill at all is installed, the official Expo plugin is missing. Tell the user once, with the install command for their agent (`claude plugin install expo@claude-plugins-official` for Claude Code, `codex plugin add expo@openai-curated` for Codex), and continue with the official documentation.
8. If you cannot open the documentation (no web access, or the request fails), or it does not answer the point, do not fall back on memory silently. Mark each affected statement in the plan as `unverified` and say what the user should check.

### Current, supported dependencies

Your knowledge of Expo and React Native libraries may be out of date. Read the documentation you need, not all of it: for each capability the plan uses, and each candidate you rule out, the page for that package in the project's SDK version. For a new app that is the SDK it will be scaffolded with, which `npm view expo dist-tags` shows.

Before proposing any dependency:

1. Prefer a package from the Expo SDK when one covers the need.
2. Confirm in the versioned documentation that the package exists in that SDK and is not deprecated or removed. If it is, use the replacement the documentation names.
3. For a third-party package, check the registry (`npm view <package> deprecated version time`) and the package's own documentation. Do not propose a deprecated package. Point out a package whose latest version was published more than roughly two years ago, and one whose documentation does not state New Architecture support, and look for a maintained alternative first.
4. Confirm it works in an Expo project, and whether it needs a development build.

In the plan's dependency section, mark each dependency, including required peer dependencies, `checked` (say where: versioned Expo page, registry, the package's documentation) or `unverified`. Use `unverified` for anything the sources did not answer, such as compatibility with the exact React Native version, and say when it will be settled, usually the first build. Never present a dependency chosen from memory alone as checked. List the candidates you rejected and why.

In an existing project, report deprecated packages you find, with their replacements. Do not replace them unless the user asks; that is its own phase.

### When Expo does not cover it

Some features have no Expo SDK package. For each such feature separately, work down this list and stop at the first that fits, and say in the native capabilities section which step each feature reached:

1. An Expo SDK package.
2. A maintained community library that works with development builds, ideally with a config plugin.
3. Custom native code inside the Expo app: an Expo module written in Swift and Kotlin (load `expo-module`), or a config plugin when only native project settings need changing.

When you reach step 3, give the user the idea in the plan, not the code:

- what the native piece does, and the few functions or views it exposes to JavaScript;
- which platform APIs it uses, for example a named Apple framework, and whether the other platform has an equivalent, a different approach, or nothing;
- what it costs: a development build is required, Expo Go no longer runs the app, native changes need a rebuild, Xcode or Android Studio is needed, and the module has to be maintained across SDK upgrades.

At any step, when a feature makes a development build necessary, say so plainly: Expo Go will no longer run the app, and native changes need a rebuild. Give each such feature its own phase, after the screens that use it exist with a placeholder.

Also say when a feature cannot behave the way the brief imagines, even though a package exists for it (for example, something that cannot update while the app is closed), and say what the other platform gets.

Never drop Expo or restructure the project to get one native feature.

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
7. Design direction: the feel, colour, light and dark mode, typography, the defining screens, and which reference (if any) it is based on.
8. State management and data-fetching strategy.
9. Storage and authentication strategy, if applicable.
10. Native capabilities and config plugins, if applicable.
11. Proposed dependencies, with a reason for each and whether it was checked; avoid unnecessary libraries.
12. Security, privacy, accessibility, and performance considerations.
13. Implementation phases.
14. Exact verification commands and expected outcomes.
15. Assumptions: every decision the brief did not state, each with its value and its source (`defaults file`, `inferred from brief`, `built-in default`, or `proposed`), so the user can correct any of them in one reply.

If the brief or the defaults file names a backend, find out whether it already exists. When it does not, include it in the architecture, dependency and phase sections as its own folder beside the app, and ask the user to confirm that this project should build it.

For a new project, the workspace may already contain `PROJECT_BRIEF.md` and `FACTORY_START_HERE.md` from the intake script. Keep both files, and say in the plan how the app will be scaffolded next to them.

For an existing project, preserve its current conventions unless there is a concrete reason to change them.

### Phase 4 — Approval gate

- Do not create, edit, delete, move, or overwrite project files during planning. The same applies to the personal defaults file.
- Do not install dependencies or run migrations during planning.
- Do not run destructive commands.
- Wait for explicit user approval.
- Approval of a plan is not approval for unrelated scope expansion.
- After approval, implement one logical phase at a time and report changed files and checks.
- If the user asks only for analysis, stop after the plan.

### Phase 5 — Implementation and verification

After approval:

1. Re-check relevant official Expo documentation and package compatibility. Scaffolding a new Expo app can create an `AGENTS.md` that names the exact SDK documentation to use; read it straight after scaffolding and follow it in every later phase.
2. Use `expo install` for Expo-compatible packages where appropriate, run through the package manager the project or the defaults file specifies (`npx expo install` when none is specified).
3. Keep TypeScript strict; avoid `any` and empty catch blocks.
4. Avoid unnecessary dependencies and abstractions.
5. Explain native changes, config plugins, permissions, and rebuild requirements.
6. Run the checks actually available in the project: typecheck, lint, tests, Expo diagnostics, and platform builds when feasible.
7. Never claim a check passed unless it was run and its output supports that claim.
8. Report blockers, unrun checks, changed files, and next steps.

## Built-in defaults

Use these only for decisions that the brief, the project, and the personal defaults file all leave open.

- Expo + React Native + TypeScript.
- Target iOS and Android.
- Design: the native look of each platform, system fonts, semantic colours, light and dark mode, and one accent colour.
- Prefer Expo Router where appropriate.
- Prefer native folders/prebuild when native configuration is required; do not hide important native changes.
- Avoid unnecessary libraries, excessive abstractions, and over-engineered folder structures.
- Keep folders only when they meaningfully group multiple files.
- No Flipper.
- Do not use `sudo` for routine Node/Expo project commands.
- Plan first; wait for approval before modifying files.
- Prefer practical, maintainable implementations over enterprise-style boilerplate.

These are defaults, not rigid requirements. The personal defaults file, project-specific instructions, and explicit user choices take precedence, in the order given under "Filling the gaps in a short brief".
