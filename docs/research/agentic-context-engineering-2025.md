---
title: "Agentic Context Engineering: Evolving Contexts for Self-Improving Language Models"
type: research
category: research
paper_type: academic
purpose: "Enable LLMs to build comprehensive, evolving knowledge bases that improve through experience without weight updates"
audience: [Product Managers, Engineers, ML Engineers, Data Scientists]
date_created: 2025-12-08
last_updated: 2025-12-08
tags: [llm, agents, context-optimization, prompt-engineering, self-improvement, memory, reasoning, financial-analysis, domain-adaptation]

# Paper metadata
authors: "Qizheng Zhang, Changran Hu, Shubhangi Upasani, Boyuan Ma, Fenglu Hong, Vamsidhar Kamanuru, Jay Rainton, Chen Wu, Mengmeng Ji, Hanchen Li, Urmish Thakker, James Zou, Kunle Olukotun"
institution: "Stanford University, SambaNova Systems, UC Berkeley"
publication_date: "2025"
publication_venue: "Preprint"
arxiv_id: "TBD"
doi: "TBD"
paper_url: "./raw/AgenticContextEngineering.pdf"

# Product relevance
domains: [llm-agents, context-optimization, financial-analysis, memory-systems, self-improving-ai]
potential_applications: [agent-memory, system-prompt-optimization, domain-specific-reasoning, financial-qa, tool-use-improvement, autonomous-learning]
implementation_complexity: medium
---

# Agentic Context Engineering: Evolving Contexts for Self-Improving Language Models

## Executive Summary

Modern LLM applications increasingly rely on **context adaptation**—improving behavior by modifying inputs rather than model weights. However, existing approaches suffer from two critical flaws: **brevity bias** (optimizing for concise prompts that lose domain-specific details) and **context collapse** (iterative rewriting that degrades information over time).

This paper introduces **ACE (Agentic Context Engineering)**, a framework that treats contexts as evolving "playbooks" that accumulate, refine, and organize strategies through modular generation, reflection, and curation. Rather than compressing knowledge into summaries, ACE preserves comprehensive, detailed contexts that scale with long-context models.

**Results are compelling**: ACE achieves **+10.6% improvement on agent benchmarks** and **+8.6% on financial analysis tasks**, while reducing adaptation latency by **86.9%** and significantly cutting deployment costs. On the AppWorld leaderboard, ACE matches the top-ranked production agent (powered by GPT-4) despite using a smaller open-source model (DeepSeek-V3). Critically, ACE learns effectively **without labeled supervision**, leveraging only execution feedback—a key ingredient for self-improving AI systems.

For product development, this represents a paradigm shift: instead of fine-tuning models for every domain, we can build systems that construct and maintain rich knowledge bases that improve through use.

## Research Context

### Problem Statement

LLM applications like agents and domain-specific reasoning systems depend on high-quality contexts (system prompts, memory, instructions). Current optimization methods face two problems:

1. **Brevity Bias**: Optimization gravitates toward short, generic prompts that omit crucial domain-specific heuristics, tool guidelines, and common failure modes. This works for simple benchmarks but fails in complex real-world applications.

2. **Context Collapse**: Iterative rewriting by LLMs degrades contexts into shorter, less informative summaries over time, causing sharp performance declines. The researchers documented drops from 70% to 36% accuracy after just a few iterations.

These limitations are increasingly problematic as applications demand greater reliability and long-context models make comprehensive contexts practical.

### Research Questions

- How can we build context optimization methods that accumulate knowledge rather than compress it?
- Can structured, modular updates prevent context collapse while maintaining interpretability?
- Can contexts improve through execution feedback alone, without labeled training data?
- How do comprehensive contexts perform across diverse applications (agents, domain reasoning)?

## Methodology

### Approach

ACE builds on the "agentic architecture" introduced in Dynamic Cheatsheet, expanding it with a **grow-and-refine principle** that prevents collapse through structured, incremental updates. The system operates through three modular components:

1. **Generator**: Uses the current playbook to solve tasks, explicitly tracking which playbook items were consulted
2. **Reflector**: Analyzes successes and failures to identify what went wrong and what strategies helped
3. **Curator**: Synthesizes reflections into structured playbook updates (additions, modifications, deletions)

Key innovation: Instead of monolithic rewriting, ACE uses **structured JSON operations** that specify exactly what to add/modify/remove, preserving detailed knowledge while organizing it into coherent sections.

### Key Components

**Playbook Structure:**
- Organized into domain-specific sections (e.g., for agents: "verification_checklist", "apis_to_use", "strategies_and_hard_rules")
- Each item has a unique ID and tracks usage statistics (helpful/harmful/neutral tags)
- Supports both offline optimization (system prompts) and online adaptation (test-time memory)

**Training Process:**
- Works on both supervised (with ground truth) and unsupervised (execution feedback only) settings
- Uses token budgets to control playbook growth and prevent unbounded expansion
- Implements sampling strategies to ensure diverse coverage of scenarios

**Evaluation Setup:**
- **Agent Benchmarks**: AppWorld (250+ real-world API tasks), SWE-bench Verified (software engineering tasks), WebArena (web navigation)
- **Domain Benchmarks**: FINER-bench (financial analysis with 3,000+ QA pairs), FinanceBench (earnings reports analysis)
- **Baselines**: Compared against GEPA (gradient-like prompt optimization), Reflexion (self-reflection), TextGrad, Dynamic Cheatsheet, and vanilla prompting

**Models Tested:**
- Primarily DeepSeek-V3 (685B parameters, open-source)
- Also validated on GPT-4.1, Claude Sonnet 4, and Claude Opus 4

## Key Findings

### Primary Results

**Agent Performance (Average across AppWorld, SWE-bench, WebArena):**
- ACE: **+10.6% improvement** over best baseline
- AppWorld specifically: **47.2% success rate** (ACE) vs. 42.6% (GEPA baseline)
- On AppWorld test-challenge split: **Surpasses top-ranked production agent** (IBM-CUGA powered by GPT-4.1)
- Overall AppWorld leaderboard: **Matches #1 ranked agent** while using smaller open-source model

**Financial Analysis Performance:**
- FINER-bench: **67.8% accuracy** (ACE) vs. 62.5% (best baseline) = **+8.5% improvement**
- FinanceBench: **70.1% vs. 64.8%** = **+8.2% improvement**
- Average domain improvement: **+8.6%**

**Efficiency Gains:**
- **86.9% lower adaptation latency** compared to existing methods
- Significantly fewer rollouts required (100-200 vs. 1000+ for some baselines)
- Lower dollar costs due to reduced inference requirements

**Unsupervised Learning:**
- ACE without labeled supervision achieves **91-96% of fully supervised performance**
- Demonstrates practical self-improvement using only execution feedback

### Supporting Findings

**Ablation Studies:**
- Removing structured operations → **-8.7% performance drop**
- Removing reflection module → **-6.3% drop**
- Monolithic rewriting (like TextGrad) → context collapse and **-12.4% drop**

**Context Length Scaling:**
- Performance continues improving as playbooks grow to 10,000+ tokens
- No degradation observed with long contexts (validates design assumption)

**Cross-Model Validation:**
- Playbooks trained on DeepSeek-V3 transfer reasonably well to GPT-4.1 and Claude models
- Best results when optimization model matches deployment model

**Context Collapse Evidence:**
- Baseline methods show **34% performance drop** after 5 iterations
- ACE maintains stable or improving performance through 20+ iterations

## Practical Implications

### For Product Development

**Build Domain-Specific AI Systems Without Fine-Tuning:**
- Instead of expensive fine-tuning for each domain, ACE can build specialized knowledge bases through experience
- Particularly valuable for rapidly evolving domains (finance, legal, customer support) where retraining is impractical
- Enables "learning by doing" - systems improve as they handle real tasks

**Immediate Applications:**
- **Customer support agents**: Build knowledge bases of successful resolution strategies, common pitfalls, API usage patterns
- **Financial analysis tools**: Accumulate calculation methods, regulatory nuances, industry-specific heuristics
- **Code generation assistants**: Collect debugging strategies, library usage patterns, common error fixes
- **Research assistants**: Build domain-specific reasoning strategies and evidence evaluation criteria

**Product Design Considerations:**
- Users can inspect and edit playbooks (full interpretability)
- Playbooks can be shared across teams or fine-tuned for specific use cases
- Natural integration point for human feedback and expertise injection

### For Engineering

**Implementation Requirements:**
- Requires long-context model support (10K+ tokens)
- Benefits from KV cache reuse for efficient inference
- Modular architecture allows independent optimization of generator/reflector/curator
- JSON-based operation format enables programmatic validation and version control

**Technical Advantages:**
- **No weight updates needed**: Faster iteration cycles, easier rollback, simpler deployment
- **Model-agnostic**: Works across GPT, Claude, DeepSeek, and other instruction-following models
- **Scalable**: Token budgets control growth; playbooks can be pruned based on utility metrics

**Integration Patterns:**
- **Offline mode**: Optimize system prompts before deployment (like prompt engineering but automated)
- **Online mode**: Maintain evolving memory during inference (like RAG but learned, not retrieved)
- **Hybrid mode**: Start with offline-optimized playbook, continue adapting during deployment

**Challenges:**
- Managing playbook versioning and updates in production
- Monitoring playbook quality and detecting degradation
- Handling multi-tenancy (shared vs. personalized playbooks)

### For Decision Making

**Strategic Insights:**
- **Context optimization > model size**: ACE with DeepSeek-V3 matches GPT-4.1 on several benchmarks
- **Self-improvement is practical**: 91-96% of supervised performance without labels opens new product possibilities
- **Long contexts are assets, not liabilities**: Comprehensive playbooks outperform concise summaries

**Prioritization Considerations:**
- Highest value for: complex multi-step tasks, domain-specific reasoning, tool-heavy workflows
- Lower value for: simple Q&A, creative writing, tasks requiring general knowledge only
- Best ROI: Applications where domain expertise is costly or rapidly evolving

**Risk Factors:**
- Playbook quality depends on feedback quality (garbage in, garbage out)
- May accumulate outdated strategies if not periodically reviewed
- Potential for "playbook bloat" without proper curation
- Security considerations: playbooks could leak sensitive information if not properly managed

## Key Learnings & Takeaways

1. **Comprehensive > Concise**: LLMs perform better with detailed, extensive contexts than compressed summaries. The "brevity bias" in optimization is a bug, not a feature.

2. **Context Collapse is Real**: Iterative monolithic rewriting degrades performance by 34% after just 5 iterations. Structured, incremental updates are essential.

3. **Self-Improvement Without Labels**: ACE achieves 91-96% of supervised performance using only execution feedback, demonstrating practical autonomous learning.

4. **Efficiency Gains are Massive**: 86.9% lower adaptation latency and significantly reduced costs while improving accuracy. This is not a speed-accuracy tradeoff.

5. **Small Model + Good Context > Big Model Alone**: DeepSeek-V3 with ACE matches/beats GPT-4.1 production systems, suggesting context optimization may be more valuable than model scaling.

6. **Modular Architecture Matters**: Separating generation, reflection, and curation enables interpretability, debugging, and independent optimization of each component.

7. **Token Budgets Enable Control**: Simple token-based constraints prevent unbounded growth while allowing rich knowledge accumulation.

8. **Playbooks Transfer (Somewhat)**: Contexts optimized on one model provide gains on others, though best performance requires matching optimization and deployment models.

9. **Long Context is a Feature**: Performance scales positively with playbook length up to 10K+ tokens, validating the "comprehensive playbook" philosophy.

10. **Structure Prevents Collapse**: JSON-based operations (+8.7% vs. unstructured) enable precise updates while maintaining coherence over many iterations.

## Connections & Related Work

### Related Research

**Prompt Optimization:**
- GEPA (gradient-like prompt optimization): Current SOTA that ACE outperforms
- TextGrad: Textual gradients for optimization (suffers from context collapse)
- DSPy: Framework for composing LM calls (complementary to ACE's approach)

**Agent Memory Systems:**
- Dynamic Cheatsheet: ACE's foundation (provides agentic architecture)
- Reflexion: Self-reflection for agents (simpler, less structured than ACE)
- MemGPT: Memory management for conversational agents
- Generative Agents: Social memory for game-playing agents

**Context Understanding:**
- Lost in the Middle: Long context attention patterns (motivates ACE's structured approach)
- Many-shot Learning: Benefits of extensive in-context examples (supports comprehensive playbooks)

**Domain-Specific Applications:**
- FinGPT: Fine-tuned models for finance (ACE offers alternative without fine-tuning)
- Code generation agents: GitHub Copilot, Devin (could benefit from ACE's strategy accumulation)

### Relevant to Our Work

**Spruce Data Central MCP Server:**
- ACE's playbook architecture could enhance our tool usage patterns
- Reflection module could identify common API misuse patterns
- Curator could build domain-specific guidelines for Jira/Confluence operations
- Potential integration: Maintain evolving "best practices" playbooks for each tool

**Product Planning Context:**
- Demonstrates value of comprehensive, structured knowledge bases vs. compressed summaries
- Validation that self-improvement through execution feedback is production-ready
- Shows smaller models + good contexts can match larger models (cost implications)

**Potential Applications:**
- **Agent for requirement gathering**: Build playbook of effective question patterns, domain terminology, common ambiguities
- **Code review assistant**: Accumulate team-specific patterns, common bugs, style preferences
- **Customer interaction analysis**: Learn successful conversation patterns, resolution strategies
- **Financial modeling tools**: Build domain-specific calculation libraries and validation rules

**Implementation Considerations:**
- Could adapt ACE framework for Spruce-specific use cases
- JSON-based operations align well with our structured data preferences
- Token budget approach compatible with cost-conscious deployment
- Modular architecture fits our service-oriented patterns

## Further Reading

**In the Paper:**
- **Section 3**: Detailed ACE architecture and algorithm
- **Section 4**: Comprehensive experimental results across all benchmarks
- **Section 5**: Ablation studies and analysis of what makes ACE work
- **Figure 2**: Visualization of context collapse in baseline methods
- **Figure 11-14**: Full prompt templates for Generator, Reflector, and Curator (Appendix)
- **Table 1**: Complete performance comparison across all benchmarks and baselines

**Beyond the Paper:**
- Dynamic Cheatsheet paper: Foundation for ACE's agentic architecture
- GEPA paper: Current SOTA baseline that ACE improves upon
- AppWorld benchmark: Real-world agent evaluation environment
- Long context LLM papers: Context window advances enabling comprehensive playbooks
- DSPy framework: Complementary approach to LM program composition

**Code & Resources:**
- Authors mention code will be released (check paper URL for updates)
- AppWorld leaderboard: Track ACE's ranking against production systems
- Consider experimenting with simplified version on internal use cases

---

**Summary for Quick Reference:**
ACE enables LLMs to build and maintain comprehensive, evolving knowledge bases that improve through experience without weight updates. It solves the "brevity bias" and "context collapse" problems in prompt optimization, achieving +10.6% gains on agents and +8.6% on financial tasks while cutting latency by 87%. The key insight: give LLMs detailed playbooks, not compressed summaries—they can figure out what's relevant.

