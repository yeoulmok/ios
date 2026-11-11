# Yeoulmok iOS

Valley flood-risk alert app (iOS, SwiftUI). Users subscribe to valleys and get push alerts.
Feature IDs (e.g. `APP-HOME-01`) tie together the Notion feature list, GitHub issues, and PRs.

## Read first
- `docs/PROGRESS.md` — current state, decisions, open items, issue order (Korean)
- Notion project page (private workspace): https://app.notion.com/p/408e3eb91c8b80d0b3a6e862e88863ab
  - Feature spec (기능 정의서), API spec (API 명세서), dev guide (개발 협업 가이드), AI guide (AI 협업 가이드)
- Figma screens: https://www.figma.com/design/J48ZeNyBojQxb3eFtimphH/%EC%97%AC%EC%9A%B8%EB%AA%A9-%ED%99%94%EB%A9%B4%EC%84%A4%EA%B3%84
- Server repo: https://github.com/yeoulmok/server

The Notion API spec is the source of truth for models until `docs/api-spec.md` exists (issue #25).

## Working with the user
- Reply in Korean. Code, code comments, and file names stay in English.
- The user is the only iOS developer. Explain the concept first (why), then the code (how). Keep it short and concrete.
- Prefer plain SwiftUI + URLSession. Do not introduce SwiftData or CloudKit unless an issue needs it, and say why.

## Stack (not decided yet — issue #24 decides)
- Bundle ID, minimum iOS version, architecture (MVVM proposed in the Notion guide), SwiftLint: undecided.
- No third-party dependencies without asking first.

## Workflow (from the Notion dev guide)
- One feature ID = one issue = one branch = one PR. Split work that exceeds ~2 days.
- Branch: `type/<issue>-short-desc` (e.g. `feat/4-subscribed-list`). Start from an issue, not from nothing.
- Commit: `type: Korean summary (#issue)`; types: feat, fix, refactor, chore, docs, test, style.
- PR title: `[FEATURE-ID] summary`. Body has `Closes #N`, a screenshot or short video for UI changes, and the "AI usage" section.
- `main` is protected for everyone, including admins: no direct push. PR -> Squash merge only.
- A PR that changes the API or DB needs the other person's approval and the `API 변경` label. Other PRs may be self-merged after 24h without a response.
- Loading / empty / error handling follows Notion feature spec section 3-1. Do not invent per-screen rules.

## Rules for the AI
- Plan first, code second. Work only inside the approved plan and the current issue.
- Never edit or delete tests to make them pass.
- Never decide safety logic alone (state judgment thresholds, push conditions). The human decides; tests pin it down.
- Verify Apple APIs and library versions against official docs. If unsure, say so.
- Never hardcode secrets or server URLs. Use `Config.xcconfig` (gitignored). Never commit `.p8`, tokens, or keys.
- Use Mock data from the API spec until a real endpoint exists.
- One logical change per commit.

## Domain facts that are easy to get wrong
- `level`: `safe` `caution` `danger` `evacuate` `unknown`. `unknown` ("판정 불가") must never look like `safe`.
- A missing value is `null`, never 0 (0 mm means "no rain", `null` means "unknown").
- `stale: true` when the observation is older than 15 min; `level: unknown` when older than 30 min or missing.
- No login. The server issues `device_id`; send it as the `X-Device-Id` header on every request.
- User location stays on the phone. "Nearby" distance is computed on device from `GET /valleys` coordinates.
- Times are Korean time, ISO8601 without offset (e.g. `2026-11-07T22:00`).
- Disclaimer and data source ("자료: 한강홍수통제소, 기상청") are legally required on the relevant screens.

## Lessons learned
- (add a rule here when the same mistake happens twice)
