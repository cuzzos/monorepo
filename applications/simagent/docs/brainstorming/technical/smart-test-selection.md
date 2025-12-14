# Smart Test Selection: Local + Cloud Hybrid Architecture

**Last Updated:** December 14, 2025  
**Status:** Core Feature - Phases 2-4  
**Impact:** 70-85% cost reduction, major competitive differentiator

---

## Overview

Smart Test Selection is SimAgent's **killer feature** that leverages our unique local-first + cloud-enabled architecture to intelligently determine which tests to run based on code changes. By combining local filesystem access with cloud VCS integration, we achieve something no competitor can match.

**Core Value Proposition:**
> "Test smarter, not harder. SimAgent analyzes what changed and runs only the tests that matter—saving you 80% in time and cost while maintaining full coverage of critical paths."

---

## The Problem

### Current State (All Competitors)

**Naive approach:**
```
Developer changes 1 file → Run all 100 tests
Cost: $3.30, Time: 20 minutes
Result: 95 tests were unnecessary
```

**Pain points:**
- Slow feedback loops (20+ minute test runs)
- Wasted CI/CD credits
- Developers skip testing due to friction
- High costs at scale

### Industry "Solutions" (Insufficient)

**GitHub Actions path filtering:**
```yaml
on:
  push:
    paths:
      - 'src/payment/**'
```
- ❌ Too coarse-grained (folder level only)
- ❌ Requires manual configuration
- ❌ Doesn't learn over time

**Manual test tagging:**
```yaml
# payment_test.yaml
tags: [payment, checkout]
```
- ❌ Requires discipline to maintain
- ❌ Tags become stale
- ❌ Doesn't capture implicit dependencies

---

## SimAgent's Solution: Dual-Mode Intelligence

### Architecture: Local + Cloud Hybrid

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer's Machine                      │
│                                                             │
│  ┌──────────────┐         ┌──────────────┐                  │
│  │ Xcode Project│◄────────│  .git/       │                  │
│  │              │         │  (local repo)│                  │
│  └──────┬───────┘         └──────┬───────┘                  │
│         │                        │                          │
│         │  (filesystem)    (git commands)                   │
│         │                        │                          │
│  ┌──────▼────────────────────────▼───────┐                  │
│  │        SimAgent.app                   │                  │
│  │  ┌────────────────────────────────┐   │                  │
│  │  │  Local Change Detector         │   │                  │
│  │  │  - Filesystem watching         │   │                  │
│  │  │  - File hashing (SHA-256)      │   │                  │
│  │  │  - AST parsing (Swift)         │   │                  │
│  │  └────────────────────────────────┘   │                  │
│  │  ┌────────────────────────────────┐   │                  │
│  │  │  Git Integration Layer         │   │                  │
│  │  │  - Diff analysis               │   │                  │
│  │  │  - Blame tracking              │   │                  │
│  │  │  - Branch comparison           │   │                  │
│  │  │  - Historical analysis         │   │                  │
│  │  └────────────────────────────────┘   │                  │
│  │  ┌────────────────────────────────┐   │                  │
│  │  │  Hybrid Intelligence Engine    │   │                  │
│  │  │  - Combines local + git data   │   │                  │
│  │  │  - Risk scoring                │   │                  │
│  │  │  - Test selection AI           │   │                  │
│  │  │  - ACE playbook integration    │   │                  │
│  │  └────────────────────────────────┘   │                  │
│  └────────────────────┬──────────────────┘                  │
│                       │                                     │
│                       │ (sync anonymized insights)          │
└───────────────────────┼─────────────────────────────────────┘
                        │
                        ↓
┌───────────────────────────────────────────────────────────────┐
│                      SimAgent Cloud                           │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐   │
│  │              Team Playbook Database                    │   │
│  │  - Aggregated learnings from all team members          │   │
│  │  - File → Test mappings (learned)                      │   │
│  │  - Historical failure patterns                         │   │
│  │  - Risk scores by file/author/time                     │   │
│  └────────────────────────────────────────────────────────┘   │
│                           ↕                                   │
│  ┌────────────────────────────────────────────────────────┐   │
│  │              GitHub/GitLab Integration                 │   │
│  │  - Webhook listeners                                   │   │
│  │  - PR comment bot                                      │   │
│  │  - Status checks (pass / fail)                         │   │
│  │  - Commit analysis pipeline                            │   │
│  └────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────┘
```

---

## Mode 1: Local Change Detection

### How It Works

**First run:**
```bash
SimAgent stores:
├─ Project path: ~/Code/MyApp
├─ File hashes: { "PaymentVC.swift": "abc123", "HomeVC.swift": "def456" }
├─ Last run timestamp: 2025-12-14 02:00:00
└─ Test execution history: { "payment_test.yaml": [pass, pass, fail, pass] }
```

**Subsequent runs:**
```bash
SimAgent detects changes:
├─ Modified: PaymentViewController.swift (hash changed)
├─ Modified: CheckoutView.swift (hash changed)  
├─ Unchanged: 147 other files
├─ Time since last run: 2 hours ago
└─ Uncommitted changes: Yes

→ Run only payment + checkout related tests (8 tests)
→ Skip unaffected tests (37 tests)
```

### Implementation

```typescript
class LocalChangeDetector {
  private watcher: FSWatcher;
  private lastRunData: Map<string, FileHash>;
  
  async detectChanges(projectPath: string): Promise<ChangedFiles> {
    const currentHashes = await this.hashAllSourceFiles(projectPath);
    const lastHashes = await this.loadLastRunData();
    
    const changed: ChangedFile[] = [];
    
    for (const [file, hash] of currentHashes) {
      if (lastHashes.get(file) !== hash) {
        const changeType = await this.analyzeChangeType(file);
        changed.push({
          path: file,
          hash: hash,
          changeType: changeType, // LOGIC, UI, COMMENT, TEST
          linesChanged: await this.countChangedLines(file)
        });
      }
    }
    
    // Save current state for next run
    await this.saveRunData(currentHashes);
    
    return changed;
  }
  
  async hashAllSourceFiles(projectPath: string): Promise<Map<string, string>> {
    const patterns = ['**/*.swift', '**/*.m', '**/*.h'];
    const files = await glob(patterns, { cwd: projectPath });
    
    const hashes = new Map();
    for (const file of files) {
      const content = await fs.readFile(path.join(projectPath, file));
      hashes.set(file, sha256(content));
    }
    
    return hashes;
  }
  
  async analyzeChangeType(file: string): Promise<ChangeType> {
    const ast = await this.parseSwiftAST(file);
    const diff = await this.getFileDiff(file);
    
    // Detect if only comments changed
    if (diff.linesChanged === diff.commentLinesChanged) {
      return ChangeType.COMMENT;
    }
    
    // Detect if only UI styling changed
    if (this.isOnlyUIChange(ast, diff)) {
      return ChangeType.UI;
    }
    
    // Detect if test file
    if (file.includes('Test')) {
      return ChangeType.TEST;
    }
    
    return ChangeType.LOGIC;
  }
}
```

### Advantages

✅ **Instant detection** - Filesystem watching, no polling  
✅ **Works offline** - No network required  
✅ **Catches uncommitted changes** - Test before committing  
✅ **Privacy preserved** - Source code never leaves machine  
✅ **Fine-grained** - Detects single-file changes  

---

## Mode 2: Git Integration

### Local Git Analysis

```typescript
class GitIntegration {
  async analyzeGitContext(projectPath: string): Promise<GitContext> {
    const repo = await git(projectPath);
    
    return {
      // What changed since last commit
      uncommittedChanges: await repo.diff(),
      
      // What changed in this branch
      branchDiff: await repo.diff('main...HEAD'),
      
      // Historical context
      blame: await this.getBlameData(),
      
      // Risk assessment
      historicalFailures: await this.getFailureHistory(),
      
      // Branch status
      commitsBehind: await repo.revList('HEAD..origin/main'),
      commitsAhead: await repo.revList('origin/main..HEAD')
    };
  }
  
  async getFailureHistory(file: string): Promise<RiskScore> {
    // Query git log for commits that touched this file
    const commits = await git.log({ file });
    
    // Check which commits had CI failures
    const failures = commits.filter(c => c.ciStatus === 'failed');
    
    return {
      totalCommits: commits.length,
      failedCommits: failures.length,
      failureRate: failures.length / commits.length,
      lastFailure: failures[0]?.date
    };
  }
}
```

### Cloud GitHub/GitLab Integration

**GitHub App Capabilities:**
- Listen to push/PR events via webhooks
- Analyze PR diffs without accessing source code
- Post status checks and comments
- Trigger CI/CD workflows with smart test selection

```typescript
class GitHubIntegration {
  @Webhook('pull_request.opened')
  async onPullRequest(pr: PullRequest) {
    // Get PR diff (only changed lines, not full source)
    const diff = await github.getPRDiff(pr.number);
    
    // Analyze which files changed
    const changedFiles = diff.files.map(f => f.filename);
    
    // Query team playbook for affected tests
    const tests = await this.teamPlaybook.getAffectedTests(changedFiles);
    
    // Determine risk level
    const risk = await this.assessRisk(changedFiles, pr);
    
    // Post comment on PR
    await github.createComment(pr.number, {
      body: this.formatComment(tests, risk)
    });
    
    // Set status check
    await github.createStatus(pr.headSha, {
      state: 'pending',
      description: `Running ${tests.length} of ${allTests.length} tests`
    });
  }
  
  async assessRisk(files: string[], pr: PullRequest): Promise<RiskLevel> {
    const factors = {
      // How many files changed
      scope: files.length,
      
      // How many commits behind main
      staleness: pr.commitsBehind,
      
      // Historical failure rate of these files
      history: await this.getHistoricalFailureRate(files),
      
      // Author experience with these files
      authorExperience: await this.getAuthorExpertise(pr.author, files),
      
      // Time of day (late night commits = higher risk 😅)
      timing: this.getTimeRiskFactor(pr.createdAt)
    };
    
    return this.calculateRiskScore(factors);
  }
}
```

---

## Hybrid Intelligence: Best of Both Worlds

### Cross-Validation

**Scenario:** Developer thinks they only changed one file

```typescript
const localChanges = await localDetector.detect(); // ["PaymentVC.swift"]
const gitChanges = await gitIntegration.diff(); // ["PaymentVC.swift", "Info.plist"]

if (localChanges !== gitChanges) {
  warn("Local and git disagree on changes!");
  warn("Git detected additional changes in: Info.plist");
  warn("Running extended test suite to be safe.");
}
```

### Team Learning Network

```typescript
class TeamPlaybook {
  // When anyone on team runs tests locally
  async recordInsight(insight: TestInsight) {
    const anonymized = {
      fileHash: sha256(insight.file), // "File_ABC123"
      testName: insight.test,
      outcome: insight.outcome,
      timestamp: Date.now(),
      context: {
        changeSize: insight.linesChanged,
        changeType: insight.changeType
      }
    };
    
    await this.cloud.uploadInsight(anonymized);
  }
  
  // When anyone requests recommendations
  async getSuggestions(file: string): Promise<TestSuggestion[]> {
    const fileHash = sha256(file);
    
    // Query aggregated team data
    const teamData = await this.cloud.queryInsights(fileHash);
    
    return {
      recommended: teamData.mostCommonFailures,
      confidence: teamData.sampleSize / 100, // More data = higher confidence
      reasoning: `Based on ${teamData.sampleSize} runs by your team`
    };
  }
}
```

**Privacy preserved:**
- ✅ File paths hashed (not sent to cloud)
- ✅ Source code never leaves machine
- ✅ Only metadata synced (test names, outcomes, timings)
- ✅ Insights are aggregated, not individual

**Network effects:**
- Team of 10 devs → 10x training data
- Each developer benefits from others' discoveries
- Playbook gets smarter with every test run

---

## Test Selection Strategies

### Strategy 1: File Proximity (Phase 1)

**Simple heuristic:**
```typescript
function selectTestsByProximity(changedFiles: string[]): string[] {
  const tests = [];
  
  for (const file of changedFiles) {
    // Find tests in same folder
    const folder = path.dirname(file);
    const testsInFolder = glob(`${folder}/**/*_test.yaml`);
    tests.push(...testsInFolder);
    
    // Find tests with similar names
    const baseName = path.basename(file, '.swift');
    const namedTests = glob(`**/${baseName}_test.yaml`);
    tests.push(...namedTests);
  }
  
  return unique(tests);
}
```

**Effectiveness:** ~60% accurate

---

### Strategy 2: Historical Correlation (Phase 2)

**Learn from history:**
```typescript
function selectTestsByHistory(changedFiles: string[]): string[] {
  const correlations = db.query(`
    SELECT test_name, COUNT(*) as frequency
    FROM test_runs
    WHERE changed_files @> $1
      AND outcome = 'failed'
    GROUP BY test_name
    ORDER BY frequency DESC
  `, [changedFiles]);
  
  return correlations.map(c => c.test_name);
}
```

**Effectiveness:** ~75% accurate

---

### Strategy 3: ACE Playbook (Phase 3)

**AI-powered prediction:**
```typescript
async function selectTestsByACE(changedFiles: string[]): Promise<TestSelection> {
  const playbook = await loadACEPlaybook();
  
  const prompt = `
    Changed files: ${changedFiles.join(', ')}
    
    Historical data:
    ${playbook.getRelevantContext(changedFiles)}
    
    Which tests should we run?
  `;
  
  const response = await llm.complete(prompt);
  
  return {
    tests: response.recommended,
    confidence: response.confidence,
    reasoning: response.reasoning
  };
}
```

**Effectiveness:** ~85% accurate

---

### Strategy 4: Multi-Agent Consensus (Phase 4)

**Multiple agents vote:**
```typescript
async function selectTestsByConsensus(changedFiles: string[]): Promise<TestSelection> {
  // Run multiple strategies in parallel
  const [proximity, history, ace, static] = await Promise.all([
    selectTestsByProximity(changedFiles),
    selectTestsByHistory(changedFiles),
    selectTestsByACE(changedFiles),
    selectTestsByStaticAnalysis(changedFiles)
  ]);
  
  // Voting mechanism
  const votes = new Map<string, number>();
  for (const test of [...proximity, ...history, ...ace, ...static]) {
    votes.set(test, (votes.get(test) || 0) + 1);
  }
  
  // Tests that got 3+ votes (high confidence)
  const highConfidence = [...votes].filter(([_, count]) => count >= 3);
  
  // Tests that got 2 votes (medium confidence)
  const mediumConfidence = [...votes].filter(([_, count]) => count === 2);
  
  return {
    mustRun: highConfidence.map(([test]) => test),
    shouldRun: mediumConfidence.map(([test]) => test),
    confidence: 'high'
  };
}
```

**Effectiveness:** ~90% accurate

---

## User Experience

### Local Development Flow

```
┌─────────────────────────────────────────────────┐
│ SimAgent - Smart Test Selection                 │
├─────────────────────────────────────────────────┤
│ Files changed since last run (2 hours ago):     │
│                                                 │
│ ✏️  PaymentViewController.swift (47 lines)      │
│ ✏️  CheckoutView.swift (12 lines)               │
│ ➕ ReceiptService.swift (New file)              │
│                                                 │
│ Smart selection recommends (8 of 45 tests):     │
│ ✅ payment_flow_test.yaml                       │
│ ✅ checkout_test.yaml                           │
│ ✅ receipt_generation_test.yaml                 │
│ ✅ payment_error_handling_test.yaml             │
│ ... and 4 more                                  │
│                                                 │
│ Always running (3 critical tests):              │
│ 🔒 login_test.yaml                              │
│ 🔒 data_persistence_test.yaml                   │
│ 🔒 app_launch_test.yaml                         │
│                                                 │
│ Estimated: 4 min, $0.26                         │
│ (vs Full Suite: 22 min, $1.49)                  │
│                                                 │
│ Confidence: High (88%)                          │
│ Based on: 127 team runs + git history           │
│                                                 │
│ [Run Smart Tests]  [Run All]  [Customize...]    │
└─────────────────────────────────────────────────┘
```

### CI/CD Integration

**GitHub PR Comment:**
```markdown
### SimAgent Test Results ✅

**Smart Test Selection Enabled**
- Analyzed PR diff: 3 files changed
- Selected 12 of 45 tests (73% reduction)
- All tests passed in 6 minutes

**What we ran:**
- ✅ 8 tests directly affected by changed files
- ✅ 3 critical path tests (always run)
- ✅ 1 new test added in this PR

**What we skipped:**
- ⏭️ 33 tests with no affected code
- 💰 Saved ~14 minutes and $1.09

**Risk Assessment:** Low
- Files changed have 5% historical failure rate
- No changes to critical payment infrastructure
- All related tests passed

<details>
<summary>View detailed analysis</summary>

**Changed files:**
- `src/ui/HomeViewController.swift` (+47, -12)
- `src/ui/FeedView.swift` (+23, -8)
- `src/models/Post.swift` (+5, -2)

**Test selection reasoning:**
- `home_screen_test.yaml` - Directly tests HomeViewController
- `feed_test.yaml` - Tests FeedView UI
- `post_model_test.yaml` - Tests Post model changes
- ... (9 more)

</details>

[View Full Report](https://app.simagent.com/runs/abc123)
```

---

## Cost Impact Analysis

### Scenario: 10-Developer Team

**Without smart selection:**
```
50 tests per run × $0.033 = $1.65 per run
5 runs/day per dev × 10 devs = 50 runs/day
50 × $1.65 = $82.50/day
$82.50 × 20 work days = $1,650/month
```

**With smart selection (80% reduction):**
```
10 tests per run × $0.033 = $0.33 per run  
5 runs/day per dev × 10 devs = 50 runs/day
50 × $0.33 = $16.50/day
$16.50 × 20 work days = $330/month

Savings: $1,320/month ($15,840/year)
```

**Plus time savings:**
```
Without: 20 min per run × 5 runs = 100 min/day per dev
With: 4 min per run × 5 runs = 20 min/day per dev

Time saved: 80 min/day per dev × 10 devs = 800 min/day
= 13.3 hours/day = 266 hours/month

Value: 266 hours × $100/hour = $26,600/month
```

**Total value delivered: $27,920/month**  
**Cost: $499/month (Team tier)**  
**ROI: 56x**

---

## Competitive Moat

### What Competitors Can't Do

**Cloud-only tools (BrowserStack, Sauce Labs):**
- ❌ Can't access local filesystem
- ❌ Can't detect uncommitted changes
- ❌ Can't work offline
- ❌ High latency (upload IPA → test → download results)

**Local-only tools (custom scripts):**
- ❌ No team learning
- ❌ No CI/CD integration
- ❌ No historical analysis
- ❌ No cloud intelligence

**SimAgent (Local + Cloud):**
- ✅ Fast local iteration (instant change detection)
- ✅ Team learning network
- ✅ CI/CD integration
- ✅ Historical analysis
- ✅ Works offline AND online
- ✅ Privacy preserved (source stays local)

**This is a 12-18 month technical lead.**

---

## Implementation Roadmap

### Phase 1: Local Only (Months 1-6)
```typescript
✅ Filesystem watching
✅ File hashing
✅ Proximity-based test selection
✅ Basic UI for test selection

Cost reduction: 40-50%
Accuracy: 60%
```

### Phase 2: Local + Git (Months 7-12)
```typescript
✅ Local git integration
✅ Historical failure analysis
✅ Team playbook sync (basic)
✅ Risk scoring

Cost reduction: 60-70%
Accuracy: 75%
```

### Phase 3: Cloud Integration (Months 13-18)
```typescript
✅ GitHub/GitLab App
✅ PR status checks
✅ CI/CD smart selection
✅ Team playbook (advanced)

Cost reduction: 70-80%
Accuracy: 85%
```

### Phase 4: AI-Powered (Months 19-24)
```typescript
✅ ACE playbook predictions
✅ Multi-agent consensus
✅ AST-level analysis
✅ Automated test generation

Cost reduction: 80-85%
Accuracy: 90%+
```

---

## Pricing Strategy

### Feature Availability by Tier

**Free Tier:**
- ❌ No smart selection (run all tests)

**Pro Tier ($99/mo):**
- ✅ Local file tracking
- ✅ Basic smart selection (proximity)
- ❌ No git integration
- ❌ No team playbook

**Team Tier ($499/mo):**
- ✅ Local + Git integration
- ✅ Historical analysis
- ✅ Team playbook sync
- ✅ Confidence scores
- ❌ No CI/CD integration

**Enterprise Tier (Custom):**
- ✅ Everything in Team
- ✅ GitHub/GitLab App
- ✅ CI/CD smart selection
- ✅ Multi-agent consensus
- ✅ ACE-powered predictions
- ✅ Custom playbook training

---

## Success Metrics

### KPIs to Track

**Efficiency Metrics:**
- **Test reduction rate:** % of tests skipped
- **Time saved:** Minutes saved per run
- **Cost saved:** $ saved per run

**Quality Metrics:**
- **Accuracy:** % of bugs caught with smart selection vs full suite
- **False negatives:** Bugs missed due to skipped tests
- **Confidence score calibration:** Actual vs predicted accuracy

**Adoption Metrics:**
- **% of runs using smart selection**
- **Override rate:** How often users click "Run All" instead
- **Satisfaction:** NPS for this feature

### Targets (Year 1)

- Test reduction: 70%+ average
- Accuracy: 85%+ (catch 85% of bugs with 30% of tests)
- False negative rate: <5%
- Adoption: 80%+ of runs use smart selection
- User satisfaction: NPS 40+

---

## Risks & Mitigations

### Risk 1: False Negatives (Miss Bugs)

**Problem:** Skip a test that should have run, bug reaches production

**Mitigation:**
1. Always run critical path tests (login, payment, core flows)
2. Run full suite weekly (not every commit)
3. Track false negatives, improve model
4. Easy override: "Run all tests" always available
5. Confidence thresholds: If confidence < 70%, run more tests

### Risk 2: User Distrust

**Problem:** Developers don't trust the AI selection

**Mitigation:**
1. Full transparency: Show WHY tests were selected/skipped
2. Confidence scores: "85% confident based on 127 runs"
3. Override always available
4. Gradual rollout: Opt-in first, default later
5. Show cost/time savings: "Saved $50 this month"

### Risk 3: Implementation Complexity

**Problem:** Building both local + cloud is complex

**Mitigation:**
1. Phase 1: Local only (simpler, still valuable)
2. Phase 2: Add git (local, no cloud needed)
3. Phase 3: Cloud integration (when proven)
4. Modular architecture: Each component works independently

### Risk 4: Privacy Concerns

**Problem:** Users fear data leaving their machine

**Mitigation:**
1. Source code NEVER uploaded
2. Only anonymized metadata synced
3. Opt-out available for team playbook
4. Clear privacy policy
5. Open source the hashing/anonymization code

---

## Conclusion

Smart Test Selection is **SimAgent's unfair advantage**:

1. **Only possible with local + cloud architecture**
2. **Delivers massive value:** 80%+ cost/time savings
3. **Creates strong moat:** 12-18 month technical lead
4. **Network effects:** Gets better with more users
5. **Hard to copy:** Requires local app + cloud + AI/ML

This is the feature that makes SimAgent a **must-have tool** rather than a nice-to-have.

**ROI for customers:** 56x  
**Competitive advantage:** Unique capability  
**Strategic value:** Category-defining feature

---

**Next Steps:**
1. Build Phase 1 (local file tracking) in Months 1-6
2. Validate with design partners
3. Add git integration in Months 7-12
4. Scale with cloud integration in Months 13-18

