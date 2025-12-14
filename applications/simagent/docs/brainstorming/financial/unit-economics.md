# Unit Economics Analysis

**Last Updated:** December 14, 2025  
**Focus:** Cost structure, margins, CAC, LTV, and payback analysis

---

## Overview

SimAgent's unit economics are healthy for a SaaS business, with 70-75% blended gross margins comparable to leading developer tools companies. The primary costs are AI API calls (GPT-4 Vision) and infrastructure (Mac compute), both of which scale efficiently with usage.

---

## Cost Structure

### Per-Test Cost Breakdown

```
Infrastructure Costs:
├─ Mac compute: $0.0015 per test
├─ Database/storage: $0.0005 per test
└─ Bandwidth: $0.0005 per test
   Subtotal: $0.0025 per test

AI Vision Costs (variable based on cache hits):
├─ Cache miss (35%): $0.05 × 1.75 screenshots = $0.0875
└─ Cache hit (65%): $0
   Weighted average: $0.0306 per test

Total Cost per Test: $0.033 per test
```

### Cost Components Explained

**Infrastructure ($0.0025/test):**
- **Mac compute:** Simulator runtime, Maestro execution
- **Database:** PostgreSQL for test results, playbooks, analytics
- **Storage:** S3 for screenshots, videos, test artifacts
- **Bandwidth:** Upload/download of test assets

**AI Vision ($0.0306/test weighted average):**
- **Primary cost:** GPT-4 Vision API calls for screenshot analysis
- **Cache strategy:** 65% hit rate reduces costs significantly
- **Screenshots per test:** Average 5 total, 1.75 unique (after caching)
- **Cost per screenshot:** $0.05 (GPT-4 Vision pricing)

### Cost Optimization Strategies

**1. Aggressive Caching (Target: 70%+ hit rate)**
- Perceptual hashing (pHash) for similar screenshots
- Screenshot deduplication across tests
- **Impact:** Reduces AI costs by 70%

**2. Selective AI Analysis**
- Only analyze screenshots on failures or visual changes
- Skip analysis for unchanged screens
- **Impact:** Additional 30-50% cost reduction

**3. Multi-Vendor Strategy**
- Primary: OpenAI GPT-4 Vision ($0.05/image)
- Fallback: Anthropic Claude Vision (competitive pricing)
- Future: Custom fine-tuned model
- **Impact:** Reduces vendor lock-in risk

**4. Tiered AI Features**
- Free tier: No AI Vision
- Pro tier: AI Vision on failures only
- Enterprise tier: Full AI Vision + multi-agent
- **Impact:** Aligns costs with revenue

---

## Revenue Per Test

### By Pricing Tier

```
Free Tier (100 tests/month):
├─ Revenue: $0
├─ Cost: $3.30/month
└─ Margin: -100% (acquisition cost)

Pro Tier ($99/month, ~500 tests/month):
├─ Revenue per test: $0.198
├─ Cost per test: $0.033
└─ Gross margin: 83%

Team Tier ($499/month, ~2,500 tests/month):
├─ Revenue per test: $0.20
├─ Cost per test: $0.033
└─ Gross margin: 84%

Enterprise Tier ($5K-50K/month, custom volume):
├─ Revenue per test: $0.10-1.00
├─ Cost per test: $0.033
└─ Gross margin: 67-97%
```

### Gross Margin Analysis

**Target Blended Gross Margin: 70-75%**

**Formulas:**
- **Revenue per test** = Monthly Subscription Price / Number of Tests per Month
- **Cost per test** = Infrastructure Cost + AI Model Cost
- **Gross Margin** = (Revenue per test - Cost per test) / Revenue per test × 100%
- **Blended Gross Margin** = Weighted average across all tiers based on customer distribution

**Benchmark Comparison:**
- Datadog: 77% gross margin
- Snowflake: 65% gross margin
- GitHub: 80%+ gross margin
- **SimAgent target: 70-75%** (healthy for SaaS)

---

## Customer Acquisition Cost (CAC)

### By Channel

| Channel | Cost per Lead | Conversion Rate | Effective CAC |
|---------|---------------|-----------------|---------------|
| **Organic (Product Hunt, SEO)** | $50 | 10% | $500 |
| **Content Marketing** | $100 | 8% | $1,250 |
| **Paid Ads (Google, Twitter)** | $200 | 5% | $4,000 |
| **Direct Sales (Enterprise)** | $10,000 | 20% | $50,000 |

### Blended CAC Over Time

**Year 1 Blended CAC: $1,000-2,000**
- Heavy reliance on organic and content marketing
- Limited paid advertising budget
- No direct sales team yet

**Year 3 Blended CAC: $2,000-5,000**
- Mix of organic, content, and paid channels
- Adding enterprise sales team
- Higher CAC offset by higher LTV (Team/Enterprise tiers)

### CAC Optimization Strategy

**Phase 1 (Year 1): Organic-First**
- Product Hunt launch
- Content marketing (blogs, tutorials)
- SEO optimization
- Community building (Reddit, forums)
- **Target CAC:** $500-1,000

**Phase 2 (Year 2): Scaling Content**
- Paid content promotion
- Conference sponsorships
- Developer relations program
- **Target CAC:** $1,000-2,000

**Phase 3 (Year 3+): Multi-Channel**
- Paid advertising at scale
- Direct sales for enterprise
- Partner channel development
- **Target CAC:** $2,000-5,000 (offset by higher LTV)

---

## Customer Lifetime Value (LTV)

### LTV Calculation

```
Assumptions:
├─ Average Monthly Churn: 5%
├─ Average Customer Lifetime: 20 months (1/churn rate)
└─ Enterprise churn lower: 3% = 36 months

ARPU by Segment:
├─ Pro: $99/month × 20 months = $1,980 LTV
├─ Team: $750/month × 20 months = $15,000 LTV
└─ Enterprise: $15K/month × 36 months = $540,000 LTV

Blended ARPU (Year 1): $150/month
Blended LTV (Year 1): $3,000

Blended ARPU (Year 3): $500/month
Blended LTV (Year 3): $15,000
```

### LTV:CAC Ratio

**Rule of thumb:** LTV:CAC > 3x is good, > 5x is excellent

**Year 1:**
- LTV: $3,000
- CAC: $1,500
- **LTV:CAC = 2.0x** (Acceptable, needs improvement)

**Year 3:**
- LTV: $15,000
- CAC: $3,000
- **LTV:CAC = 5.0x** (Excellent)

**Improvement Strategy:**
1. Reduce churn through better onboarding (5% → 3%)
2. Increase ARPU through upsells (Pro → Team → Enterprise)
3. Optimize CAC through organic channels
4. Focus on higher-value customer segments

---

## CAC Payback Period

### Calculation

```
Formula: CAC Payback = CAC / (ARPU × Gross Margin)

Year 1 Scenario:
├─ Blended ARPU: $150/month
├─ Blended CAC: $1,500
├─ Gross Margin: 70%
└─ Payback Period = $1,500 / ($150 × 0.70) = 14.3 months

Year 3 Scenario:
├─ Blended ARPU: $500/month
├─ Blended CAC: $3,000
├─ Gross Margin: 72%
└─ Payback Period = $3,000 / ($500 × 0.72) = 8.3 months
```

### Industry Benchmarks

- **Target:** < 12 months (best-in-class)
- **Acceptable:** < 18 months
- **Red flag:** > 24 months

**SimAgent Assessment:**
- Year 1: 14.3 months (acceptable, needs improvement)
- Year 3: 8.3 months (excellent)

**Improvement Plan:**
1. Increase Pro tier adoption (higher ARPU per CAC dollar)
2. Reduce CAC through organic channels
3. Improve activation rate (free → paid conversion)
4. Faster time-to-value (reduce churn in first 3 months)

---

## Cohort Economics

### Monthly Cohort Analysis (Pro Tier Example)

| Month | Customers | Monthly Revenue | Cumulative Revenue | Cumulative Profit |
|-------|-----------|-----------------|--------------------|--------------------|
| 0 | 100 | $9,900 | $9,900 | -$140,100 (after CAC) |
| 1 | 95 | $9,405 | $19,305 | -$133,835 |
| 3 | 86 | $8,514 | $45,459 | -$109,281 |
| 6 | 73 | $7,227 | $89,838 | -$68,802 |
| 12 | 54 | $5,346 | $160,812 | -$6,828 |
| 14 | 49 | $4,851 | $183,669 | **+$10,029** ← Break-even |
| 24 | 30 | $2,970 | $283,140 | $93,510 |

**Break-even:** 14.3 months (matches payback calculation)

---

## Unit Economics by Tier

### Free Tier

**Purpose:** Lead generation and activation

```
Revenue: $0
Cost: $3.30/month (100 tests × $0.033)
CAC: $500 (organic)
Conversion to paid: 10%

Economics:
├─ Direct loss: -$3.30/month
├─ CAC: -$500
└─ Value: $50 (10% × $500 LTV from converted users)

Net: -$453 per free user
```

**Verdict:** Acceptable loss for acquisition

---

### Pro Tier ($99/month)

**Target:** Individual developers and small teams

```
Revenue: $99/month
Cost: $16.50/month (500 tests × $0.033)
Gross Profit: $82.50/month
Gross Margin: 83%
CAC: $1,000
Lifetime: 20 months

LTV: $1,650 (20 months × $82.50)
LTV:CAC: 1.65x
Payback: 12 months
```

**Verdict:** Healthy economics, need to improve LTV:CAC to 3x+

---

### Team Tier ($499/month)

**Target:** Development teams (5-20 developers)

```
Revenue: $499/month
Cost: $82.50/month (2,500 tests × $0.033)
Gross Profit: $416.50/month
Gross Margin: 84%
CAC: $2,500
Lifetime: 20 months

LTV: $8,330 (20 months × $416.50)
LTV:CAC: 3.3x
Payback: 6 months
```

**Verdict:** Excellent economics, target growth segment

---

### Enterprise Tier ($5,000-50,000/month)

**Target:** Large organizations with multiple iOS teams

```
Revenue: $15,000/month (average)
Cost: $1,650/month (50,000 tests × $0.033)
Gross Profit: $13,350/month
Gross Margin: 89%
CAC: $50,000
Lifetime: 36 months (lower churn)

LTV: $480,600 (36 months × $13,350)
LTV:CAC: 9.6x
Payback: 4 months
```

**Verdict:** Best economics, prioritize when ready (Year 2-3)

---

## Sensitivity Analysis

### Impact of AI Cost Changes

| AI Cost Change | New Cost/Test | Gross Margin Impact |
|----------------|---------------|---------------------|
| **-50%** (cheaper models) | $0.018 | 73% → **78%** (+5pp) |
| **Baseline** | $0.033 | **73%** |
| **+50%** (OpenAI price increase) | $0.048 | 73% → **69%** (-4pp) |
| **+100%** (double AI costs) | $0.063 | 73% → **65%** (-8pp) |

**Mitigation:** Multi-vendor strategy, custom model investment

---

### Impact of Churn Changes

| Monthly Churn | Avg Lifetime | LTV (Pro) | LTV:CAC |
|---------------|--------------|-----------|---------|
| **3%** | 33 months | $2,723 | **2.7x** |
| **5%** (baseline) | 20 months | $1,650 | **1.65x** |
| **7%** | 14 months | $1,155 | **1.2x** ⚠️ |
| **10%** | 10 months | $825 | **0.8x** ❌ |

**Mitigation:** Invest heavily in onboarding, product stickiness

---

## Key Takeaways

### ✅ Strengths

1. **Healthy gross margins:** 70-75% comparable to best-in-class SaaS
2. **Low infrastructure costs:** Compute is cheap, scales efficiently
3. **Clear path to profitability:** Unit economics improve with scale
4. **Strong enterprise economics:** 9.6x LTV:CAC at enterprise tier

### ⚠️ Areas for Improvement

1. **Year 1 CAC payback:** 14 months (target < 12)
2. **Pro tier LTV:CAC:** 1.65x (target > 3x)
3. **AI cost dependency:** 93% of costs are AI API (vendor risk)
4. **Churn assumption:** 5% is optimistic, need strong retention

### 🎯 Optimization Priorities

1. **Improve activation:** Get users to first valuable test faster
2. **Reduce CAC:** Focus on organic channels (content, community)
3. **Increase ARPU:** Drive Pro → Team upgrades
4. **Reduce churn:** Invest in onboarding and customer success

---

## Comparison to Benchmarks

| Metric | SimAgent | Industry Benchmark | Assessment |
|--------|----------|-------------------|------------|
| **Gross Margin** | 70-75% | 70-80% | ✅ On par |
| **LTV:CAC (Year 1)** | 2.0x | 3.0x+ | ⚠️ Below target |
| **LTV:CAC (Year 3)** | 5.0x | 3.0x+ | ✅ Excellent |
| **CAC Payback** | 14 months | < 12 months | ⚠️ Acceptable |
| **Monthly Churn** | 5% | 3-7% | ✅ Reasonable |
| **ARPU Growth** | 3.3x (Y1→Y3) | 2-3x | ✅ Strong |

---

**Overall Verdict:** Unit economics are sound and improve significantly with scale. Bootstrap-friendly with clear path to strong margins. Primary risk is AI cost volatility and churn assumptions.

