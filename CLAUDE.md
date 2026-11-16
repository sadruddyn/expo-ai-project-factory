# Expo AI Project Factory — Claude Code guidance

This repository maintains a reusable Expo project-orchestration skill.

- Keep compatibility with both Claude Code and Codex.
- Use the official Expo plugin as the source of Expo-specific skills and current documentation.
- Keep project work plan-first: inspect, select skills, propose architecture and phases, then wait for explicit approval before modifying files.
- Do not overwrite existing user skill paths or global instruction files.
- Test shell scripts with `bash -n` and test installation in a temporary HOME before release.
