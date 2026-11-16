# Expo AI Project Factory

A reusable, GitHub-hosted workflow for starting Expo / React Native projects with Codex and Claude Code.

## What this repository does

- Installs one reusable `expo-project-factory` agent skill into Codex and Claude Code user-level skill directories.
- Routes each new project brief to the relevant official Expo skills.
- Requires a discovery and planning phase before implementation.
- Preserves existing project conventions; it does not blindly restructure existing apps.
- Includes verification scripts.

The factory skill is the orchestrator. Official Expo skills remain the source of Expo-specific implementation guidance.

## 1. Prerequisites

- macOS or Linux
- Git
- Node.js + npm
- Codex CLI and/or Claude Code CLI
- GitHub CLI (`gh`) is optional, only needed to create/push the GitHub repository from Terminal

## 2. Put this folder in your development directory

Example:

```bash
mkdir -p ~/Development
# Extract this archive into ~/Development/
cd ~/Development/expo-ai-project-factory
```

## 3. Install the factory skill for both agents

```bash
chmod +x scripts/*.sh
./scripts/install.sh
```

The installer creates symlinks:
- `~/.agents/skills/expo-project-factory` for Codex
- `~/.claude/skills/expo-project-factory` for Claude Code

Symlinks keep the installed skill synced with this Git repository when you pull updates.

## 4. Install the official Expo plugin in each agent

Expo's official recommendation for Codex and Claude Code is to install the Expo plugin from each agent's marketplace. It includes Expo skills and configures the Expo MCP server.

Claude Code:

```bash
claude plugin install expo@claude-plugins-official
```

Codex:

```bash
codex plugin add expo@openai-curated
```

If a command is unavailable in your installed CLI version, use the agent's plugin UI:
- Claude Code: `/plugin`
- Codex: `/plugins`

Restart both agent sessions after installing plugins.

## 5. Verify

```bash
./scripts/verify.sh
```

Expected:
- Both factory skill paths exist and resolve to this repository.
- The skill metadata is readable.
- The Expo skill/plugin installation is reported when the relevant CLI is available.

The verification script does not claim that a plugin is installed merely because its CLI exists. Confirm the Expo plugin in the agent's plugin UI as well.

## 6. Create and publish your GitHub repository

Create an empty repository on GitHub named `expo-ai-project-factory`, then:

```bash
git init
git add .
git commit -m "chore: bootstrap Expo AI Project Factory"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/expo-ai-project-factory.git
git push -u origin main
```

Or, if GitHub CLI is installed and authenticated:

```bash
gh repo create expo-ai-project-factory --private --source=. --remote=origin --push
```

## 7. Use it for a new project (interactive)

Run the interactive intake script:

```bash
./scripts/new-project.sh
```

It asks for the project name, a multi-line project description, platforms, project type, backend, database, authentication, native features, design references, constraints, and destination folder. It shows a summary and asks for confirmation before creating the workspace.

You can optionally pass a parent directory:

```bash
./scripts/new-project.sh ~/Development/ClientApps
```

The script creates `PROJECT_BRIEF.md` and `FACTORY_START_HERE.md`. It does not generate the app or install dependencies. Open the generated folder in Codex or Claude Code and ask it to follow `FACTORY_START_HERE.md`.

If you prefer to skip the script, open a new, empty project directory in Codex or Claude Code and give a short brief directly:

```text
Use the expo-project-factory skill.

Project: Grocery shopping app.
Platforms: iOS and Android.
Users can create shopping lists, browse stores, add products,
receive store-distance alerts, and use Siri shortcuts.
Backend: NestJS + PostgreSQL.

First inspect the directory and requirements.
Do not create or modify files yet.
Return:
1. Clarifying questions (only if essential)
2. Relevant Expo skills and why
3. Architecture and folder structure
4. Dependency choices with compatibility checks
5. Implementation phases
6. Risks and verification commands

Wait for my explicit approval before implementation.
```

After reviewing the plan, reply:

```text
Approved. Implement Phase 1 only. Show changed files and verification results.
```

## 8. Updating

Update the factory:

```bash
cd ~/Development/expo-ai-project-factory
git pull
./scripts/verify.sh
```

Update Expo plugins from their respective marketplaces. For skills installed through the skills CLI instead of plugins, use `npx skills@latest update`.

## Important operating rules

- The factory is guidance and orchestration, not a guarantee that every agent will obey every instruction. Keep approval controls enabled in the agent UI.
- Do not let the agent install packages, change native files, run destructive commands, or create credentials without approval.
- For an existing app, audit its current architecture first. Never apply a new-project folder template blindly.
- Expo documentation, Expo CLI, and EAS CLI are the source of truth; skill instructions are supporting guidance.
