---
title: "Solving a Million-Step LLM Task with Zero Errors"
type: research
category: research
paper_type: academic
purpose: "Demonstrates how extreme task decomposition and error correction enable LLM systems to reliably execute tasks requiring over one million sequential steps with zero errors"
audience: [Product Managers, ML Engineers, AI Researchers, Engineering Leads]
date_created: 2025-11-23
last_updated: 2025-11-23
tags: [llm, agents, multi-agent, reliability, error-correction, task-decomposition, scaling, microagents, voting, towers-of-hanoi]

# Paper metadata
authors: "Elliot Meyerson, Giuseppe Paolo, Roberto Dailey, Hormoz Shahrzad, Olivier Francon, Conor F. Hayes, Xin Qiu, Babak Hodjat, Risto Miikkulainen"
institution: "Cognizant AI Lab & UT Austin"
publication_date: "2025-11"
publication_venue: "arXiv"
arxiv_id: "2511.09030v1"
doi: "10.48550/arXiv.2511.09030"
paper_url: "https://arxiv.org/abs/2511.09030"

# Product relevance
domains: [ai-agents, reliability-engineering, task-automation, production-systems, ai-safety]
potential_applications: [complex-workflows, long-running-processes, safety-critical-systems, task-orchestration, autonomous-agents]
implementation_complexity: medium
---

# Solving a Million-Step LLM Task with Zero Errors

## Executive Summary

This paper introduces **MAKER** (Maximal Agentic decomposition, first-to-ahead-by-K Error correction, and Red-flagging), the first system to successfully solve a task requiring over one million LLM steps with zero errors. The breakthrough comes from an extreme "divide-and-conquer" approach: instead of trying to build increasingly intelligent single agents, the authors decompose tasks into the smallest possible subtasks, each handled by focused "microagents."

The key innovation is combining **maximal agentic decomposition (MAD)** with **efficient error correction through voting** and **red-flagging** to filter unreliable responses. By breaking a million-step task into a million one-step subtasks and using multiple agents to vote on each step, the system achieves perfect reliability. Surprisingly, smaller, cheaper non-reasoning models (like GPT-4.1-mini at $0.0016/MTok) outperform more expensive reasoning models for this application.

This matters for product development because it offers an orthogonal path to AI scaling: rather than waiting for better base models, we can achieve superintelligent behavior through massively decomposed agentic processes (MDAPs). The implications span from workflow orchestration to safety-critical systems where reliability is paramount.

## Research Context

### Problem Statement

LLMs have achieved remarkable capabilities in reasoning and tool use, but they have a persistent per-step error rate that prevents scaling to large numbers of sequential steps. Recent experiments showed LLMs inevitably fail on tasks requiring hundreds of consecutive correct steps, with even a 1% per-step error rate leading to near-certain failure after only 100 steps. 

The core question: **How can LLM-based systems execute tasks requiring millions of sequential operations with extreme precision when base models have inherent error rates?**

This is critical because:
- Real-world organizational processes (supply chains, hospitals, infrastructure) require executing vast numbers of steps reliably
- Most LLM benchmarks focus on tasks with relatively few dependent logical steps
- A 99% accuracy on independent test examples is considered "solved," but yields expected failure after 100 steps of a dependent task
- LLMs are increasingly being inserted into safety-critical and large-scale processes

### Research Questions

- Can LLM-based systems scale to execute tasks with millions of steps with zero errors?
- What is the optimal level of task decomposition for reliability and cost efficiency?
- How does decomposition granularity affect the probability of success and expected computational cost?
- Can error correction techniques from other computing domains (quantum, classical, biological) be adapted to "linguistic computing"?
- Are advanced reasoning models necessary, or can smaller models suffice when properly orchestrated?

## Methodology

### Approach

The paper introduces the **Massively Decomposed Agentic Processes (MDAP)** framework with three core components:

1. **Maximal Agentic Decomposition (MAD)**: Break tasks into the smallest possible subtasks (m=1 step per agent) rather than assigning agents multiple steps. Each "microagent" has a single, focused role.

2. **First-to-ahead-by-k Voting**: For each subtask, sample multiple independent solutions and use statistical voting to select the correct answer. A candidate wins when it has k more votes than any competitor. This is mathematically optimal (based on Sequential Probability Ratio Test).

3. **Red-flagging**: Discard responses showing signs of unreliability (overly long responses >750 tokens, incorrect formatting) as these correlate with confused reasoning and incorrect answers.

### Key Components

**Mathematical Framework:**
- Derives scaling laws showing cost grows as Θ(slns) for maximal decomposition vs exponential growth Θ(p^(-m)cslns) for coarser decomposition
- Shows required voting margin k_min grows logarithmically with task size: k_min = Θ(lns)
- Proves that without extreme decomposition, tasks become computationally infeasible

**Testbed:**
- Uses Towers of Hanoi benchmark (20 disks = 2^20-1 = 1,048,575 steps)
- Each agent receives current state and must produce: (1) next move, (2) resulting state
- Strategy provided upfront to isolate execution capability from insight generation
- Can validate correctness of each step independently

**Implementation:**
- Tested 10+ models (proprietary & open-source) from 3B to 671B parameters
- Measured per-step error rates on random samples before full run
- Used error rate estimates to project cost and select optimal model
- Temperature 0 for first vote, 0.1 for subsequent votes

### Evaluation Metrics

- **Per-step error rate (1-p)**: Proportion of incorrect responses on individual steps
- **Consecutive error-free steps**: Expected steps before failure = 1/error_rate
- **Solve rate**: Probability of completing entire task with zero errors
- **Expected cost**: Total API cost to achieve target solve probability
- **Collision count**: Steps where multiple initial votes are incorrect (measures correlated errors)
- **Convergence rate**: How quickly undecided steps decrease with voting rounds

## Key Findings

### Primary Results

**Perfect Solution Achieved:**
- First system to solve 1M+ step task (20-disk Towers of Hanoi) with zero errors
- Used GPT-4.1-mini as base model with k=3 voting threshold
- Total cost: ~$3.5K (vs projected $9.4K for o3-mini, $41.9K for gpt-4.1-nano)

**Per-step Error Rates (Figure 6):**
- gpt-4.1-mini: 0.223% - 0.45% error rate (varies by temperature)
- o3-mini (reasoning model): 0.17% error rate
- gpt-4.1-nano (cheapest): 35.71% error rate (too high for practical use)
- Open-source gpt-oss-20B: 3.58% error rate (best open-source option at $0.2/MTok)

**Surprising finding:** Per-step error rates remain remarkably stable as problem size increases (10-20 disks), suggesting good scaling properties.

**Cost Efficiency:**
- Non-reasoning models outperform reasoning models on cost-effectiveness for this application
- Smaller models sufficient when properly orchestrated through decomposition
- Cost dominated by first k voting rounds due to exponential convergence

### Supporting Findings

**Convergence Behavior:**
- Exponential decay in undecided steps after k rounds (Figure 8)
- 99%+ of cost spent in first k voting rounds
- Vast majority of steps resolve in first 3-5 votes
- One pathological step required 18 votes but still converged correctly

**Red-flagging Impact (Figure 9):**
- Error rate jumps precipitously when responses exceed ~700 tokens
- Formatting errors correlate strongly with reasoning errors
- Red-flagging reduces correlated errors more than overall error rate
- Collision count (both votes wrong) drops significantly with red-flagging
- Without red-flagging, collisions far exceed i.i.d. predictions

**Error Decorrelation:**
- Zero overlap in errors between two independent runs of 10K samples
- Indicates errors are sufficiently decorrelated for voting to work
- Temperature variation sufficient for decorrelation in this domain

**Model Size Findings:**
- Smaller models (3.2B params) had >100% error rate (Llama-3.2-3B)
- Mid-size models (20B-235B) hit "sweet spot" for cost/performance
- Largest models (671B-1T) didn't justify increased cost
- Non-reasoning models more cost-effective than reasoning models

**Decomposition Scaling Laws (Figure 5):**
- Expected cost grows exponentially with steps-per-agent (m)
- m=100 costs ~10^10 more than m=1 for same reliability
- Validates maximal decomposition (m=1) as optimal strategy

### Preliminary Extensions

**Multiplication Experiments (Appendix F):**
- Extended framework to handle insight generation (not just execution)
- Four agent types: decomposition, decomposition-discriminator, solution-discriminator, problem-solver
- Recursive decomposition with voting at each level
- Achieved 100% solve rate on 5×5 digit multiplication, 95% on 6×6
- Demonstrates generalization beyond pre-specified strategies

## Practical Implications

### For Product Development

**Workflow Reliability:**
- Framework applicable to any long-running, multi-step process requiring high reliability
- Could orchestrate complex business workflows (order processing, compliance checks, data pipelines)
- Particularly valuable when single failures cascade into major issues
- Enables "zero-defect" automation in domains currently requiring human oversight

**Cost-Performance Tradeoffs:**
- Provides mathematical tools (Eq. 18) to estimate costs before full deployment
- Can select optimal model based on per-token cost and estimated error rate
- Smaller models often more economical than bleeding-edge reasoning models
- Suggests "fleet of small agents" architecture over "single powerful agent"

**Safety-Critical Applications:**
- Demonstrates path to deploying LLMs in high-stakes scenarios (medical, financial, safety systems)
- Multiple independent checks built into architecture
- Each microagent's limited scope enables better sandboxing and auditing
- Reduces risk of undetected collusion or harmful behavior

**Alternative Scaling Path:**
- Don't wait for better foundation models—scale through orchestration
- Orthogonal to "bigger models" approach pursued by most AI labs
- May reach superintelligent behavior sooner through MDAPs than through model improvements alone

### For Engineering

**Architecture Patterns:**
- **Microagents as microservices**: Parallels with microservice architecture
  - Modularity: Each agent tailored to specific task
  - Independent scaling: Scale individual agent types based on bottlenecks  
  - Design for failure: System tolerates any single agent failure
  - Real-time monitoring: Can track per-step success rates
  
**Implementation Considerations:**
- Requires infrastructure for massive parallelization (millions of agent calls)
- Need efficient batching/async execution (OpenAI Batch API used in paper)
- Must handle non-determinism and sampling with temperature
- Parsing/validation critical—formatting errors are red flags
- Monitoring essential: track error rates, voting rounds, costs per step

**Technical Requirements:**
- Ability to decompose tasks into minimal, well-defined subtasks
- Each subtask must have verifiable correct answer
- Infrastructure to spawn and manage millions of agent instances
- Voting/consensus mechanisms with efficient convergence detection
- Red-flagging system to identify and discard suspicious responses

**Scalability:**
- Log-linear scaling: O(s log s) cost for s steps
- Parallelizable: voting rounds can run concurrently  
- Cost dominated by first k rounds, then negligible
- Can trade cost for reliability by adjusting k

### For Decision Making

**When to Use MDAPs:**
- Long-running processes (>1000 steps) where reliability is critical
- Tasks decomposable into clear, verifiable subtasks
- Situations where per-step error rate is manageable but compounding errors are not
- Cost-sensitive applications where cheaper models can be orchestrated effectively

**When NOT to Use:**
- Tasks requiring holistic context or gestalt reasoning
- Problems where decomposition is unknown or computationally expensive to discover
- Time-critical applications unable to wait for voting rounds
- Domains where errors are tolerable or self-correcting

**Risk Mitigation:**
- Framework reduces AI safety risks by limiting individual agent scope
- Smaller models less likely to exhibit harmful emergent behaviors
- Multiple independent checks prevent single point of failure
- May reduce model welfare concerns (sentience less likely in focused micro-agents)

**Strategic Insights:**
- Investment in orchestration infrastructure may yield better ROI than waiting for GPT-5
- Organizations can achieve production-grade reliability with current models
- "Intelligence amplification through decomposition" viable path to superintelligence
- Suggests competitive advantage in execution reliability vs reasoning capability

## Key Learnings & Takeaways

1. **Extreme decomposition enables extreme reliability**: Breaking million-step tasks into million one-step subtasks makes voting-based error correction feasible and efficient

2. **Cost scales log-linearly with maximal decomposition**: Expected cost grows as O(s log s), while coarser decomposition causes exponential cost growth—decomposition isn't just good, it's optimal

3. **Smaller, cheaper models can outperform larger ones**: GPT-4.1-mini ($1.6/MTok) more cost-effective than o3-mini ($4.5/MTok) or GPT-4.1-nano ($0.48/MTok) for long-horizon tasks when properly orchestrated

4. **Error stability is encouraging**: Per-step error rates don't degrade as task size increases from 1K to 1M steps, suggesting the approach can scale far beyond

5. **Red-flagging prevents correlated errors**: Discarding overly-long or misformatted responses is more important for reducing correlated errors than improving overall error rate—it's about avoiding pathological cases

6. **Voting threshold grows logarithmically**: Need only k ~ log(s) votes per step to maintain high reliability, making the approach practical even at scale

7. **First k rounds dominate cost**: Exponential convergence means 99%+ of cost is in initial voting rounds, rest is "rounding error"—early stopping very effective

8. **Non-reasoning models sufficient for execution**: When strategy/plan is provided, reasoning models offer little advantage over standard models for step-by-step execution

9. **Multi-agent advantage demonstrated**: Analogous to quantum advantage—achieves results impossible for single-agent systems regardless of capability

10. **Microagents ≈ microservices**: Same benefits (modularity, independent scaling, fault tolerance, monitoring) apply to decomposed agentic systems as to decomposed software systems

## Connections & Related Work

### Related Research

**LLM Scaling & Reasoning:**
- Shojaee et al. (2025) "Illusion of Thinking" - showed LLMs fail catastrophically on Towers of Hanoi after few hundred steps
- Dziri et al. (2023) "Faith and Fate" - demonstrated exponential performance degradation with task horizon length
- Sinha et al. (2025) - showed small per-step improvements lead to exponential gains in achievable task length
- Schaeffer et al. (2023) - "emergent abilities" may be mirage; continuous improvement through decomposition more reliable

**Multi-Agent Systems:**
- Belcak et al. (2025) - advocated for small language models in agentic AI for reliability and cost
- Guo et al. (2024), Wang et al. (2024) - surveys of LLM-based multi-agent systems
- Meyerson & Qiu (2025) - position paper advocating extreme decomposition and "micro-roles" vs anthropomorphized agents

**Error Correction:**
- Voting/ensembling: Long history in ML (Opitz & Maclin 1999, Ganaie et al. 2022)
- LLM ensembling: Used in coding systems (AlphaCode, self-consistency in CoT)
- Quantum error correction (Roffe 2019, Fowler et al. 2012) - analogous challenges with inherent noisiness
- Classical computing: Error correction enables pretending computation is deterministic when bits flip constantly

**Structured Output & Validation:**
- Geng et al. (2025) JSONSchemaBench, OpenAI structured outputs - enforcing correct formats
- Pydantic, json_repair, Guardrails-AI - post-hoc fixing of LLM outputs
- This paper shows formatting errors are red flags for wrong reasoning, not just annoyances

### Relevant to Our Work

**Internal Connections:**
- Workflow orchestration systems could adopt MDAP architecture for reliability
- Agent-based automation initiatives should consider microagent approach vs monolithic agents
- Cost optimization: evaluate if multiple cheaper model calls beat single expensive call
- Safety/compliance systems need zero-error execution frameworks

**Product Areas That Could Benefit:**
- **Data pipelines**: Multi-step transformations where failures cascade
- **Compliance/audit workflows**: Require complete accuracy in processing
- **Code generation**: Complex codebases need many coordinated changes
- **Document processing**: Multi-step extraction/validation/transformation
- **Testing orchestration**: Coordinating many test steps with dependencies
- **Customer support automation**: Complex resolution processes with multiple steps

**Architecture Implications:**
- Consider "microagent mesh" architecture analogous to service mesh
- Voting/consensus as first-class architectural primitive
- Red-flagging/validation layer before accepting agent outputs
- Cost/reliability tradeoff calculators based on scaling laws
- Monitor per-step error rates to detect degradation

## Further Reading

### In the Paper

**Key Sections:**
- Section 3.2: Mathematical derivation of scaling laws (Equations 9-18) - essential for understanding cost/reliability tradeoffs
- Figure 6: Per-step error rates across models - practical guide for model selection
- Section 4.5 & Figure 9: Red-flagging impact analysis - shows importance of correlated error mitigation
- Appendix D: Sample responses showing correct vs confused reasoning
- Appendix F: Multiplication experiments - demonstrates generalization beyond execution-only tasks

**Critical Figures:**
- Figure 1: Cost vs error-free steps across models - shows MAKER breakthrough
- Figure 3: Scaling laws for reliability with voting threshold k
- Figure 4: Cost scaling showing log-linear growth with maximal decomposition
- Figure 5: Exponential cost increase with steps-per-agent
- Figure 8: Convergence showing exponential decay in undecided steps

### Beyond the Paper

**Foundational Concepts:**
- Shannon (1948) "Mathematical Theory of Communication" - error correction fundamentals
- Meyerson & Qiu (2025) "Scaling LLM Agents Requires Asymptotic Analysis" - theoretical foundation for MAKER
- Bernoulli (1713) "Ars Conjectandi" - gambler's ruin problem underlying voting math

**Related Benchmarks:**
- Towers of Hanoi as LLM benchmark: Shojaee et al. (2025)
- Multi-step reasoning evaluation: Patel et al. (2024) Multi-LogiEval
- Long-horizon tasks: Kwa et al. (2025)

**Alternative Approaches:**
- Self-consistency (Wang et al. 2022) - voting at task level vs subtask level
- AlphaCode (Li et al. 2022) - voting on complete programs
- Semantic density (Qiu & Miikkulainen 2024) - uncertainty quantification in semantic space

**Microservices Parallel:**
- Fowler & Lewis (2014) "Microservices" - architectural patterns applicable to microagents
- Goyal & Bhasin (2025) - moving from monolithic to microservices for multi-agent systems

**Code & Implementations:**
- Source code: github.com/cognizant-ai-lab/neuro-san-benchmarking (multiplication experiments)
- Video demonstration: youtube.com/watch?v=gLkehsQy4H4 (animation of million-step process)
- OpenAI Batch API used for efficient parallelization

**Philosophical Implications:**
- Lynch et al. (2025) - agentic misalignment and insider threats
- Anthropic (2025) Claude system cards - model safety considerations
- Tkachenko (2024) - AI welfare and conscious suffering mitigation
- Debates on whether LLMs "think" or "reason": Varela et al., Khan et al., Opus & Lawsen (2025)

---

*This paper represents a paradigm shift in AI scaling: instead of building ever-larger foundation models, we can achieve superintelligent behavior by "smashing intelligence into a million pieces" through massively decomposed agentic processes. The mathematical rigor, empirical validation, and practical cost analysis make this immediately applicable to production systems requiring extreme reliability.*

