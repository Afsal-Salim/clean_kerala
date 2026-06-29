# Stage 2 — Government Integration

> **Status:** Not started  
> **Last updated:** 2026-06-28  
> **Depends on:** Stage 1  
> **Prerequisite:** State or local government **approves the MKC proposal**  
> **Blocks:** Stage 3

---

## Goal

Extend the community platform with a **government layer**. If Kerala state or local bodies approve the proposal, officials can join, verify reports, escalate unresolved issues, and track performance — without replacing the NGO-first flow from Stage 1.

---

## Product Concept

```
Stage 1 flow continues (citizens post → NGOs accept → issues resolved)
        +
Government officials onboard after proposal approval
        ↓
Officials see reports & issues in their ward / municipality
        ↓
Can verify reports, escalate stale issues, assign govt cleaning teams
        ↓
NGO-resolved issues can be audited by officials
        ↓
Government performance dashboard
```

---

## Scope

### Backend — Government Onboarding

- [ ] Proposal / partnership status flag (`govt_approved`, effective date)
- [ ] Official account creation (admin-approved only)
- [ ] Roles: `ward_member`, `municipality_officer`, `panchayat_officer`, `district_officer`, `mla`, `state_admin`
- [ ] Link officials to geography (district / municipality / ward)
- [ ] Approval workflow for new official accounts

### Backend — Official Workflow

- [ ] Officials view reports and issues in their jurisdiction
- [ ] Verify report authenticity (mark verified / flag as fake)
- [ ] Escalate issue — NGO not acting within SLA → notify higher authority
- [ ] Assign government cleaning team to issue
- [ ] Override or co-manage issue with NGO
- [ ] Upload official completion evidence
- [ ] Close issue with official sign-off

### Backend — Escalation & SLA

- [ ] Configurable SLA (e.g. 48h for NGO to accept, 7 days to resolve)
- [ ] Auto-escalate to municipality officer if NGO rejects all or times out
- [ ] Escalation chain: ward → municipality → district → state
- [ ] Escalation logged in status history

### Backend — Government Notifications

- [ ] Notify officials on new reports in jurisdiction
- [ ] Notify on escalation events
- [ ] Notify citizen when government takes over an issue
- [ ] Email + push for officials

### Backend — Government Dashboard

- [ ] Issues by status, ward, category
- [ ] NGO vs government resolution counts
- [ ] Average resolution time by area
- [ ] Pending / overdue issues
- [ ] Official performance metrics (basic)

### Frontend — Official App Views

- [ ] Official login (separate onboarding flow)
- [ ] Jurisdiction dashboard — reports and issues map/list
- [ ] Verify / reject report
- [ ] Escalate issue
- [ ] Assign government team
- [ ] Mark complete with photo
- [ ] SLA overdue alerts

### Frontend — Citizen (Enhanced)

- [ ] See when government has verified or taken over an issue
- [ ] Official badge on government-closed issues

### Integration Prep

- [ ] API design compatible with future Kerala e-governance hooks
- [ ] Export reports for government systems (CSV / JSON)
- [ ] Audit log export for transparency requests

---

## Database Tables (Stage 2 — New)

| Table | Purpose |
|-------|---------|
| `officials` | Government official profiles |
| `official_assignments` | Official ↔ geography mapping |
| `escalations` | Escalation events and chain |
| `govt_assignments` | Government team assigned to issue |
| `sla_rules` | Configurable SLA thresholds |
| `partnership` | Govt approval status and metadata |

---

## API Endpoints (Stage 2)

### Officials

```
GET    /api/v1/officials/dashboard
GET    /api/v1/officials/reports          # Reports in jurisdiction
GET    /api/v1/officials/issues           # Issues in jurisdiction
POST   /api/v1/officials/verify/{report_id}
POST   /api/v1/officials/reject/{report_id}
POST   /api/v1/officials/escalate/{issue_id}
POST   /api/v1/officials/assign/{issue_id}
POST   /api/v1/officials/complete/{issue_id}
```

### Admin — Officials

```
POST   /api/v1/admin/officials
GET    /api/v1/admin/officials
PUT    /api/v1/admin/officials/{id}
POST   /api/v1/admin/partnership/approve   # Mark govt proposal approved
```

### Analytics (Government)

```
GET    /api/v1/analytics/jurisdiction
GET    /api/v1/analytics/officials/{id}
GET    /api/v1/analytics/export
```

---

## Issue State Machine (Stage 2 Extension)

Stage 1 states remain. Additional transitions:

```
issue: open
  ↓ (SLA breach or NGO inactive)
escalated → assigned_to_govt
  ↓
govt: in_progress
  ↓
govt: resolved → closed
```

Official verification on reports:

```
report: posted → official_verified | official_flagged
```

---

## Acceptance Criteria

- [ ] Platform can be toggled to "government approved" mode
- [ ] Approved officials can log in and see jurisdiction-scoped data only
- [ ] Official can verify or flag a citizen report
- [ ] Unresolved issues auto-escalate per SLA rules
- [ ] Official can assign government team and close issue
- [ ] Citizen sees government involvement on their report timeline
- [ ] Dashboard shows resolution stats for officials and NGOs
- [ ] Stage 1 NGO accept/reject flow continues to work unchanged

---

## Out of Scope (Deferred to Stage 3)

- AI classification and duplicate detection
- Funding and donation transparency dashboard
- Public funding ledger
- Advanced predictive analytics
- IoT / smart bin integration

---

## Completion Checklist

When Stage 2 is done:

1. Mark all scope items and acceptance criteria above
2. Update status in [STAGES.md](../STAGES.md)
3. Update [README.md](../../README.md) stage table
4. Update [HLD.md](../HLD.md) and [LLD.md](../LLD.md)
