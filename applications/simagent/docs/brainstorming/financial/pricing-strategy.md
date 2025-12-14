# Pricing Strategy

**Last Updated:** December 14, 2025  
**Focus:** Tiered pricing, packaging, value-based monetization

---

## Overview

SimAgent uses a **value-based tiered pricing model** that aligns with customer segments and scales from individual developers to large enterprises. The strategy balances accessibility (free tier for activation), growth (self-serve tiers), and profitability (enterprise custom pricing).

**Core Pricing Philosophy:** Charge based on value delivered (time saved, bugs caught) not just usage (test runs).

---

## Pricing Tiers

### Tier Overview

| Tier | Price | Target Segment | Key Features |
|------|-------|----------------|--------------|
| **Free** | $0 | Individual devs, evaluation | 100 tests/month, basic features |
| **Pro** | $99/mo | Solo devs, small teams (1-2) | Unlimited tests, AI Vision, email support |
| **Team** | $499/mo | Dev teams (5-20 people) | Collaboration, CI/CD, shared playbooks |
| **Enterprise** | Custom | Large orgs (50+ devs) | SSO, compliance, dedicated support |

---

## Free Tier

### Positioning

**Purpose:** Lead generation, activation, and viral growth

**Target Users:**
- Individual developers evaluating the product
- Hobbyist iOS developers
- Students and learners
- Open source project maintainers

### Features

**Included:**
- ✅ 100 test runs per month
- ✅ Maestro test execution (fast, reliable)
- ✅ Basic AI error messages (limited)
- ✅ Community support (Discord/forums)
- ✅ Local macOS app
- ✅ Test history (30 days)

**Not Included:**
- ❌ AI Vision for visual testing
- ❌ ACE playbook suggestions
- ❌ CI/CD integrations
- ❌ Team collaboration
- ❌ Priority support
- ❌ Custom branding on reports

### Economics

```
Revenue: $0
Cost: $3.30/month (100 tests × $0.033)
CAC: $500 (organic)
Conversion to paid: 10%

Purpose: Activation and qualification
Value per free user: $50 (lifetime value of converted users)
Net cost: -$453 per free user (acceptable acquisition cost)
```

### Conversion Strategy

**Upgrade Prompts:**
- Hit 100 test limit → "Upgrade for unlimited"
- See visual bug not caught → "Enable AI Vision in Pro"
- Want CI/CD integration → "Available in Pro tier"
- 30-day history expires → "Pro gets 90 days, Team gets 1 year"

**Target Conversion Rate:**
- Month 1: 5% (users evaluating)
- Month 3: 10% (activated users)
- Month 6: 15% (power users)

---

## Pro Tier - $99/month

### Positioning

**Tagline:** "Professional iOS testing for serious developers"

**Target Users:**
- Solo iOS developers
- Freelance developers
- Small teams (1-2 people)
- Side projects with revenue

### Features

**All Free features, plus:**
- ✅ **Unlimited test runs**
- ✅ **AI Vision analysis** (visual regression detection)
- ✅ **Smart error messages** (natural language diagnostics)
- ✅ **Phase 2: AI test suggestions** (ACE playbooks)
- ✅ **Email support** (24-hour response time)
- ✅ **Test history** (90 days)
- ✅ **Custom branding** on reports
- ✅ **Priority bug fixes**

**Usage Limits:**
- Tests: Unlimited
- Projects: Up to 3 iOS apps
- Seats: 1 user
- Storage: 5GB (screenshots, videos)

### Value Proposition

**Time Savings Calculation:**
```
Without SimAgent:
- Manual testing: 2 hours/week
- Debugging cryptic errors: 3 hours/week
- Visual regression checks: 2 hours/week
Total: 7 hours/week = 28 hours/month

With SimAgent:
- Automated testing: 0.5 hours/week
- AI error messages: 0.5 hours/week
- AI visual checks: 0 hours/week
Total: 1 hour/week = 4 hours/month

Time saved: 24 hours/month
Value at $100/hour: $2,400/month
Cost: $99/month
ROI: 24x
```

### Upgrade Path

**To Team Tier:**
- When adding 2+ team members
- When needing shared test libraries
- When integrating with CI/CD
- When managing 4+ apps

---

## Team Tier - $499/month

### Positioning

**Tagline:** "Collaborative iOS testing for development teams"

**Target Users:**
- Development teams (5-20 people)
- iOS-focused startups
- Digital agencies
- Mid-size product companies

### Features

**All Pro features, plus:**
- ✅ **5 seats included** ($99 per additional seat)
- ✅ **Unlimited projects** (manage all your iOS apps)
- ✅ **Team collaboration:**
  - Shared test libraries
  - Team dashboards
  - Test result sharing
- ✅ **CI/CD integrations:**
  - GitHub Actions
  - GitLab CI
  - CircleCI
  - Jenkins
- ✅ **ACE playbooks** (team-specific + global)
- ✅ **Slack/Email notifications**
- ✅ **Role-based permissions** (admin, developer, viewer)
- ✅ **Priority support** (4-hour response time)
- ✅ **Test history** (1 year)
- ✅ **25GB storage**

### Value Proposition

**Team ROI Calculation:**
```
10-person iOS team:
- Each developer saves 20 hours/month
- Total time saved: 200 hours/month
- Value at $100/hour: $20,000/month
- Cost: $499/month (5 seats) + $396 (4 additional seats) = $895/month
- ROI: 22x
```

### Pricing Model

**Base:** $499/month (5 seats)
**Additional seats:** $99/month each
**Volume discount:** 20+ seats → $79/seat

**Example Pricing:**
- 5 seats: $499/month
- 10 seats: $994/month
- 20 seats: $1,984/month
- 30 seats: $2,269/month (volume discount applied)

### Upgrade Path

**To Enterprise:**
- When needing SSO (Okta, Azure AD)
- When requiring compliance features
- When managing 50+ developers
- When needing on-premise deployment
- When requiring SLA guarantees

---

## Enterprise Tier - Custom Pricing

### Positioning

**Tagline:** "Enterprise-grade iOS testing with compliance and scale"

**Target Users:**
- Large enterprises (Fortune 500)
- Companies with 50+ iOS developers
- Highly regulated industries (healthcare, finance)
- Companies requiring on-premise/air-gapped deployments

### Features

**All Team features, plus:**
- ✅ **Unlimited seats**
- ✅ **SSO integration** (Okta, Azure AD, OneLogin)
- ✅ **SAML 2.0** authentication
- ✅ **Advanced security:**
  - IP whitelisting
  - Audit logs
  - Data residency options
  - SOC 2 Type II compliance
- ✅ **On-premise deployment option**
- ✅ **Dedicated support:**
  - Named customer success manager
  - 1-hour response SLA
  - Phone support
  - Quarterly business reviews
- ✅ **Custom integrations**
- ✅ **Training and onboarding**
- ✅ **Unlimited storage**
- ✅ **Custom playbook training** (ACE)
- ✅ **Multi-agent debugging** (Phase 4)
- ✅ **Zero-defect certification** (MAKER)

### Pricing Model

**Starting Price:** $5,000/month ($60K/year)

**Pricing Factors:**
1. **Seat count:**
   - 50-100 seats: $5K-10K/month
   - 100-500 seats: $10K-30K/month
   - 500+ seats: $30K-50K+/month

2. **Test volume:**
   - <100K tests/month: Included
   - 100K-500K: +$5K/month
   - 500K-1M: +$10K/month
   - 1M+: Custom pricing

3. **Deployment:**
   - Cloud (standard): Included
   - On-premise: +$20K/year setup + $10K/year maintenance
   - Air-gapped: Custom (typically $50K+ annual premium)

4. **Support tier:**
   - Standard (4-hour SLA): Included
   - Premium (1-hour SLA): +$1K/month
   - 24/7 on-call: +$5K/month

5. **Advanced features:**
   - Zero-defect certification (MAKER): +$2K/month
   - Custom playbook training: +$10K one-time
   - Professional services: $250/hour

### Example Enterprise Pricing

**Mid-size Enterprise (200 developers):**
```
Base (100 seats): $15,000/month
Additional seats (100): $7,900/month
Test volume (250K/month): $5,000/month
Premium support: $1,000/month
Total: $28,900/month ($347K/year)
```

**Large Enterprise (500 developers):**
```
Base (500 seats): $35,000/month
On-premise deployment: $10,000/month (prorated)
Zero-defect certification: $2,000/month
24/7 support: $5,000/month
Professional services: $5,000/month
Total: $57,000/month ($684K/year)
```

### Value Proposition

**Enterprise ROI:**
```
500-developer organization:
- 100 actively using SimAgent
- Each saves 15 hours/month
- Total: 1,500 hours/month
- Value at $150/hour (enterprise rate): $225,000/month
- Cost: $35,000/month
- ROI: 6.4x

Additional value:
- Avoided production bugs: $50K-500K/year (depending on severity)
- Faster release cycles: 20-30% improvement
- Reduced QA headcount needs: $200K-500K/year
```

---

## Pricing Philosophy & Strategy

### Value-Based Pricing

**Not usage-based:**
- ❌ Don't charge per test run (creates disincentive to test more)
- ❌ Don't charge per project (limits adoption)
- ❌ Don't charge per screenshot (hidden costs frustrate users)

**Do charge for:**
- ✅ Seats (aligns with team size and value)
- ✅ Capabilities (AI Vision, multi-agent, playbooks)
- ✅ Service level (support SLAs, uptime guarantees)
- ✅ Integrations (CI/CD, SSO, compliance)

### Pricing Anchors

**Free Tier → Pro:**
- Anchor: Time savings (24 hours/month @ $100/hour = $2,400 value)
- Price: $99/month
- **Value ratio: 24x**

**Pro → Team:**
- Anchor: Team productivity (200 hours/month @ $100/hour = $20,000 value)
- Price: $499-895/month
- **Value ratio: 20-40x**

**Team → Enterprise:**
- Anchor: Enterprise scale + compliance + risk mitigation
- Price: $5,000-50,000/month
- **Value ratio: 5-10x**

### Competitive Positioning

| Competitor | Entry Price | Target Market | SimAgent Advantage |
|------------|-------------|---------------|---------------------|
| **XCTest UI** | Free | All iOS devs | We're faster, smarter, with AI |
| **Maestro OSS** | Free | DIY devs | We add AI + cloud + collaboration |
| **BrowserStack** | $200+/month | Cross-platform | We're iOS-specialized + AI |
| **Appium** | Free (OSS) / $400+ (cloud) | Enterprise | We're simpler + AI-first |

**Pricing Strategy:**
- **Free tier:** Matches open source (Maestro, XCTest)
- **Pro tier:** Undercuts BrowserStack ($99 vs $200+)
- **Team tier:** Premium to open source, competitive with cloud tools
- **Enterprise:** Value-based, 50-70% of incumbent pricing

---

## Monetization Tactics

### Expansion Revenue

**Seat Expansion:**
- Team grows from 5 → 10 seats
- Revenue increases $499 → $994 (+99%)

**Tier Upgrades:**
- Pro → Team (5x revenue increase)
- Team → Enterprise (10-50x increase)

**Feature Upsells:**
- Zero-defect certification: +$2K/month
- Professional services: $250/hour
- Custom playbooks: +$10K one-time

**Target Net Dollar Retention: 120-130%**

### Discounts & Promotions

**Annual Billing:**
- Pay annually: 15% discount
- Pro: $99/mo → $1,010/year ($84/mo effective)
- Team: $499/mo → $5,090/year ($424/mo effective)

**Startup Program:**
- <2 years old, <$1M funding
- 50% off Pro/Team for first year
- Requirements: Logo + case study

**Education:**
- Free Pro tier for students (.edu email)
- Free Team tier for university courses
- Purpose: Build brand awareness

**Non-Profit:**
- 30% discount on all paid tiers
- Verification required

**Open Source:**
- Free Pro tier for OSS maintainers
- Public repos with 100+ stars
- Logo + attribution required

### Bundle Strategies

**Launch Bundle (Limited Time):**
- Pro tier: $79/month (save $20, first 100 customers)
- **Purpose:** Create urgency, reward early adopters

**Annual Commitment:**
- Lock in current pricing for 3 years
- **Purpose:** Retention, predictable revenue

---

## Pricing Evolution Over Time

### Phase 1: Initial Launch (Months 1-6)

**Pricing:**
- Free: $0 (100 tests)
- Pro: $79/month (launch discount)
- Team: Not yet available
- Enterprise: Not yet available

**Focus:** Activation, product-market fit

---

### Phase 2: Scale Self-Serve (Months 7-12)

**Pricing:**
- Free: $0 (100 tests)
- Pro: $99/month (regular price)
- Team: $499/month (NEW)
- Enterprise: Not yet available

**Focus:** Team adoption, collaboration features

---

### Phase 3: Enterprise Ready (Months 13-24)

**Pricing:**
- Free: $0 (100 tests)
- Pro: $99/month
- Team: $499-1,999/month (volume tiers)
- Enterprise: $5K-50K/month (NEW)

**Focus:** Enterprise sales, compliance, SSO

---

### Phase 4: Value-Based Expansion (Months 24+)

**Pricing:**
- Free: $0 (50 tests) ← reduced to drive upgrades
- Pro: $129/month ← increase justified by Phase 2-4 AI features
- Team: $599-2,499/month
- Enterprise: $10K-100K/month

**New Add-Ons:**
- Zero-defect certification: $2K/month
- Multi-agent debugging: Included in Enterprise
- Custom playbook training: $10K
- Professional services: $250/hour

**Focus:** Maximize revenue per customer, premium features

---

## Objection Handling

### "Too expensive compared to free tools"

**Response:**
> "You're right that XCTest and Maestro are free, but they cost you time. SimAgent saves your team 20+ hours per week through AI error messages, visual testing, and smart suggestions. At $100/hour, that's $8,000/month in value for $99/month."

---

### "We'll build this internally"

**Response:**
> "Many teams consider that. Here's what you'd need: iOS simulator infrastructure, AI Vision integration, caching layer, web dashboard, CI/CD connectors, and ongoing maintenance. That's typically 6-12 months of 2-3 engineers = $300K-600K. We're $1,200/year. Plus, we're adding multi-agent debugging and ACE playbooks that would take years to build internally."

---

### "Not sure if we'll use enough to justify cost"

**Response:**
> "Start with the free tier (100 tests/month). If you find value, upgrade to Pro. No annual commitment required. Most teams find they save enough time in the first week to justify the annual cost."

---

### "What if you raise prices later?"

**Response:**
> "Lock in current pricing with annual billing. We guarantee no price increases for the length of your contract. Annual customers on legacy plans keep their pricing even after we increase list prices."

---

## Key Metrics to Track

### Pricing Health Metrics

**ARPU (Average Revenue Per User):**
- Target: $150/month (Year 1) → $500/month (Year 3)
- Track by cohort, segment, acquisition channel

**Price Sensitivity:**
- A/B test pricing (+/- 20%)
- Monitor conversion rate impact
- Survey willingness to pay

**Expansion Revenue:**
- Net Dollar Retention: Target 120-130%
- Measure seat expansion, tier upgrades, add-ons

**Tier Distribution:**
- Healthy mix: 60% Pro, 30% Team, 10% Enterprise (by customer count)
- Revenue mix: 20% Pro, 40% Team, 40% Enterprise

---

## Conclusion

**Pricing Summary:**
- **Free:** Lead generation and activation
- **Pro ($99/mo):** Individual developers and small teams
- **Team ($499/mo):** Collaborative testing for dev teams
- **Enterprise (Custom):** Large organizations with compliance needs

**Strategic Advantages:**
- Value-based pricing (not usage-based)
- Clear upgrade paths between tiers
- Competitive positioning against both OSS and commercial tools
- Room for expansion revenue (seats, tiers, add-ons)
- Flexible enough to evolve with product (Phase 1-4 features)

**Expected Outcome:**
- Blended ARPU: $150/month (Year 1) → $500/month (Year 3)
- Net Dollar Retention: 120-130%
- Gross margin: 70-75%
- Strong unit economics support both bootstrap and VC paths

