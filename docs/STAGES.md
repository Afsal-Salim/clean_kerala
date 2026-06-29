# Make Kerala Clean — Development Stages

> **Last updated:** 2026-06-28

The project is split into **three stages**. Each stage is independently shippable. Update this file when stage status or scope changes.

---

## Vision Summary

| Stage | What we build | Who it's for |
|-------|---------------|--------------|
| **1** | Waste feed + NGO accept/reject → issues + **closure badges (10, 100, 1,000…)** | Citizens, NGOs, volunteers |
| **2** | Government module (if proposal approved) | Municipalities, panchayats, state admin |
| **3** | AI + transparent funding & donation dashboard | Funders, donors, public transparency |

---

## Stage Overview

| Stage | Name | Goal | Doc |
|-------|------|------|-----|
| 1 | Community Platform | Social waste feed, NGO matching, issue tracking | [stage-1-community-platform.md](stages/stage-1-community-platform.md) |
| 2 | Government Integration | Add state/local govt if proposal is approved | [stage-2-government-integration.md](stages/stage-2-government-integration.md) |
| 3 | AI & Funding Transparency | AI features + live funding/donation dashboard | [stage-3-ai-funding-transparency.md](stages/stage-3-ai-funding-transparency.md) |

---

## Dependency Graph

```
Stage 1 (Community Platform)
    │
    ▼
Stage 2 (Government Integration)   ← conditional on govt approval
    │
    ▼
Stage 3 (AI & Funding Transparency)  ← conditional on funding
```

Stage 1 is the **standalone MVP**. Stage 2 extends it when government partners onboard. Stage 3 adds intelligence and financial transparency when grants or donations arrive.

---

## Status Tracker

| Stage | Status | Started | Completed |
|-------|--------|---------|-----------|
| 1 | In progress | — | — |
| 2 | Not started | — | — |
| 3 | Not started | — | — |

---

## What Each Stage Delivers

### Stage 1 — Community Platform

A social-style app where citizens post waste reports with photos and location (ward, municipality, district). Nearby NGOs receive notifications and can **accept** or **reject**. When an NGO accepts, the report becomes an **open issue**. Accounts earn **profile badges** at closure milestones — 10, 100, 1,000, and beyond. Public feed, comments, upvotes, and issue lifecycle (open → in progress → resolved → closed).

### Stage 2 — Government Integration

If the state or local government approves the proposal, add official accounts, verification workflows, escalation from NGO issues to government action, and performance dashboards for authorities. Existing community flow continues; government layer sits alongside it.

### Stage 3 — AI & Funding Transparency

When funding comes from government or other organisations: AI classification, duplicate detection, hotspot analysis. A **public transparency dashboard** shows total funding received, amount spent, balance remaining — and **donations reflect immediately** on the dashboard when a person contributes.

---

## Documentation Sync

When completing tasks in any stage:

1. Mark acceptance criteria in the stage doc
2. Update [HLD.md](HLD.md) if architecture or features change
3. Update [LLD.md](LLD.md) if APIs or schema change
4. Update [README.md](../README.md) status table
5. Add entry to LLD change log

See [DOCUMENTATION.md](DOCUMENTATION.md) for the full checklist.
