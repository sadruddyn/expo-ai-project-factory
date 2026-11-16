# Expo Project Factory — personal defaults

The factory skill reads this file at the start of every project, so you only
state these choices once. You do not have to edit it by hand: a line left as
`not decided` is proposed by the agent, and after you approve a plan the agent
offers to save the approved choices here. You can also tell the agent "from now
on use X" and it updates the matching line. Every line is yours to change,
including the engineering preferences below.

A project brief always wins over this file: if a brief says "web only" or
"use Supabase", that project uses what the brief says.

## Stack

- Target platforms: iOS + Android
- Language: TypeScript (strict)
- Navigation: Expo Router
- State management: not decided
- Data fetching: not decided
- Styling: not decided
- Backend / API: not decided
- Database: not decided
- Authentication: not decided
- Local storage: not decided
- Testing: not decided
- Package manager: not decided

## Engineering preferences

- Prefer native folders/prebuild when native configuration is required; do not hide important native changes.
- Avoid unnecessary libraries, excessive abstractions, and over-engineered folder structures.
- Keep folders only when they meaningfully group multiple files.
- No Flipper.
- Do not use `sudo` for routine Node/Expo project commands.
- Prefer practical, maintainable implementations over enterprise-style boilerplate.

## Constraints

- Paid services and SDKs: ask before adding any
- Offline support: not decided
- Accessibility and localisation: not decided

## Anything else the agent should always know

- (add your own notes here)
