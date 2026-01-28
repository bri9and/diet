# Diet App - Architecture Documentation

**Phase 3 Deliverables - Backend Architecture**
**Date**: 2026-01-27
**Author**: Agent 03: BACKEND

## Overview

This directory contains the complete backend architecture documentation for the diet tracking app. All decisions are based on Sebastian's approved choices:

- **Backend Platform**: Supabase + PowerSync
- **Cost Tolerance**: ~$5-8K/month at 10K users
- **AI Privacy**: Process-and-delete (no photo storage)
- **Food Database**: Nutritionix (primary) + Open Food Facts + USDA

---

## Document Index

### Architecture Decision Records (ADRs)

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-001](./adrs/ADR-001-backend-platform-selection.md) | Backend Platform Selection | Accepted |
| [ADR-002](./adrs/ADR-002-database-architecture.md) | Database Architecture | Accepted |
| [ADR-003](./adrs/ADR-003-food-database-strategy.md) | Food Database Strategy | Accepted |
| [ADR-004](./adrs/ADR-004-authentication-flow.md) | Authentication Flow | Accepted |
| [ADR-005](./adrs/ADR-005-sync-protocol.md) | Sync Protocol | Accepted |

### Technical Specifications

| Document | Description |
|----------|-------------|
| [database-schema.sql](./database-schema.sql) | Complete PostgreSQL schema with RLS |
| [api-specification.md](./api-specification.md) | REST API and Edge Function specs |
| [cost-optimization-plan.md](./cost-optimization-plan.md) | Cost management strategies |

---

## Quick Reference

### Technology Stack

```
┌─────────────────────────────────────────────────────────────┐
│                         iOS App                              │
│                   (SwiftUI + PowerSync SDK)                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      PowerSync Service                       │
│                   (Offline-First Sync Layer)                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        Supabase                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ PostgreSQL   │  │ Supabase Auth│  │ Edge Functions│       │
│  │ + RLS        │  │ + Apple SSO  │  │ (Deno)        │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│   Nutritionix    │ │ Open Food Facts  │ │  Claude AI API   │
│   (Food API)     │ │  (Barcode API)   │ │ (Photo/NLP)      │
└──────────────────┘ └──────────────────┘ └──────────────────┘
```

### Database Tables

| Table | Purpose | Synced |
|-------|---------|--------|
| users | User profiles and preferences | Yes |
| user_goals | Nutrition targets and body metrics | Yes |
| foods | Food items (cached + custom) | Custom only |
| food_logs | Meal containers | Yes |
| meal_items | Individual logged foods | Yes |
| recent_foods | User's frequently used foods | Yes |
| daily_summaries | Pre-computed daily totals | Yes |
| families | Family groups | Yes |
| family_members | Family membership | Yes |
| family_invites | Pending invitations | Yes |
| weight_logs | Weight measurements | Yes |

### API Endpoints Summary

| Category | Base Path | Auth Required |
|----------|-----------|---------------|
| Auth | `/auth/v1/*` | No |
| User Data | `/rest/v1/users` | Yes |
| Food Logs | `/rest/v1/food_logs` | Yes |
| Food Search | `/functions/v1/search-foods` | Yes |
| AI Processing | `/functions/v1/process-food-photo` | Yes |
| Family | `/functions/v1/invite-family-member` | Yes |

### Cost Summary (10K MAU)

| Category | Monthly Cost |
|----------|-------------|
| Infrastructure (Supabase + PowerSync) | $500-900 |
| Food Database APIs | $200-600 |
| AI Processing | $1,500-4,000 |
| **Total** | **$2,200-5,500** |

---

## Implementation Checklist

### Phase 1: Foundation
- [ ] Create Supabase project
- [ ] Run database-schema.sql migration
- [ ] Configure Row-Level Security policies
- [ ] Set up Supabase Auth with Apple SSO
- [ ] Connect PowerSync to Supabase

### Phase 2: Core Features
- [ ] Implement Edge Functions for food search
- [ ] Set up Nutritionix API integration
- [ ] Implement barcode lookup with Open Food Facts
- [ ] Create user profile management endpoints

### Phase 3: AI Features
- [ ] Implement photo processing Edge Function
- [ ] Set up natural language parsing
- [ ] Create AI insights generator
- [ ] Implement rate limiting for AI features

### Phase 4: Family Sharing
- [ ] Implement family creation and invites
- [ ] Configure family RLS policies
- [ ] Build family member management
- [ ] Test data isolation

### Phase 5: Optimization
- [ ] Implement multi-tier caching
- [ ] Set up cost monitoring dashboards
- [ ] Configure auto-scaling rules
- [ ] Performance testing and tuning

---

## Security Considerations

1. **Row-Level Security**: All tables protected by RLS policies
2. **JWT Validation**: All Edge Functions verify Supabase JWT
3. **Input Validation**: Parameterized queries, no raw SQL
4. **Secret Management**: All API keys in Supabase Vault
5. **Photo Privacy**: Process-and-delete, no permanent storage
6. **HTTPS Only**: All traffic encrypted in transit
7. **Soft Deletes**: Data recoverable, audit trail maintained

---

## Next Steps

1. Review all ADRs with the team
2. Create Supabase project and run migrations
3. Implement PowerSync sync rules
4. Build Edge Functions for AI processing
5. Set up monitoring and alerting
6. Performance testing before launch
