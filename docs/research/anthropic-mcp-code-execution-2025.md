---
title: "Code Execution with MCP: Building More Efficient Agents"
type: research
category: research
paper_type: technical-blog
purpose: "Demonstrates how code execution environments can dramatically reduce token consumption and improve agent efficiency when working with Model Context Protocol (MCP) servers"
audience: [Product Managers, Engineers, ML Engineers, AI Architects]
date_created: 2025-11-23
last_updated: 2025-11-23
tags: [mcp, agents, code-execution, tool-use, context-efficiency, token-optimization, model-context-protocol]

# Publication metadata
authors: "Adam Jones, Conor Kelly (Anthropic Engineering)"
institution: "Anthropic"
publication_date: "2025-11-04"
publication_venue: "Anthropic Engineering Blog"
paper_url: "https://www.anthropic.com/engineering/code-execution-with-mcp"

# Product relevance
domains: [ai-agents, tool-integration, context-optimization, system-architecture]
potential_applications: [agent-platforms, workflow-automation, data-processing, multi-tool-orchestration]
implementation_complexity: medium
---

# Code Execution with MCP: Building More Efficient Agents

## Executive Summary

As MCP (Model Context Protocol) adoption scales to hundreds or thousands of connected tools, traditional approaches that load all tool definitions into context and pass intermediate results through the model become prohibitively expensive. This blog post from Anthropic Engineering introduces a pattern where agents write code to interact with MCP servers rather than calling tools directly, reducing token consumption by up to 98.7% in some scenarios.

The key insight: present MCP servers as code APIs that agents can discover through filesystem exploration. Instead of loading 150,000 tokens of tool definitions upfront, agents can read only the specific tools they need (reducing to ~2,000 tokens). Intermediate data processing happens in the code execution environment rather than flowing through the model's context window, saving tokens and preventing context overflow with large datasets.

This matters for product development because it enables a new generation of highly-connected agents that can orchestrate complex workflows across many systems efficiently. The pattern also provides privacy benefits (sensitive data stays in execution environment) and enables state persistence and reusable "skills."

## Research Context

### Problem Statement

MCP has been rapidly adopted since launching in November 2024—thousands of MCP servers exist, and developers routinely build agents with access to hundreds or thousands of tools. However, two patterns emerge that increase cost and latency at scale:

1. **Tool definitions overload the context window**: Loading all tool definitions upfront can consume hundreds of thousands of tokens before the agent even starts working
2. **Intermediate tool results consume additional tokens**: When data must pass through the model between tool calls (e.g., fetching a document and attaching it elsewhere), large datasets may flow through context multiple times

These challenges make traditional direct tool-calling approaches inefficient as agents connect to more MCP servers.

### Research Questions

- How can agents efficiently work with hundreds or thousands of connected tools without loading all definitions upfront?
- Can intermediate data processing happen outside the model's context to reduce token consumption?
- What architectural patterns enable agents to scale to many MCP servers while minimizing costs?
- How does code execution change the security, privacy, and state management characteristics of agent systems?

## Methodology

### Approach

The blog post proposes representing MCP servers as code APIs that agents can explore through filesystem operations. Rather than exposing tools via direct tool-calling syntax, the system generates a file tree where each MCP server becomes a directory and each tool becomes a TypeScript file with type definitions.

**Key architectural shift:**
- Traditional: `TOOL CALL: gdrive.getDocument(documentId: "abc123")` → result flows through context
- Code execution: Agent writes code importing and calling tools, with results staying in execution environment

### Key Components

**Filesystem-Based Tool Discovery:**
```
servers/
├── google-drive/
│   ├── getDocument.ts
│   ├── ... (other tools)
│   └── index.ts
├── salesforce/
│   ├── updateRecord.ts
│   └── index.ts
```

Each tool file contains:
- Type definitions for inputs/outputs
- JSDoc comments describing functionality
- An async function that calls `callMCPTool()` under the hood

**Progressive Disclosure:**
Agents discover tools by:
1. Listing `./servers/` directory to find available servers
2. Reading specific tool files they need for the task
3. Loading only relevant type definitions into context

**Alternative: Search-Based Discovery:**
Some implementations add a `search_tools` function that allows agents to query for relevant tools by keyword rather than navigating the filesystem.

### Implementation Patterns

**Token Reduction Example:**
- Traditional approach: Load all 500 tool definitions = 150,000 tokens
- Code execution approach: List servers + read 2-3 specific tools = 2,000 tokens
- **Reduction: 98.7%**

**Context-Efficient Data Flow:**
```typescript
// Read transcript from Google Docs and add to Salesforce prospect
import * as gdrive from './servers/google-drive';
import * as salesforce from './servers/salesforce';

const transcript = (await gdrive.getDocument({ documentId: 'abc123' })).content;
await salesforce.updateRecord({
  objectType: 'SalesMeeting',
  recordId: '00Q5f000001abcXYZ',
  data: { Notes: transcript }
});
```

The full transcript never flows through the model's context—it moves directly from Google Drive to Salesforce through variables in the execution environment.

## Key Findings

### Primary Results

**Dramatic Token Reduction:**
- 98.7% reduction in tokens for tool definitions (150K → 2K tokens)
- Large datasets (10,000-row spreadsheets, long transcripts) no longer need to flow through model context
- Agents can filter/transform data in code before returning results

**Scalability Improvements:**
- Agents can now efficiently work with hundreds or thousands of connected tools
- Only tool definitions actually needed for the task consume context
- Intermediate processing happens in O(1) context rather than O(data size)

**Performance Characteristics:**
- Reduced "time to first token" latency—control flow executed in environment rather than through model
- Complex loops, conditionals, and error handling handled by code rather than agent message loop
- Single code block can orchestrate multi-step workflows

### Supporting Findings

**Privacy & Security Benefits:**
- Intermediate data stays in execution environment by default
- Only explicitly logged or returned data flows through model context
- Enables PII tokenization: MCP client can intercept and tokenize sensitive data before model sees it
- Real data flows between tools while model only sees `[EMAIL_1]`, `[PHONE_1]` tokens

**State Persistence:**
- Agents can write intermediate results to filesystem
- Enables resumable workflows and progress tracking
- Supports building reusable "skills" - saved code functions the agent can invoke later

**Cloudflare Validation:**
- Cloudflare independently published similar findings, calling this "Code Mode"
- Core insight identical: leverage LLMs' code-writing strengths for efficient tool orchestration

## Practical Implications

### For Product Development

**Agent Platform Architecture:**
- Consider code execution as first-class capability for agent systems
- Enables "highly-connected agent" product experiences without prohibitive costs
- Opens up use cases requiring orchestration across many systems simultaneously

**Cost Management:**
- Makes previously expensive workflows economically viable
- Particularly impactful for data-intensive workflows (document processing, spreadsheet analysis)
- Enables agents to work with larger datasets without hitting context limits

**Privacy-Preserving Workflows:**
- Agent can orchestrate data flows between systems without seeing sensitive contents
- Enables compliance-friendly implementations (HIPAA, GDPR, etc.)
- Deterministic security rules about which systems can exchange data

### For Engineering

**Implementation Requirements:**
- Secure code execution environment with sandboxing, resource limits, and monitoring
- Filesystem for tool discovery and state persistence
- MCP client that can generate code API wrappers from MCP tool definitions
- Infrastructure for monitoring code execution, errors, and security

**Architectural Trade-offs:**
- **Pros**: Massive token savings, better data handling, state persistence, privacy benefits
- **Cons**: Added complexity of code execution infrastructure, security considerations, operational overhead
- Decision should weigh benefits against implementation costs for specific use cases

**Code Generation Considerations:**
- TypeScript recommended for type safety and tooling
- Need robust error handling in generated wrapper functions
- Consider how to handle streaming responses, pagination, rate limits

**Security Considerations:**
- Code execution introduces new attack surface
- Requires careful sandboxing and resource limits
- Need monitoring for malicious or inefficient code patterns
- Consider timeout mechanisms and execution budgets

### For Decision Making

**When to Use Code Execution with MCP:**
- Agents connecting to many (10+) MCP servers
- Workflows involving large data transfers between systems
- Privacy-sensitive applications where data minimization is important
- Complex orchestration requiring loops, conditionals, error handling
- Applications where state persistence or resumability is valuable

**When Direct Tool Calling Suffices:**
- Simple agents with few (1-5) tools
- Workflows where all data should flow through model for reasoning
- Applications without secure code execution infrastructure
- Cases where simplicity outweighs efficiency gains

**Strategic Insights:**
- Code execution is becoming table-stakes for production agent systems
- "Agent writes code to call tools" is more scalable than "agent calls tools directly"
- Aligns with broader industry trend toward code-based agent architectures
- Early investment in code execution infrastructure enables future capabilities (skills, state, privacy)

## Key Learnings & Takeaways

1. **Progressive disclosure is critical at scale**: Loading all tool definitions upfront doesn't scale to hundreds of tools; agents should discover tools on-demand through filesystem navigation or search

2. **Intermediate results are expensive**: Large datasets flowing through model context multiple times can dominate costs; keeping data in execution environment saves tokens

3. **98.7% token reduction possible**: Real-world example showed 150K → 2K token reduction by loading only needed tools rather than all upfront

4. **LLMs excel at writing code**: Leverage this strength—agents writing code to orchestrate tools is more efficient than direct tool calling at scale

5. **Privacy through isolation**: Execution environment provides natural privacy boundary; data can flow between tools without entering model context

6. **State enables resumability**: Filesystem access allows agents to persist intermediate results and resume interrupted workflows

7. **Skills as code**: Agents can save working implementations as reusable functions, building up capabilities over time

8. **Control flow efficiency**: Loops, conditionals, and error handling execute immediately in code rather than through multi-turn agent conversations

9. **Infrastructure investment required**: Code execution adds complexity (sandboxing, monitoring, security) that must be weighed against benefits

10. **Industry convergence**: Multiple organizations (Anthropic, Cloudflare) independently arriving at same pattern suggests fundamental scaling law

## Connections & Related Work

### Related Research

**Model Context Protocol (MCP):**
- MCP launched November 2024 as open standard for connecting AI agents to external systems
- Thousands of MCP servers built by community
- SDKs available for all major programming languages
- Becoming de-facto standard for agent-tool integration

**Code Execution for Agents:**
- Cloudflare's "Code Mode" - independent validation of same approach
- Industry trend toward code-based agent architectures
- Relates to broader "agentic coding" movement

**Context Window Optimization:**
- Long-standing challenge: tool definitions consume valuable context
- Related to work on selective tool exposure, tool retrieval, dynamic prompting
- Code execution offers architectural solution vs prompt engineering approach

**Agent Scaling:**
- Complements "massively decomposed agentic processes" research
- Both address how to scale agents beyond single-model limitations
- Code execution handles tool scalability, MDAP handles step scalability

### Relevant to Our Work

**Internal Connections:**
- Agent platform development should consider code execution as core capability
- Workflow automation systems can benefit from code-based tool orchestration
- Data pipeline orchestration with agent oversight
- Privacy/compliance features enabled by execution environment isolation

**Product Areas That Could Benefit:**
- **Multi-system integrations**: Workflows spanning many tools (CRM, docs, communication, etc.)
- **Data processing**: Large dataset manipulation with agent oversight
- **Document workflows**: Extract from one system, transform, load to another
- **Automation platforms**: Users building complex automations across many services
- **Compliance workflows**: Privacy-preserving data flows between systems

**Architecture Implications:**
- Consider code execution sandbox as infrastructure primitive
- MCP client should support both direct tool calling and code API generation
- Monitoring/observability for code execution patterns
- Security reviews for sandboxing implementation
- Cost modeling: compare direct tool calling vs code execution for different workflow types

## Further Reading

**In the Blog Post:**
- Code examples showing progressive disclosure pattern
- Token consumption comparison (150K → 2K)
- Privacy-preserving tokenization example
- Skills/state persistence patterns
- Security and complexity trade-offs discussion

**Beyond the Blog Post:**

**MCP Resources:**
- Model Context Protocol specification
- MCP server examples and community implementations
- MCP SDKs for TypeScript, Python, and other languages

**Related Anthropic Content:**
- Claude and code execution capabilities
- Agent frameworks and best practices
- Context window optimization techniques

**Alternative Implementations:**
- Cloudflare's "Code Mode" blog post
- Other agent frameworks adopting code-based tool orchestration
- Open-source implementations of MCP with code execution

**Broader Context:**
- LLM code generation capabilities and benchmarks
- Secure code execution environments (containers, VMs, sandboxes)
- Agent orchestration patterns and frameworks
- Tool-use scaling challenges and solutions

---

*This blog post represents an important architectural pattern for production agent systems. As MCP adoption grows and agents connect to more tools, code execution becomes essential for managing token costs and enabling complex data workflows. The 98.7% token reduction and privacy benefits make this approach compelling despite added infrastructure complexity.*

