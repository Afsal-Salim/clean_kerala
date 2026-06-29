# Make Kerala Clean — High-Level Design (HLD)

> **Last updated:** 2026-06-28  
> **Stage:** Pre-implementation (design baseline)

---

## 1. Project Overview

Make Kerala Clean starts as a **community platform** — a social-style feed where citizens post waste reports with photos and location. Nearby NGOs are notified and can **accept or reject** each report. When an NGO accepts, the report becomes an **open issue** they commit to resolving.

In **Stage 2**, state and local government join (if the proposal is approved) with official verification, escalation, and government-assigned cleanup.

In **Stage 3**, AI features and a **transparent funding dashboard** are added when grants or donations arrive — every donation reflects immediately on the public dashboard.

---

## 2. Objectives

- Encourage citizens to report waste through a familiar social feed experience
- Connect reports to nearby NGOs automatically by location (ward, municipality, district)
- Track issues from post → NGO acceptance → resolution
- Increase transparency in cleanup and (Stage 3) funding
- Integrate government workflows when approved (Stage 2)
- Provide AI-assisted intelligence and public financial transparency (Stage 3)

---

## 3. Stakeholders

| Stakeholder | Stage | Interest |
|-------------|-------|----------|
| Citizens | 1+ | Post reports, track issues, donate (Stage 3) |
| NGOs | 1+ | Accept/reject reports, resolve issues |
| Volunteers | 1+ | Join NGO cleanups |
| Ward Members | 2+ | Local oversight |
| Municipal Officials | 2+ | Verify, escalate, assign teams |
| Panchayat Officials | 2+ | Rural area management |
| District Administration | 2+ | District coordination |
| State Government | 2+ | Partnership, grants, policy |
| Funders / Donors | 3 | Transparent use of funds |
| System Admin | 1+ | Platform management |

---

## 4. Major Features by Stage

### Stage 1 — Community Platform

**Citizen:** Register, post waste reports (feed), comment, upvote, track my reports, **earn closure milestone badges**  
**NGO:** Register, set service areas, receive nearby notifications, accept/reject, manage issues, upload completion photos, **earn closure milestone badges**  
**Volunteer:** Join NGO, view assigned issues, **earn badges for participated closes**  
**Feed:** Public timeline of waste reports scoped by geography  
**Achievements:** Account badges at 10, 100, 1000+ closed issues (displayed on profile)

### Stage 2 — Government Integration

**Official:** Verify reports, escalate stale issues, assign government teams, close with evidence  
**Escalation:** SLA-based auto-escalation ward → municipality → district  
**Dashboard:** Government performance and jurisdiction analytics

### Stage 3 — AI & Funding Transparency

**AI:** Auto-categorize waste, detect duplicates, predict severity, hotspot analysis  
**Funding dashboard:** Total received, spent, remaining — **live updates on every donation**  
**Donate:** Citizen payment flow with instant dashboard reflection  
**Rewards:** Leaderboards and competitive rankings (optional, funding-dependent). **Closure milestone badges ship in Stage 1** — see § Achievements.

---

## 5. Core Workflow (Stage 1)

```
Citizen posts waste report (photo + GPS + description)
        ↓
Report appears on public feed (ward / municipality / district tagged)
        ↓
Nearby NGOs notified (push + in-app)
        ↓
NGO accepts  →  report status → accepted; open ISSUE created
NGO rejects  →  no status change; other NGOs can still accept
        ↓
NGO: in progress → resolved (completion photo)
        ↓
Citizen confirms → Issue closed
        ↓
Closure counted → achievement check → badge awarded if milestone hit (10, 100, 1000…)
```

---

## 5b. Achievements & Badges (Stage 1)

Accounts earn **badges on their profile** when they reach closed-issue milestones. Badges are permanent and visible to others on profile and feed cards.

### What counts as a "close"

| Account type | Close counted when |
|--------------|-------------------|
| **Citizen** | Their report's issue reaches `closed` (citizen confirmed) |
| **NGO** | An issue assigned to them reaches `closed` |
| **Volunteer** | An issue they were assigned to reaches `closed` |

### Milestone tiers

| Closes | Badge name | Icon tier |
|--------|------------|-------------|
| 10 | Green Starter | Bronze |
| 100 | Clean Warrior | Silver |
| 1,000 | Clean Kerala Champion | Gold |
| 10,000 | Waste Hero | Platinum |

Additional tiers (50, 500, 5,000) can be added in config without code changes.

### Behaviour

- On every issue `closed` event, increment the relevant account's close counter(s)
- Check if the new total crosses a milestone → award badge if not already earned
- Push notification: "You earned the Clean Warrior badge — 100 issues closed!"
- Profile shows all earned badges; highest badge shown on feed comments and report cards
- Badges are **non-transferable** and tied to the user account (NGO badge shown on NGO admin profile and NGO public page)

---

## 6. Extended Workflow (Stage 2)

```
Stage 1 flow continues
        +
Official sees reports/issues in jurisdiction
        ↓
Verify report OR escalate if NGO inactive (SLA breach)
        ↓
Government team assigned → resolved → closed
```

---

## 7. Funding Workflow (Stage 3)

```
Grant / sponsorship / citizen donation received
        ↓
Append-only ledger entry
        ↓
Dashboard updates in real time (WebSocket / SSE)
        ↓
Expenses logged against issues or operations
        ↓
Public view: total in · spent · remaining · donation feed
```

---

## 8. Categories

Plastic Waste · Food Waste · Construction Waste · Electronic Waste · Biomedical Waste · Overflowing Dustbin · Roadside Garbage · Canal Waste · Beach Waste · Illegal Dumping

---

## 9. Status Lifecycles

### Waste Report (Feed Post)

```
posted → pending_ngo → accepted → resolved → closed
```

- **NGO accept** is the only NGO action that changes report status (`pending_ngo` → `accepted`).
- **NGO reject** does not change status; logged in `ngo_responses` only. Report stays `pending_ngo` for other NGOs.

**Limits:** max **3 photos** per report · **5 reports per user per day** · **camera-only** with on-device waste verification — see [DECISIONS.md](DECISIONS.md).

### Issue (After NGO Accepts)

```
open → in_progress → resolved → closed
```

### Issue with Government (Stage 2)

```
open → escalated → govt_in_progress → govt_resolved → closed
```

---

## 10. User Roles

| Stage | Roles |
|-------|-------|
| 1 | Citizen · NGO Admin · Volunteer · System Admin |
| 2 | + Ward Member · Municipality Officer · Panchayat Officer · District Officer · MLA · State Admin |
| 3 | All above; public read-only access to funding dashboard |

---

## 11. Architecture

```
                Mobile App (Flutter)
                       |
                API Gateway
                       |
    ┌──────────────────┼──────────────────┐
    │                  │                  │
Authentication   Report / Feed       Notification
   Service         Service              Service
    │                  │                  │
   NGO / Issue    Location            Media
   Service         Service             Service
    │                  │                  │
 Official (S2)   Analytics (S2+)    Funding (S3)
   Service                            Service
    │                  │                  │
  AI (S3)          Workflow Engine
                       |
    ┌──────────────────┼──────────────────┐
    │                  │                  │
PostgreSQL        Redis Cache      Object Storage (S3)
                       |
         Email · Push · RabbitMQ · WebSocket (S3 donations)
```

---

## 12. External Services

| Service | Stage | Purpose |
|---------|-------|---------|
| Google Maps API | — | **Not used for MVP** — OSM + free GeoJSON instead |
| GPS | 1 | Location capture |
| AWS S3 | 1 | Image storage |
| Firebase Push | 1 | NGO and citizen alerts |
| Email | 1–2 | Notifications |
| Payment Gateway | 3 | Donations (Razorpay / Stripe) |
| AI Model | 3 | Classification, duplicates |

---

## 13. Technology Stack

| Layer | Choice |
|-------|--------|
| Frontend | Flutter (Android / iOS) |
| Backend | FastAPI |
| Database | PostgreSQL |
| Object Storage | AWS S3 |
| Cache / Pub-Sub | Redis |
| Queue | RabbitMQ |
| Real-time | WebSocket or SSE (Stage 3 dashboard) |
| Maps | Google Maps |
| Authentication | JWT |
| Hosting | AWS |

---

## 14. High-Level Database Entities

**Stage 1:** Users · Waste Reports · Report Images · Comments · Upvotes · NGOs · NGO Service Areas · Issues · Issue Status History · NGO Responses · Notifications · Districts · Municipalities · Wards · Volunteers · **Badges · User Achievements · Close Counters**

**Stage 2:** Officials · Escalations · Government Assignments · SLA Rules · Partnership

**Stage 3:** Funding Sources · Donations · Expenses · Funding Ledger · AI Classifications · Badges · Rankings

---

## 15. Notification Flow (Stage 1)

```
Citizen posts report
  ↓ Resolve ward / municipality / district
  ↓ Find nearby NGOs
Push + In-app → NGO admins
  ↓ NGO accepts
Push → Citizen ("Your report is being handled")
  ↓ NGO resolves
Push → Citizen ("Please confirm closure")
```

---

## 16. AI Components (Stage 3)

- **Image classification** — Plastic, Food, Construction, Mixed, Hazardous
- **Duplicate detection** — Same location + similar image
- **Severity prediction** — Low, Medium, High, Critical
- **Hotspot analysis** — Recurring waste locations
- **Before/after comparison** — Validate cleanup completion

---

## 17. Transparency & Funding (Stage 3)

- Public dashboard: total funding, spent, remaining balance
- Live donation feed — updates within seconds of payment
- Append-only ledger for audit
- Expense log linked to issues where applicable
- Government grants shown with reference numbers

---

## 18. Security Considerations

- JWT with role-based access control
- GPS validation within Kerala bounds
- Rate limiting: **5 reports per user per day**; max **3 photos** per report
- NGO accept uses concurrency lock (one NGO per issue)
- Official accounts require admin approval (Stage 2)
- Append-only funding ledger (Stage 3)
- Encryption for payment data and PII

---

## 19. Future Enhancements

- IoT smart-bin integration
- QR codes on public waste bins
- Open government APIs
- Carbon impact analytics
- Kerala e-governance integration
- AI chatbot for reporting assistance

---

## 20. Implementation Stages

See [STAGES.md](STAGES.md) for detailed scope per stage.

| Stage | Name | Trigger |
|-------|------|---------|
| 1 | Community Platform | Launch MVP |
| 2 | Government Integration | Govt approves proposal |
| 3 | AI & Funding Transparency | Funding received |
