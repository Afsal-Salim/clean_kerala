# Make Kerala Clean (MKC)

A civic-tech platform that starts as a **community-driven waste reporting network** — like a social feed for cleanliness — and grows into government-backed infrastructure with transparent funding.

**Stage 1:** Citizens post waste reports; nearby NGOs accept or reject. Accepted reports become open **issues**. Accounts earn **badges at 10, 100, 1,000+ closes** on their profile.

**Stage 2:** State and local government join the platform (after proposal approval) with official workflows.

**Stage 3:** AI features, plus a public **funding transparency dashboard** — donations and grants reflect immediately.

## Repository Structure

```
clean_kerala/
├── frontend/          # Flutter mobile app (Android/iOS)
├── backend/           # FastAPI backend services
├── docs/              # Design docs, stage plans, and maintenance guides
│   ├── HLD.md
│   ├── LLD.md
│   ├── STAGES.md
│   └── stages/
└── .cursor/rules/     # AI rules (including doc sync on code changes)
```

## Technology Stack

| Layer | Technology |
|-------|------------|
| Mobile | Flutter |
| Backend | FastAPI |
| Database | PostgreSQL |
| Cache | Redis |
| Queue | RabbitMQ |
| Object Storage | AWS S3 |
| Maps | Google Maps API |
| Auth | JWT |
| Hosting | AWS |

## Development Stages

The project is delivered in **three stages**. See [docs/STAGES.md](docs/STAGES.md) for the full roadmap.

| Stage | Focus | Status |
|-------|-------|--------|
| [Stage 1](docs/stages/stage-1-community-platform.md) | Community platform — social feed, NGOs, accept/reject → issues | Not started |
| [Stage 2](docs/stages/stage-2-government-integration.md) | Government integration — officials, approval, escalation | Not started |
| [Stage 3](docs/stages/stage-3-ai-funding-transparency.md) | AI features + transparent funding & donation dashboard | Not started |

## Documentation

| Document | Description |
|----------|-------------|
| [High-Level Design (HLD)](docs/HLD.md) | Architecture, features, stakeholders, workflows |
| [Low-Level Design (LLD)](docs/LLD.md) | APIs, database tables, state machine, algorithms |
| [Documentation Maintenance](docs/DOCUMENTATION.md) | How to keep docs in sync with code changes |
| [Locked Decisions](docs/DECISIONS.md) | Product defaults (limits, status rules) |

**Important:** Whenever you modify code, update the relevant documentation. See [docs/DOCUMENTATION.md](docs/DOCUMENTATION.md).

## Quick Start

> Stage 1 setup instructions will be added as implementation begins.

### Backend

```bash
cd backend
# Setup instructions in backend/README.md
```

### Frontend

```bash
cd frontend
# Setup instructions in frontend/README.md
```

## User Roles

| Stage | Roles |
|-------|-------|
| 1 | Citizen · NGO Admin · Volunteer · System Admin |
| 2 | + Ward Member · Municipality Officer · Panchayat Officer · District Officer · MLA · State Admin |
| 3 | All roles + public funding viewers |

## License

TBD
