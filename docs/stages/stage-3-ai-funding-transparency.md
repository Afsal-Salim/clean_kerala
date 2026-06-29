# Stage 3 — AI & Funding Transparency

> **Status:** Not started  
> **Last updated:** 2026-06-28  
> **Depends on:** Stage 2 (or Stage 1 if govt funding arrives without Stage 2)  
> **Prerequisite:** Funding from government or other organisations  
> **Blocks:** —

---

## Goal

When grants or donations arrive, add **AI-powered intelligence** and a **fully transparent funding dashboard**. Every donation reflects **immediately** on the public dashboard. Citizens and funders can see total received, spent, and remaining balance at all times.

---

## Product Concept

```
Funding received (govt grant / org sponsorship / citizen donation)
        ↓
Recorded in public ledger → Dashboard updates in real time
        ↓
AI assists reports (classify waste, detect duplicates, predict severity)
        ↓
Expenses logged against issues / campaigns with receipts
        ↓
Public sees: Total fund · Spent · Remaining · Donation history
```

---

## Scope

### Backend — Funding & Transparency

- [ ] `funding_sources` — grants, sponsorships, categories
- [ ] `donations` — individual citizen donations with amount, donor (optional anonymous), timestamp
- [ ] `expenses` — spend linked to issue, campaign, or operational category
- [ ] `funding_ledger` — append-only ledger for audit
- [ ] Real-time balance calculation: `total_in − total_out = remaining`
- [ ] WebSocket or SSE for **instant dashboard refresh** on new donation
- [ ] Public API: funding summary (no auth required for read)

### Backend — Donation Flow

- [ ] Payment gateway integration (Razorpay / Stripe — TBD)
- [ ] On successful payment → write donation row → push dashboard update
- [ ] Receipt generation for donor
- [ ] Optional anonymous donations
- [ ] Donation goals / campaigns (e.g. "Clean Kochi Week")

### Backend — Transparency Dashboard Data

- [ ] Total funding received (all time + by period)
- [ ] Breakdown by source: government · organisation · citizen
- [ ] Total spent and by category (cleanup ops, tech, outreach)
- [ ] Remaining balance
- [ ] Recent donations feed (live)
- [ ] Expense log with description and linked issue (where applicable)
- [ ] Export for audit (CSV / PDF)

### Backend — AI Classification Service

- [ ] Image classification: Plastic · Food · Construction · Mixed · Hazardous
- [ ] Auto-suggest category on report upload
- [ ] Severity prediction: Low · Medium · High · Critical
- [ ] Duplicate detection (same location + similar image)
- [ ] Before/after image comparison for issue completion validation

### Backend — AI Analytics

- [ ] Hotspot detection — recurring waste locations
- [ ] Trend reports by district / category
- [ ] NGO and official performance scoring (from Stage 2 data)
- [ ] Optional: chatbot for complaint assistance

### Backend — Leaderboards (Stage 3)

- [ ] Platform-wide leaderboards (top NGOs, citizens, volunteers by close count)
- [ ] Seasonal or campaign-based bonus badges (optional)
- [ ] Leaderboard refresh job

> **Note:** Core closure milestone badges (10, 100, 1,000, 10,000) are built in **Stage 1**. Stage 3 adds competitive rankings and optional campaign badges only.

### Backend — Enhanced Media Validation

- [ ] Live camera capture enforcement for completion photos
- [ ] GPS + timestamp + device ID metadata
- [ ] Image watermark (date, time, location)
- [ ] AI similarity check — detect reused photos

### Frontend — Public Transparency Dashboard

- [ ] **Funding overview** — total in, spent, remaining (large, clear numbers)
- [ ] **Live donations ticker** — new donations appear immediately
- [ ] Donation history table (paginated)
- [ ] Expense breakdown chart
- [ ] Source breakdown (govt / org / citizen pie chart)
- [ ] Link expenses to resolved issues where applicable

### Frontend — Donate

- [ ] Donate screen with amount presets
- [ ] Payment flow
- [ ] Success → instant redirect to dashboard showing updated total
- [ ] Share receipt

### Frontend — AI-Enhanced Reporting

- [ ] Auto-category suggestion after photo upload
- [ ] Duplicate warning ("Similar report nearby")
- [ ] Severity badge on feed posts

### Frontend — Analytics (Admin)

- [ ] Hotspot map
- [ ] AI trend charts
- [ ] Full platform analytics

---

## Database Tables (Stage 3 — New)

| Table | Purpose |
|-------|---------|
| `funding_sources` | Grants and major funding entries |
| `donations` | Individual donations |
| `expenses` | Platform and cleanup spend |
| `funding_ledger` | Append-only audit trail |
| `donation_campaigns` | Optional fundraising campaigns |
| `ai_classifications` | Model output per report |
| `rankings` | Computed NGO / volunteer / citizen rankings |

> `badges` and `user_achievements` are Stage 1 tables. Stage 3 `rankings` reads from `close_counters`.

---

## API Endpoints (Stage 3)

### Funding (Public Read)

```
GET    /api/v1/funding/summary           # Total in, spent, remaining
GET    /api/v1/funding/donations         # Recent donations (live feed)
GET    /api/v1/funding/expenses          # Expense log
GET    /api/v1/funding/breakdown         # By source and category
GET    /api/v1/funding/stream            # SSE/WebSocket for live updates
```

### Donations (Authenticated)

```
POST   /api/v1/donations/create          # Initiate payment
POST   /api/v1/donations/webhook         # Payment gateway callback
GET    /api/v1/donations/{id}/receipt
```

### Admin — Funding

```
POST   /api/v1/admin/funding/sources     # Record grant / sponsorship
POST   /api/v1/admin/funding/expenses    # Log expense
GET    /api/v1/admin/funding/ledger      # Full audit export
```

### AI

```
POST   /api/v1/ai/classify
POST   /api/v1/ai/duplicate-check
POST   /api/v1/ai/compare-images
GET    /api/v1/ai/hotspots
```

### Leaderboards (Stage 3)

```
GET    /api/v1/leaderboard/ngos
GET    /api/v1/leaderboard/citizens
GET    /api/v1/leaderboard/volunteers
```

> Achievement badges API is Stage 1 — see `GET /api/v1/achievements/*`

---

## Real-Time Donation Dashboard

When a donation succeeds:

```
Payment webhook
  → Insert donation row
  → Append funding_ledger entry
  → Recalculate balances
  → Publish event (Redis pub/sub or WebSocket)
  → All connected dashboard clients refresh immediately
```

Dashboard must show within **2 seconds** of payment confirmation:

- Updated total received
- Updated remaining balance
- New row in recent donations list

---

## Transparency Principles

- All funding sources are public (amount, source type, date)
- All expenses are public (amount, category, description, date)
- Citizen donations show name or "Anonymous"
- Ledger is append-only — no silent edits; corrections via reversal entries
- Government grants displayed with reference number where provided

---

## Acceptance Criteria

- [ ] Admin can record a government grant; dashboard totals update
- [ ] Citizen can donate; dashboard reflects amount **immediately** after payment
- [ ] Public can view total funding, spent, and remaining without logging in
- [ ] Expense entries reduce remaining balance and appear in expense log
- [ ] AI suggests waste category on photo upload
- [ ] Duplicate reports at same location are flagged
- [ ] Hotspot map shows recurring waste areas
- [ ] Ledger export available for audit
- [ ] Leaderboards rank NGOs, citizens, and volunteers by close count

---

## Future Enhancements (Post Stage 3)

- IoT smart-bin overflow alerts
- QR codes on public bins
- Open government APIs
- Carbon impact analytics
- Integration with Kerala disaster management systems

---

## Completion Checklist

When Stage 3 is done:

1. Mark all scope items and acceptance criteria above
2. Update status in [STAGES.md](../STAGES.md)
3. Update [README.md](../../README.md) stage table
4. Update [HLD.md](../HLD.md) and [LLD.md](../LLD.md)
5. Mark platform feature-complete for v1.0
