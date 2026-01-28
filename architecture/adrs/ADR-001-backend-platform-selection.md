# ADR-001: Backend Platform Selection

**Status**: Accepted (Revised)
**Date**: 2026-01-27
**Decision Makers**: Sebastian (CEO/Product Owner), Backend Architecture Team

## Context

The diet tracking app requires a backend platform that supports:
- Real-time synchronization across multiple devices
- Offline-first capability for mobile users
- Multi-tenant data isolation (family sharing feature)
- Scalability to 10,000+ users
- **CRITICAL: Cost efficiency within $50/month budget at 10K MAU**
- Rapid development for MVP launch

The previous architecture (Supabase + PowerSync) was **rejected due to cost** - it would have cost $500-700/month at scale, far exceeding budget constraints.

## Decision

We will use a **self-hosted stack** leveraging Sebastian's existing bare metal server and free-tier services:

### Technology Stack

| Component | Technology | Cost | Purpose |
|-----------|------------|------|---------|
| Database | MongoDB (self-hosted or Atlas free tier) | $0 | Primary data store |
| Authentication | Clerk | $0 (10K MAU free) | User management, Sign in with Apple |
| API (Staging) | Vercel Serverless Functions | $0 (free tier) | Development/staging API |
| API (Production) | Node.js/Express on bare metal | $0 | Production API server |
| AI Processing | Sebastian's existing API keys | $0 | OpenAI, Claude, Gemini |
| Hosting | Sebastian's bare metal server | $0 (already owned) | Production deployment |

### Architecture Overview

```
                                    ┌─────────────────────────────────────────┐
                                    │         Sebastian's Bare Metal          │
                                    │            (Production)                 │
                                    ├─────────────────────────────────────────┤
                                    │  ┌─────────────┐  ┌─────────────────┐   │
                                    │  │  MongoDB    │  │  Node.js/       │   │
                                    │  │  (Primary)  │  │  Express API    │   │
                                    │  └─────────────┘  └─────────────────┘   │
                                    │           │              │              │
                                    └───────────┼──────────────┼──────────────┘
                                                │              │
┌──────────────────────┐                        │              │
│     iOS App          │◄───────────────────────┼──────────────┤
│  (SwiftUI + GRDB)    │                        │              │
│                      │                        │              │
│  ┌────────────────┐  │       REST API         │              │
│  │ Local SQLite   │  │◄───────────────────────┼──────────────┘
│  │ (offline-first)│  │                        │
│  └────────────────┘  │                        │
│                      │                        │
│  ┌────────────────┐  │       JWT Auth         │
│  │ Clerk iOS SDK  │──┼────────────────────────┼───────────────┐
│  └────────────────┘  │                        │               │
└──────────────────────┘                        │               │
                                                │               ▼
                                                │    ┌─────────────────────┐
                                                │    │       Clerk         │
                                                │    │  (Authentication)   │
                                                │    │  - Sign in w/ Apple │
                                                │    │  - JWT Tokens       │
                                                │    │  - User Management  │
                                                │    └─────────────────────┘
                                                │
                              Staging Only      │
                                    ▼           │
                         ┌─────────────────────────────────┐
                         │         Vercel (Staging)        │
                         ├─────────────────────────────────┤
                         │  Serverless Functions           │
                         │  - API endpoints                │
                         │  - Same code as production      │
                         │                                 │
                         │  MongoDB Atlas (Free Tier)      │
                         │  - 512MB storage                │
                         │  - Development database         │
                         └─────────────────────────────────┘
```

## Consequences

### Positive

1. **Zero Infrastructure Cost**: All services are either self-hosted or free tier
2. **Clerk Excellence**: Best-in-class Sign in with Apple, 10K MAU free
3. **MongoDB Flexibility**: Document model suits food data with varying nutrition fields
4. **No Vendor Lock-in**: Can migrate MongoDB anywhere; Clerk can be replaced
5. **Rapid Development**: Vercel for staging, simple Node.js for production
6. **Existing Resources**: Leverages Sebastian's bare metal server and AI API keys

### Negative

1. **Ops Responsibility**: Self-hosting requires maintenance (but Sebastian has DevOps skills)
2. **No Built-in Sync**: Must implement offline sync manually (simpler approach chosen)
3. **Single Point of Failure**: Bare metal server needs monitoring/backup
4. **Free Tier Limits**: Must stay within Clerk/Atlas free tier limits

### Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Bare metal server failure | Low | High | Daily backups to cloud storage; health monitoring |
| Clerk pricing changes | Low | Medium | Architecture allows swap to Auth.js/Lucia |
| MongoDB Atlas free tier limits | Medium | Low | Self-host on bare metal if needed |
| AI API costs exceed budget | Medium | Medium | Rate limiting; use Sebastian's existing subscriptions |

## Cost Analysis

### At 10,000 Monthly Active Users

| Service | Tier | Monthly Cost |
|---------|------|--------------|
| MongoDB | Self-hosted on bare metal | $0 |
| Clerk | Free tier (10K MAU) | $0 |
| Vercel | Free tier (staging only) | $0 |
| Bare Metal Server | Already owned | $0 |
| Domain/SSL | Let's Encrypt | $0 |
| AI APIs | Sebastian's existing keys | $0 |
| **Total Infrastructure** | | **$0/month** |

The entire budget can go to AI processing if needed, but Sebastian's existing API subscriptions should cover typical usage.

## Alternatives Considered

### 1. Supabase + PowerSync (Original Plan)

**Pros**:
- Built-in auth, database, real-time
- PowerSync provides excellent offline-first sync

**Cons**:
- **Cost: ~$700/month at 10K MAU** (Supabase Pro + PowerSync Growth)
- Exceeds $50/month budget by 14x

**Rejected because**: Way over budget.

### 2. Firebase + Firestore

**Pros**:
- Mature platform, built-in offline support
- Good iOS SDK

**Cons**:
- Complex pricing model, unpredictable costs
- Vendor lock-in to Google
- NoSQL limitations for relational queries

**Rejected because**: Cost unpredictability and vendor lock-in.

### 3. PocketBase (Self-hosted)

**Pros**:
- Single binary, easy to deploy
- Built-in auth and real-time
- SQLite-based

**Cons**:
- Less mature ecosystem
- No native Sign in with Apple
- Would need custom auth integration

**Rejected because**: Clerk provides better auth UX; MongoDB more flexible for food data.

### 4. Appwrite (Self-hosted)

**Pros**:
- Open-source Firebase alternative
- Self-hostable

**Cons**:
- Heavier resource requirements
- Auth less polished than Clerk

**Rejected because**: More complex than needed; Clerk + MongoDB simpler.

## Implementation Notes

### MongoDB Setup
1. **Staging**: MongoDB Atlas free tier (512MB, shared cluster)
2. **Production**: MongoDB on bare metal with daily backups to cloud storage

### Clerk Setup
1. Create Clerk application with Sign in with Apple enabled
2. Configure iOS SDK in SwiftUI app
3. Set up JWT verification on backend

### Vercel Staging
1. Deploy API as serverless functions
2. Connect to MongoDB Atlas free tier
3. Use for development and testing

### Production Deployment
1. Node.js/Express API on bare metal
2. MongoDB on same server (or separate container)
3. Nginx reverse proxy with Let's Encrypt SSL
4. PM2 for process management

## References

- [Clerk Documentation](https://clerk.com/docs)
- [Clerk Sign in with Apple](https://clerk.com/docs/authentication/social-connections/apple)
- [MongoDB Documentation](https://www.mongodb.com/docs/)
- [Vercel Serverless Functions](https://vercel.com/docs/functions)
- [MongoDB Atlas Free Tier](https://www.mongodb.com/pricing)
