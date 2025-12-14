# Future Projects & Enhancements

This directory contains vision documents and ideas for future enhancements to the Thiccc development workflow and testing infrastructure.

## Overview

These are **aspirational documents** describing systems and workflows we'd like to build to improve development efficiency, particularly around automated testing and AI agent capabilities.

## Documents in This Directory

### [simagent-ios-automation.md](./simagent-ios-automation.md)

**Vision:** Fully automated iOS UI testing driven by AI agents

**Problem it solves:**
- Currently, every code change requires manual verification in the iOS simulator
- This is slow, tedious, and blocks AI agents from working autonomously
- Human becomes a bottleneck in the development loop

**Proposed solution:**
- AI agent generates Maestro YAML test scripts
- macOS agent automatically builds app, runs tests, captures results
- Results flow back to development agent
- Agent iterates automatically until tests pass

**Why Maestro:**
- Simple YAML syntax (AI-friendly)
- Built-in video recording for animation review
- Fast execution (~5-7 seconds per test)
- No compilation overhead

**Status:** 💡 Vision / Planning  
**Effort:** Medium (1-2 weeks for MVP)  
**Impact:** 🚀 High - enables 24/7 autonomous development

**Start here if:** You want to eliminate manual testing bottleneck

---

### [development-workflow.md](./development-workflow.md)

**Description:** Documents current Linux + macOS split workflow

**Covers:**
- What works where (Linux vs macOS)
- Current pain points
- Optimization strategies
- Tools and commands for each environment
- Future automated workflow vision

**Status:** 📖 Reference documentation  
**Audience:** Developers and AI agents working on Thiccc

**Read this if:** You want to understand the current development setup and its limitations

---

## Current Testing Strategy

**What we use:**
- ✅ **Rust unit tests** - 100% line coverage required (enforced via `make coverage-check`)
- ✅ **Maestro** - ALL UI testing (smoke tests, critical flows, animation review)

**What we DON'T use:**
- ❌ Swift integration tests - Redundant with 100% Rust coverage
- ❌ XCTest UI - Too flaky, Maestro is better for our needs

**See:** [../testing_strategies/README.md](../testing_strategies/README.md) for full details

---

## SimAgent Automation Roadmap

### Phase 1: Manual Testing (Current)
**Status:** ✅ In use

- AI agent writes Rust code
- AI agent ensures 100% coverage (`make coverage-check`)
- Human manually tests UI in simulator
- Human reports results back
- Agent iterates based on feedback

**Pros:** Works today, no infrastructure needed  
**Cons:** Slow, requires human for every UI change

---

### Phase 2: Semi-Automated Testing with Maestro
**Status:** 🎯 Next milestone (high priority)  
**Effort:** 2-4 days

**Goal:** Reduce human intervention to running a single command

**Implementation:**
1. AI agent generates Maestro YAML tests
2. Human runs `maestro test tests/maestro/test-name.yaml` on macOS
3. Test results are clear pass/fail
4. Human reports: "✅ passed" or "❌ failed: [error]"

**Benefits:**
- Faster feedback (one command vs manual clicking)
- Repeatable tests (can re-run anytime)
- Executable documentation
- Video recording for animation review

**Prerequisites:**
- Maestro installed: `brew install maestro`
- App builds successfully: `make xcode-build`
- Simulator available: `make list-sims`

**Next steps:**
- Create first Maestro test for a simple flow
- Validate workflow with AI agent
- Document test creation patterns

---

### Phase 3: Automated Maestro Test Execution
**Status:** 🔮 Future (weeks)  
**Effort:** 1-2 weeks

**Goal:** Maestro tests run automatically without human intervention

**Implementation:**
1. **File-based communication** between agents:
   ```
   .agent-tasks/
   ├── current-task.json       ← AI agent writes task
   ├── maestro-tests/          ← AI agent writes test YAML
   │   └── verify-phase-X.yaml
   └── results/                ← macOS agent writes results
       └── phase-X/
           ├── status.txt      (PASS/FAIL)
           ├── output.txt      (logs)
           └── video.mp4       (recording)
   ```

2. **macOS watcher script** detects new tests
3. Automatically builds app: `make xcode-build`
4. Runs Maestro test: `maestro test --video <test.yaml>`
5. Saves results (status, logs, video) to shared location
6. AI agent reads results and continues

**Requirements:**
- Shared filesystem (Dropbox, git sync, or network share)
- macOS machine always available (can be headless)
- Watcher script running as daemon

**Benefits:**
- No human needed for test execution
- Agent works overnight on multiple features
- Fast iteration (5-10 seconds per test)
- Video artifacts for debugging failures

---

### Phase 4: AI Vision-Enhanced SimAgent
**Status:** 🌟 Vision (months)  
**Effort:** Months (but highest value!)

**Goal:** Complete autonomous development loop with visual verification

**Features:**
1. **AI Vision Analysis** (GPT-4 Vision or similar)
   - Automatically analyze screenshots/videos
   - Detect layout issues, spacing problems, color bugs
   - Verify animations are smooth
   - Check accessibility (contrast, font sizes)

2. **Intelligent Iteration**
   - AI agent gets specific feedback: "Button is outside screen bounds"
   - Agent fixes code automatically
   - Re-tests until visual issues resolved

3. **Multi-Device Testing**
   - Run tests on iPhone SE, iPhone 15 Pro, iPhone 15 Pro Max
   - Catch responsive layout issues automatically

4. **Performance Metrics**
   - Measure animation frame rates
   - Track memory usage during tests
   - Detect performance regressions

**The Game-Changer:**
```
Without AI Vision:
- Test passes ✅
- But button is wrong color ❌ (human catches later)

With AI Vision:
- Test passes ✅
- AI detects: "Button should be blue (#007AFF) but is gray (#808080)"
- AI agent fixes automatically ✅
```

**Benefits:**
- Fully autonomous agent (no human needed)
- 24/7 development capability
- Catches visual bugs automatically
- Scales to multiple features in parallel
- Higher quality than manual testing

---

## Related Documentation

### Testing Strategy
- **[../testing_strategies/README.md](../testing_strategies/README.md)** - Complete testing strategy overview
- **[../testing_strategies/COVERAGE-QUICK-START.md](../testing_strategies/COVERAGE-QUICK-START.md)** - Rust 100% coverage guide
- **[../testing_strategies/maestro.md](../testing_strategies/maestro.md)** - Maestro UI testing guide

### Coverage Requirements
- **[../../.cursor/rules/rust-coverage.mdc](../../.cursor/rules/rust-coverage.mdc)** - Mandatory coverage rules

### Development Workflow
- **[development-workflow.md](./development-workflow.md)** - Linux + macOS split workflow
- **[simagent-ios-automation.md](./simagent-ios-automation.md)** - Detailed SimAgent architecture

## How to Contribute Ideas

If you have ideas for future enhancements:

1. **Create a new markdown file** in this directory
2. **Follow this structure:**
   - Overview (what problem does it solve?)
   - Vision (what would the solution look like?)
   - Architecture (how would it work?)
   - Implementation phases
   - Benefits and challenges
   - Resources and related docs

3. **Update this README** with a link and summary

## Questions & Discussion

For questions about these projects or to propose new ideas:
- Open an issue in the repository
- Discuss in team chat
- Tag with `future-enhancement` label

## Implementation Priority

**Now (Phase 2):**
- Focus on Maestro test creation
- Build pattern library of common test scenarios
- Validate that AI agents can generate good Maestro YAML

**Next (Phase 3):**
- Implement file-based communication
- Create macOS watcher script
- Automate test execution

**Future (Phase 4):**
- Integrate AI vision APIs
- Build feedback loop for visual analysis
- Scale to multi-device parallel testing

---

**Last Updated**: December 13, 2025  
**Status**: Living document - aligned with simplified testing strategy  
**Maintainers**: Development team

