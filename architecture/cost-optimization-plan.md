# Cost Optimization Plan

**Target**: Keep total costs under **$50/month** at 10,000 Monthly Active Users (MAU)
**Date**: 2026-01-27 (Revised)

## Executive Summary

This document outlines how we achieve the aggressive $50/month budget constraint. The key insight: **leverage what we already have**.

### The $50/Month Budget Breakdown

| Category | Monthly Cost | Notes |
|----------|--------------|-------|
| Infrastructure (Bare Metal) | $0 | Sebastian's existing server |
| MongoDB | $0 | Self-hosted on bare metal |
| Clerk (Authentication) | $0 | Free tier = 10K MAU |
| Vercel (Staging) | $0 | Free tier for development |
| AI Processing | $0* | Sebastian's existing API subscriptions |
| Domain/SSL | $0 | Let's Encrypt + existing domain |
| **Total** | **$0-50/month** | Buffer for unexpected costs |

*Sebastian already pays for OpenAI, Claude, and Gemini subscriptions for other projects.

---

## 1. Infrastructure: Zero Cost Strategy

### 1.1 Bare Metal Server (Sebastian's Existing)

Sebastian owns a bare metal server that can host the entire production stack:

| Component | Specification | Purpose |
|-----------|--------------|---------|
| CPU | 8+ cores | API server, MongoDB |
| RAM | 32GB+ | MongoDB, Node.js |
| Storage | 500GB SSD | Database, backups |
| Network | 1Gbps | Low latency API |
| Location | EU/US data center | Compliance friendly |

**Monthly cost**: $0 (already paid for other projects)

**Services running**:
```
┌─────────────────────────────────────────────────────────────┐
│                 Sebastian's Bare Metal Server               │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │    Nginx        │  │    Certbot      │                   │
│  │  (reverse proxy)│  │  (Let's Encrypt)│                   │
│  └────────┬────────┘  └─────────────────┘                   │
│           │                                                  │
│  ┌────────▼────────┐  ┌─────────────────┐                   │
│  │  Node.js API    │  │    MongoDB      │                   │
│  │  (PM2 managed)  │  │   (standalone)  │                   │
│  │  Port: 3000     │  │   Port: 27017   │                   │
│  └─────────────────┘  └─────────────────┘                   │
│                                                              │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │   Backup Agent  │  │   Monitoring    │                   │
│  │  (to B2/S3)     │  │   (Uptime Kuma) │                   │
│  └─────────────────┘  └─────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 MongoDB: Self-Hosted

**Why self-hosted instead of Atlas?**

| Option | Cost at 10K MAU | Storage |
|--------|-----------------|---------|
| MongoDB Atlas M0 (Free) | $0 | 512MB limit |
| MongoDB Atlas M10 | $57/month | 10GB |
| **Self-hosted** | **$0** | **Unlimited** |

The app will need ~10GB at scale (see schema doc), exceeding Atlas free tier.

**Setup**:
```bash
# Docker compose for MongoDB
version: '3.8'
services:
  mongodb:
    image: mongo:7
    container_name: dietapp-mongo
    restart: always
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_USER}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASS}
    volumes:
      - mongodb_data:/data/db
      - ./mongo-backup:/backup
    ports:
      - "127.0.0.1:27017:27017"  # Only localhost

volumes:
  mongodb_data:
```

**Backup strategy** (free):
```bash
# Daily backup to Backblaze B2 (free tier: 10GB)
0 3 * * * mongodump --out=/backup/$(date +%Y%m%d) && \
          tar -czf /backup/dietapp-$(date +%Y%m%d).tar.gz /backup/$(date +%Y%m%d) && \
          b2 upload-file diet-backups /backup/dietapp-$(date +%Y%m%d).tar.gz && \
          rm -rf /backup/$(date +%Y%m%d)*
```

### 1.3 Vercel: Staging Only

Vercel free tier is used only for staging/development:

| Feature | Free Tier Limit | Our Usage |
|---------|-----------------|-----------|
| Deployments | 100/day | ~5/day |
| Serverless Functions | 100GB-hours | ~10GB-hours |
| Bandwidth | 100GB/month | ~5GB |
| Build minutes | 6000/month | ~100/month |

**Staging architecture**:
```
staging.dietapp.com  →  Vercel  →  MongoDB Atlas Free Tier (512MB)
api.dietapp.com      →  Bare Metal  →  MongoDB Self-Hosted
```

---

## 2. Authentication: Clerk Free Tier

### 2.1 Clerk Pricing

Clerk offers a generous free tier perfect for our needs:

| Tier | MAU | Cost | Features |
|------|-----|------|----------|
| **Free** | **10,000** | **$0** | Sign in with Apple, JWT, User management |
| Pro | 10,000+ | $25+ | Same + custom domains, advanced features |

At exactly 10K MAU, we stay within free tier.

### 2.2 Staying Within Free Tier

**Monitoring MAU**:
```typescript
// Check Clerk usage monthly
const clerkUsage = await clerkClient.organizations.getUsage();
console.log(`MAU: ${clerkUsage.mau} / 10,000`);

if (clerkUsage.mau > 9000) {
  alertAdmin('Clerk MAU approaching limit');
}
```

**Contingency if we exceed 10K MAU**:
1. Upgrade to Clerk Pro ($25/month) - still under budget
2. Or implement Auth.js with Apple OAuth (free but more work)

---

## 3. AI Processing: Leverage Existing Subscriptions

Sebastian already maintains API subscriptions for other projects:

| Service | Sebastian's Plan | Monthly Cost | Typical Allowance |
|---------|------------------|--------------|-------------------|
| OpenAI | Plus + API credits | ~$40 | $40 API credits |
| Anthropic Claude | Pro + API | ~$20 | Included API usage |
| Google Gemini | API access | ~$0 | Free tier generous |

**Strategy**: Route AI requests through Sebastian's existing accounts.

### 3.1 AI Usage Estimates

| Feature | Requests/Month | Tokens/Request | Model | Est. Cost |
|---------|----------------|----------------|-------|-----------|
| Photo Recognition | 8,000 | 1,500 | GPT-4V | ~$12 |
| Natural Language | 25,000 | 500 | GPT-3.5 | ~$2 |
| Weekly Insights | 10,000 | 2,000 | Claude Haiku | ~$3 |
| **Total** | | | | **~$17/month** |

This fits within Sebastian's existing API budgets.

### 3.2 Cost Reduction Strategies

**1. Model Tiering**:
```typescript
function selectModel(task: AITask): Model {
  switch (task.complexity) {
    case 'simple':
      return 'gpt-3.5-turbo';  // $0.0005/1K tokens
    case 'medium':
      return 'claude-3-haiku'; // $0.00025/1K tokens
    case 'complex':
      return 'gpt-4-vision';   // $0.01/1K tokens
  }
}
```

**2. Aggressive Caching**:
```typescript
// Cache AI responses for common foods
const aiCache = new LRUCache<string, AIResponse>({
  max: 10000,
  ttl: 1000 * 60 * 60 * 24 * 7  // 7 days
});

async function processFood(image: Buffer): Promise<AIResponse> {
  const hash = await imageHash(image, 16);
  const cached = aiCache.get(hash);
  if (cached) return cached;

  const result = await callAI(image);
  aiCache.set(hash, result);
  return result;
}
```

**3. Rate Limiting Free Users**:
```typescript
const aiLimits = {
  free: {
    photoRecognition: 5,   // per month
    naturalLanguage: 10,   // per month
    insights: 0            // premium only
  },
  premium: {
    photoRecognition: 500,
    naturalLanguage: 1000,
    insights: 4  // weekly
  }
};
```

---

## 4. Food Database APIs: Minimize Calls

### 4.1 API Costs

| Service | Pricing | Strategy |
|---------|---------|----------|
| Nutritionix | $200-1000/month | Avoid - too expensive |
| Open Food Facts | Free | Primary source |
| USDA FoodData Central | Free | Secondary source |

**Decision**: Use free APIs only (Open Food Facts + USDA).

### 4.2 Caching Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                    FOOD LOOKUP CACHE LAYERS                      │
├─────────────────────────────────────────────────────────────────┤
│ L1: App Memory (Swift)  │ Session     │ 30% cache hit           │
│ L2: Local SQLite        │ 30 days     │ 50% cache hit           │
│ L3: MongoDB Cache       │ 90 days     │ 15% cache hit           │
│ L4: External API        │ Fresh       │ 5% - actual API call    │
├─────────────────────────────────────────────────────────────────┤
│ Combined Cache Hit Rate Target: 95%                              │
│ Result: Minimal external API calls                               │
└─────────────────────────────────────────────────────────────────┘
```

### 4.3 Pre-Seeded Database

Seed MongoDB with common foods from free sources:

```javascript
// One-time seeding script
const foods = [
  ...await fetchUSDACommonFoods(1000),        // Top 1000 USDA foods
  ...await fetchOpenFoodFactsTop(5000),       // Top 5000 scanned products
];

await FoodCollection.insertMany(foods);
// Total: ~6000 foods pre-cached, zero ongoing cost
```

---

## 5. Domain and SSL: Free

### 5.1 Let's Encrypt SSL

```bash
# Certbot auto-renewal (free)
certbot --nginx -d api.dietapp.com -d staging.dietapp.com

# Auto-renewal cron (runs twice daily)
0 */12 * * * certbot renew --quiet
```

### 5.2 Domain

Assume Sebastian already owns a domain. If not:
- `.com` domain: ~$12/year = $1/month
- Still under $50/month budget

---

## 6. Monitoring and Observability: Free Tools

| Tool | Purpose | Cost |
|------|---------|------|
| Uptime Kuma | Uptime monitoring | $0 (self-hosted) |
| Grafana + Prometheus | Metrics | $0 (self-hosted) |
| Sentry | Error tracking | $0 (free tier) |
| Logflare | Logging | $0 (free tier) |

```yaml
# docker-compose addition for monitoring
services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    volumes:
      - uptime-kuma:/app/data
    ports:
      - "3001:3001"

  # Sentry DSN configured in app
  # Logflare API key configured for logs
```

---

## 7. Scaling Considerations

### 7.1 When We Exceed 10K MAU

| Trigger | Action | New Cost |
|---------|--------|----------|
| Clerk > 10K MAU | Upgrade to Pro | +$25/month |
| MongoDB > 50GB | Add storage | +$0 (existing capacity) |
| CPU > 80% sustained | Optimize or upgrade server | Case by case |
| AI costs > $50 | Tighten rate limits | $0 |

### 7.2 Cost Projection at Scale

| MAU | Infrastructure | Auth | AI | Total |
|-----|----------------|------|-----|-------|
| 1K | $0 | $0 | $5 | $5 |
| 5K | $0 | $0 | $15 | $15 |
| **10K** | **$0** | **$0** | **$17** | **$17** |
| 15K | $0 | $25 | $25 | $50 |
| 25K | $0 | $35 | $40 | $75 |
| 50K | $50* | $75 | $80 | $205 |

*May need additional server capacity at 50K MAU

---

## 8. Budget Contingency

The $50/month budget provides buffer for:

| Scenario | Cost | Covered? |
|----------|------|----------|
| Clerk overage (burst) | $10-20 | Yes |
| Unexpected AI spike | $20-30 | Yes |
| Domain renewal | $1 | Yes |
| Emergency cloud backup | $5 | Yes |
| CDN for assets (if needed) | $0 | Cloudflare free |

---

## 9. Comparison: Old vs. New Architecture

### Previous Plan (Supabase + PowerSync)

| Component | Monthly Cost |
|-----------|--------------|
| Supabase Pro | $25 |
| Supabase Database (8GB) | $100 |
| Supabase Edge Functions | $50 |
| PowerSync | $500 |
| Nutritionix API | $500 |
| AI Processing | $500 |
| **Total** | **$1,675/month** |

### New Plan (MongoDB + Clerk + Bare Metal)

| Component | Monthly Cost |
|-----------|--------------|
| Bare Metal Server | $0 |
| MongoDB (self-hosted) | $0 |
| Clerk | $0 |
| Vercel (staging) | $0 |
| Free Food APIs | $0 |
| AI (existing subs) | $0-17 |
| **Total** | **$0-17/month** |

**Savings: ~$1,650/month (99% reduction)**

---

## 10. Implementation Checklist

### Phase 1: Infrastructure Setup
- [ ] Configure MongoDB on bare metal
- [ ] Set up Nginx reverse proxy
- [ ] Configure Let's Encrypt SSL
- [ ] Set up daily backup script
- [ ] Deploy Uptime Kuma monitoring

### Phase 2: Services Integration
- [ ] Create Clerk application
- [ ] Configure Sign in with Apple
- [ ] Set up Vercel staging environment
- [ ] Connect to MongoDB Atlas free tier (staging)

### Phase 3: API Development
- [ ] Deploy Node.js/Express API
- [ ] Configure PM2 for process management
- [ ] Set up AI model routing
- [ ] Implement food caching layer

### Phase 4: Monitoring
- [ ] Configure Sentry error tracking
- [ ] Set up usage dashboards
- [ ] Create cost alerts

---

## Summary

By leveraging Sebastian's existing infrastructure and free-tier services, we achieve:

- **Total monthly cost**: $0-17 (well under $50 budget)
- **10K MAU capacity**: Fully supported
- **Same functionality**: All features from original plan
- **Trade-offs**: More ops responsibility, simpler sync (acceptable)

The architecture is sustainable, scalable to ~25K MAU before significant cost increases, and built on portable technologies that avoid vendor lock-in.
