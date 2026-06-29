# Documentation Maintenance Guide

> **Last updated:** 2026-06-28

This project treats documentation as a **living artifact**. Docs must stay in sync with code. A Cursor rule (`.cursor/rules/documentation-sync.mdc`) enforces this automatically when you use AI assistance.

---

## Documentation Map

| File | Update when… |
|------|--------------|
| [README.md](../README.md) | Project overview, stack, or stage status changes |
| [docs/HLD.md](HLD.md) | Architecture, features, workflows, stakeholders, or security model change |
| [docs/LLD.md](LLD.md) | APIs, database schema, state machine, or algorithms change |
| [docs/STAGES.md](STAGES.md) | Stage status, scope, or dependencies change |
| [docs/stages/stage-*.md](stages/) | Tasks completed, scope added/removed, acceptance criteria met (see stage-1-community-platform, stage-2-government-integration, stage-3-ai-funding-transparency) |
| [docs/DECISIONS.md](DECISIONS.md) | Locked product/technical defaults (limits, status rules) |
| [docs/DATABASE.md](DATABASE.md) | Full DB schema, audit columns, table relationships, migrations |
| [backend/README.md](../backend/README.md) | Backend setup, env vars, or run instructions change |
| [frontend/README.md](../frontend/README.md) | Flutter setup, build, or run instructions change |

---

## When to Update (Checklist)

Use this checklist **every time you merge or commit meaningful code changes**:

### Any code change

- [ ] Does an API endpoint exist that isn't in LLD? → Add it to [LLD.md](LLD.md)
- [ ] Was an API removed or renamed? → Update [LLD.md](LLD.md)
- [ ] Was a database table or column added/changed? → Update [LLD.md](LLD.md) and relevant stage doc
- [ ] Did the complaint workflow or status enum change? → Update [HLD.md](HLD.md) and [LLD.md](LLD.md)

### Feature completion

- [ ] Check off the item in the relevant [stage doc](stages/)
- [ ] If all acceptance criteria met, update stage status in [STAGES.md](STAGES.md) and [README.md](../README.md)

### Architecture change

- [ ] Update the architecture diagram in [HLD.md](HLD.md)
- [ ] Update module table in [LLD.md](LLD.md)
- [ ] Note the change in LLD **Change Log** (bottom of LLD.md)

### New environment variable or dependency

- [ ] Update [backend/README.md](../backend/README.md) or [frontend/README.md](../frontend/README.md)
- [ ] Update `.env.example` if present

---

## LLD Change Log Format

Add a row at the bottom of [LLD.md](LLD.md) § Change Log:

```
| YYYY-MM-DD | Brief description of change | Author |
```

---

## Stage Status Values

Use these consistently in STAGES.md, README.md, and stage docs:

| Status | Meaning |
|--------|---------|
| Not started | No implementation yet |
| In progress | Active development |
| Complete | All acceptance criteria met |
| Blocked | Waiting on dependency or decision |

---

## AI Assistant Rule

The file `.cursor/rules/documentation-sync.mdc` instructs Cursor AI to:

1. Identify which docs are affected by code changes
2. Propose or apply doc updates alongside code edits
3. Check off completed stage tasks when features are implemented

You do not need to remind the AI — the rule applies automatically in this repository.

---

## Quick Reference — Doc vs Code Locations

| Concern | Doc | Code (planned) |
|---------|-----|----------------|
| Auth APIs | LLD § Authentication | `backend/app/modules/auth/` |
| Feed / Report APIs | LLD § Reports | `backend/app/modules/reports/` |
| NGO accept/reject | LLD § NGO + Stage 1 | `backend/app/modules/ngo/` |
| Issues | LLD § Issues | `backend/app/modules/issues/` |
| Official / Govt | LLD § Official + Stage 2 | `backend/app/modules/officials/` |
| Achievements / badges | LLD § Achievements + Stage 1 | `backend/app/modules/achievements/` |
| Funding / Donations | LLD § Funding + Stage 3 | `backend/app/modules/funding/` |
| DB models | LLD § Database Tables | `backend/app/models/` |
| Flutter screens | Stage docs § Frontend | `frontend/lib/features/` |
| State machine | LLD § State Machines | `backend/app/modules/issues/workflow.py` |

---

## Review Cadence

- **Per PR / commit:** Run the checklist above
- **Per stage completion:** Full review of HLD + LLD against implemented code
- **Before demo / release:** Verify README quick-start works and stage status is accurate
