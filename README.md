# Expo AI Project Factory

A reusable, GitHub-hosted workflow for starting Expo / React Native projects with Codex and Claude Code.

## What this repository does

- Installs one reusable `expo-project-factory` agent skill into Codex and Claude Code user-level skill directories.
- Routes each new project brief to the relevant official Expo skills.
- Requires a discovery and planning phase before implementation.
- Preserves existing project conventions; it does not blindly restructure existing apps.
- Includes verification scripts.

The factory skill is the orchestrator. Official Expo skills remain the source of Expo-specific implementation guidance.

## Quick start

```bash
git clone https://github.com/sadruddyn/expo-ai-project-factory.git
cd expo-ai-project-factory
./scripts/install.sh        # links the skill, creates your defaults file
./scripts/new-project.sh    # asks for a project name and a brief
```

Edit `~/.config/expo-project-factory/defaults.md` once with your usual stack. After that, each new project needs only a name and a brief: the agent takes everything else from your defaults, lists what it assumed, and waits for your approval before writing code.

You also need the official Expo plugin in your agent (section 4). The sections below explain each step.

## 1. Prerequisites

- macOS or Linux
- Git
- Node.js + npm
- Codex CLI and/or Claude Code CLI
- GitHub CLI (`gh`) is optional, only needed to create/push the GitHub repository from Terminal

## 2. Get the repository

```bash
mkdir -p ~/Development
cd ~/Development
git clone https://github.com/sadruddyn/expo-ai-project-factory.git
cd expo-ai-project-factory
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

It also creates your personal defaults file at `~/.config/expo-project-factory/defaults.md` from `templates/defaults.md`. Open it once and fill in your usual stack (platforms, backend, database, authentication, libraries you prefer). The skill reads it for every project, so you do not repeat these choices in each brief. Lines left as `not decided` are proposed by the agent and shown as assumptions in the plan.

Rerunning the installer is safe: it never overwrites an existing skill path or an existing defaults file.

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
- Your personal defaults file is reported if it exists.
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

## 7. Use it for a new project

Run the intake script:

```bash
./scripts/new-project.sh
```

It asks for two things: the project name and a multi-line project description. It then shows a summary and asks for confirmation before creating the workspace. Platforms, backend, database, authentication and the rest are not asked; the agent takes them from the description, then from your defaults file.

The workspace is created at `~/Development/<project-name-as-a-slug>`. To use a different parent directory, pass it as an argument:

```bash
./scripts/new-project.sh ~/Development/ClientApps
```

The script creates `PROJECT_BRIEF.md` and `FACTORY_START_HERE.md`. It does not generate the app or install dependencies. Open the generated folder in Codex or Claude Code and send the prompt in `FACTORY_START_HERE.md`.

If you prefer to skip the script, open a new, empty project directory in Codex or Claude Code and give the brief directly:

```text
Use the expo-project-factory skill.

Project: Grocery shopping app.
Users can create shopping lists, browse stores, add products,
receive store-distance alerts, and use Siri shortcuts.

Prepare the plan and wait for my approval.
```

To override a default for one project, say so in the brief (for example, "Backend: Supabase" or "Web only").

The plan ends with an "Assumptions" list showing every choice the agent made for you and where it came from. Correct anything there before approving.

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
