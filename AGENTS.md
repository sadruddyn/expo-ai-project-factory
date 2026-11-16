# Expo AI Project Factory — repository guidance

When maintaining this repository:
- Keep the factory skill agent-neutral and compatible with Codex and Claude Code.
- Keep Expo-specific implementation knowledge in the official Expo plugin/skills; do not copy stale skill content into this repository.
- Preserve the plan-first approval gate: no project edits, installs, migrations, or destructive actions before explicit approval.
- Keep scripts safe, idempotent where practical, and explicit about paths they will create or refuse to overwrite.
- Update README.md and verification steps whenever installation behavior changes.
