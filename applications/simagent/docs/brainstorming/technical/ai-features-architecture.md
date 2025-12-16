# AI Features Technical Architecture

**Last Updated:** December 14, 2025  
**Scope:** Complete 4-phase AI evolution architecture  
**Focus:** How AI intelligence layer integrates with Maestro execution foundation

---

## Architectural Philosophy

### Core Principle: Separation of Concerns

```
┌─────────────────────────────────────────┐
│     EXECUTION LAYER (Maestro)           │  ← Table Stakes (proven, reliable)
│  - Runs tests                           │
│  - Controls simulator                   │
│  - Captures screenshots                 │
│  - Reports pass/fail                    │
└────────────────┬────────────────────────┘
                 │
                 │ Test results, screenshots, logs
                 │
                 ▼
┌─────────────────────────────────────────┐
│    AI INTELLIGENCE LAYER (Our Moat)     │  ← Differentiation
│  - Analyzes failures                    │
│  - Suggests tests                       │
│  - Interprets natural language          │
│  - Multi-agent consensus                │
└─────────────────────────────────────────┘
```

**Why this matters:**
- Maestro can be replaced later without affecting AI features
- AI features work with any test execution engine
- Clear value proposition: AI intelligence, not test runner

---

## System Architecture Overview

### High-Level Components

```
┌─────────────────────────────────────────────────────────────┐
│                    USER INTERFACE                           │
│                                                             │
│  ┌────────────┐  ┌──────────────┐  ┌────────────────┐       │
│  │ macOS App  │  │     CLI      │  │  Web Dashboard │       │
│  │ (SwiftUI)  │  │  (Python)    │  │   (React)      │       │
│  └─────┬──────┘  └───────┬──────┘  └────────┬───────┘       │
└────────┼─────────────────┼──────────────────┼───────────────┘
         │                 │                  │
         └─────────────────┼──────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                     API GATEWAY                             │
│  - Authentication                                           │
│  - Rate limiting                                            │
│  - Request routing                                          │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
┌──────────┐ ┌──────────────┐ ┌──────────────┐
│   Test   │ │      AI      │ │   Playbook   │
│ Execution│ │   Services   │ │   Service    │
│  Service │ │              │ │   (ACE)      │
└─────┬────┘ └──────┬───────┘ └──────┬───────┘
      │             │                │
      │             │                │
      ▼             ▼                ▼
┌────────────────────────────────────────────────────────────────┐
│                    DATA LAYER                                  │
│                                                                │
│  ┌────────────┐  ┌──────────┐  ┌────────────┐  ┌────────────┐  │
│  │PostgreSQL  │  │  Redis   │  │    S3      │  │ Vector     │  │
│  │(tests,     │  │(cache,   │  │(screenshots│  │   DB       │  │
│  │ playbooks) │  │ sessions)│  │  videos)   │  │(embeddings)│  │
│  └────────────┘  └──────────┘  └────────────┘  └────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: AI Error Analysis Architecture

### Service Design

```python
# failure_analyzer_service.py

class FailureAnalyzerService:
    """
    Phase 1: Analyzes test failures with AI
    Triggered only when tests fail (cost-efficient)
    """
    
    def __init__(
        self,
        vision_api: VisionAPIClient,
        cache: RedisCache,
        db: PostgreSQL
    ):
        self.vision_api = vision_api
        self.cache = cache
        self.db = db
    
    async def analyze_failure(
        self,
        test_id: UUID,
        failure_data: FailureData
    ) -> FailureReport:
        """
        Main entry point for failure analysis
        """
        
        # Step 1: Check cache (avoid duplicate analysis)
        cache_key = self._compute_cache_key(failure_data)
        if cached := await self.cache.get(cache_key):
            return cached
        
        # Step 2: Extract context
        context = await self._gather_context(failure_data)
        
        # Step 3: Parallel analysis
        results = await asyncio.gather(
            self._analyze_visual_state(context),
            self._analyze_logs(context),
            self._check_known_issues(context)
        )
        
        visual_analysis, log_analysis, known_issues = results
        
        # Step 4: Generate comprehensive report
        report = await self._generate_report(
            visual=visual_analysis,
            logs=log_analysis,
            known=known_issues,
            context=context
        )
        
        # Step 5: Cache and store
        await self.cache.set(cache_key, report, ttl=3600)
        await self.db.store_analysis(test_id, report)
        
        return report
```

### API Integration Pattern

```python
# vision_api_client.py

class VisionAPIClient:
    """
    Wrapper for GPT-4 Vision API with retry logic
    """
    
    def __init__(self, api_key: str, backup_provider: Optional[str] = None):
        self.primary = OpenAIClient(api_key)
        self.backup = AnthropicClient() if backup_provider == "anthropic" else None
    
    async def analyze_screenshot(
        self,
        image: bytes,
        prompt: str,
        max_retries: int = 3
    ) -> AnalysisResult:
        """
        Call vision API with fallback and retry
        """
        
        for attempt in range(max_retries):
            try:
                # Try primary provider (OpenAI)
                result = await self.primary.vision_analyze(
                    image=image,
                    prompt=prompt,
                    model="gpt-4-vision-preview"
                )
                return self._parse_result(result)
                
            except RateLimitError:
                if self.backup and attempt == max_retries - 1:
                    # Fall back to Anthropic
                    return await self.backup.vision_analyze(image, prompt)
                await asyncio.sleep(2 ** attempt)  # Exponential backoff
                
            except Exception as e:
                if attempt == max_retries - 1:
                    raise
                await asyncio.sleep(1)
        
        raise APIError("Failed after all retries")
```

---

## Phase 2: ACE Playbook Architecture

### Playbook Data Model

```sql
-- playbooks.sql

-- Global playbook (shared patterns)
CREATE TABLE global_playbook_patterns (
    id UUID PRIMARY KEY,
    category TEXT NOT NULL,  -- 'login', 'checkout', 'navigation', etc.
    pattern_name TEXT NOT NULL,
    description TEXT,
    trigger_conditions JSONB,  -- When to suggest this pattern
    test_template JSONB,  -- Maestro YAML template
    confidence_score FLOAT DEFAULT 0.5,
    usage_count INTEGER DEFAULT 0,
    success_rate FLOAT DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Customer-specific playbook
CREATE TABLE customer_playbook_patterns (
    id UUID PRIMARY KEY,
    customer_id UUID NOT NULL,
    pattern_name TEXT NOT NULL,
    app_context JSONB,  -- App-specific details
    test_template JSONB,
    learned_from_tests UUID[],  -- Tests that contributed to this pattern
    confidence_score FLOAT DEFAULT 0.5,
    last_used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Pattern performance tracking
CREATE TABLE pattern_feedback (
    id UUID PRIMARY KEY,
    pattern_id UUID NOT NULL,
    customer_id UUID,
    test_id UUID,
    user_action TEXT,  -- 'accepted', 'rejected', 'modified'
    modification_details JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for fast lookups
CREATE INDEX idx_patterns_category ON global_playbook_patterns(category);
CREATE INDEX idx_customer_patterns ON customer_playbook_patterns(customer_id);
CREATE INDEX idx_pattern_feedback ON pattern_feedback(pattern_id, user_action);
```

### Pattern Learning Service

```python
# pattern_learning_service.py

class PatternLearningService:
    """
    Phase 2: Learns testing patterns from user behavior
    Implements ACE (Agentic Context Engineering) principles
    """
    
    def __init__(self, db: PostgreSQL, embeddings: VectorDB):
        self.db = db
        self.embeddings = embeddings
    
    async def learn_from_test(
        self,
        customer_id: UUID,
        test: Test,
        execution_result: TestResult
    ):
        """
        Extract patterns from successful tests
        """
        
        # Step 1: Extract test characteristics
        characteristics = self._extract_characteristics(test)
        
        # Step 2: Check if similar pattern exists
        similar = await self._find_similar_patterns(
            customer_id,
            characteristics
        )
        
        if similar:
            # Update existing pattern
            await self._update_pattern_confidence(similar, execution_result)
        else:
            # Create new pattern
            await self._create_new_pattern(customer_id, test, characteristics)
        
        # Step 3: Update embeddings for semantic search
        await self._update_embeddings(test)
    
    async def suggest_tests_for_screen(
        self,
        customer_id: UUID,
        screen_description: str,
        app_context: Dict
    ) -> List[TestSuggestion]:
        """
        Suggest tests based on screen description
        """
        
        # Step 1: Find relevant patterns (semantic search)
        relevant_patterns = await self._semantic_search(
            screen_description,
            app_context,
            limit=10
        )
        
        # Step 2: Get customer-specific patterns
        customer_patterns = await self.db.get_customer_patterns(
            customer_id,
            context=app_context
        )
        
        # Step 3: Merge and rank
        suggestions = self._rank_and_merge(
            global_patterns=relevant_patterns,
            customer_patterns=customer_patterns,
            context=app_context
        )
        
        return suggestions[:5]  # Top 5 suggestions
    
    def _extract_characteristics(self, test: Test) -> Dict:
        """
        Extract learnable features from test
        """
        return {
            "flow_type": self._classify_flow(test),  # login, checkout, etc.
            "assertions": [step.type for step in test.steps if step.is_assertion],
            "interactions": [step.type for step in test.steps if step.is_action],
            "error_handling": self._detect_error_cases(test),
            "edge_cases": self._detect_edge_cases(test),
        }
```

### Vector Search for Semantic Matching

```python
# embeddings_service.py

from sentence_transformers import SentenceTransformer

class EmbeddingsService:
    """
    Generate and search embeddings for semantic test matching
    """
    
    def __init__(self, model_name: str = "all-MiniLM-L6-v2"):
        self.model = SentenceTransformer(model_name)
        self.vector_db = PineconeClient()  # or Weaviate, Qdrant
    
    async def embed_test(self, test: Test) -> np.ndarray:
        """
        Generate embedding for test
        """
        # Combine test name, description, and steps
        text = f"""
        {test.name}
        {test.description}
        Steps: {', '.join([step.description for step in test.steps])}
        """
        
        embedding = self.model.encode(text)
        return embedding
    
    async def find_similar_tests(
        self,
        query: str,
        customer_id: Optional[UUID] = None,
        limit: int = 10
    ) -> List[Tuple[Test, float]]:
        """
        Find tests similar to query using semantic search
        """
        # Generate query embedding
        query_embedding = self.model.encode(query)
        
        # Search vector DB
        results = await self.vector_db.search(
            vector=query_embedding,
            filter={"customer_id": customer_id} if customer_id else None,
            limit=limit
        )
        
        return [(result.test, result.score) for result in results]
```

---

## Phase 3: Natural Language Interpretation Architecture

### Conversation State Management

```python
# nl_interpreter_service.py

class NLInterpreterService:
    """
    Phase 3: Converts natural language to Maestro YAML
    Uses multi-turn conversation to refine ambiguous input
    """
    
    def __init__(
        self,
        llm_client: LLMClient,
        playbook_service: PatternLearningService,
        yaml_validator: YAMLValidator
    ):
        self.llm = llm_client
        self.playbooks = playbook_service
        self.validator = yaml_validator
    
    async def interpret_nl_input(
        self,
        customer_id: UUID,
        nl_input: str,
        conversation_history: Optional[List[Message]] = None,
        app_context: Optional[Dict] = None
    ) -> InterpretationResult:
        """
        Main entry point for NL interpretation
        """
        
        # Step 1: Load relevant playbooks for context
        playbook_context = await self.playbooks.get_relevant_context(
            customer_id,
            nl_input
        )
        
        # Step 2: Build prompt with ACE playbook context
        prompt = self._build_interpretation_prompt(
            nl_input=nl_input,
            playbook_context=playbook_context,
            conversation_history=conversation_history,
            app_context=app_context
        )
        
        # Step 3: LLM interprets intent
        interpretation = await self.llm.chat_completion(
            messages=prompt,
            temperature=0.3,  # Lower = more deterministic
            response_format="json"
        )
        
        # Step 4: Check for ambiguity
        if interpretation.confidence < 0.8:
            # Need clarification
            questions = self._generate_clarifying_questions(interpretation)
            return InterpretationResult(
                status="needs_clarification",
                questions=questions,
                partial_interpretation=interpretation
            )
        
        # Step 5: Generate YAML
        yaml_test = self._generate_yaml(interpretation, playbook_context)
        
        # Step 6: Validate
        validation = await self.validator.validate(yaml_test)
        if not validation.is_valid:
            return InterpretationResult(
                status="invalid_yaml",
                errors=validation.errors
            )
        
        # Step 7: Cache interpretation
        await self._cache_interpretation(
            nl_input=nl_input,
            yaml_output=yaml_test,
            context_hash=self._hash_context(app_context)
        )
        
        return InterpretationResult(
            status="success",
            yaml=yaml_test,
            explanation=interpretation.explanation
        )
```

### Deterministic Caching Strategy

```python
# interpretation_cache.py

class InterpretationCache:
    """
    Cache NL→YAML interpretations for determinism
    """
    
    def __init__(self, db: PostgreSQL, redis: RedisCache):
        self.db = db
        self.redis = redis
    
    async def get_cached_interpretation(
        self,
        nl_input: str,
        app_version: str,
        context_hash: str
    ) -> Optional[str]:
        """
        Retrieve cached interpretation if exists
        """
        
        # Compute cache key
        cache_key = self._compute_key(nl_input, app_version, context_hash)
        
        # Try Redis first (fast)
        if cached := await self.redis.get(cache_key):
            return cached
        
        # Fallback to DB
        cached = await self.db.query(
            """
            SELECT yaml_output 
            FROM interpretation_cache
            WHERE cache_key = $1
              AND created_at > NOW() - INTERVAL '30 days'
            ORDER BY usage_count DESC
            LIMIT 1
            """,
            cache_key
        )
        
        if cached:
            # Promote to Redis
            await self.redis.set(cache_key, cached.yaml_output, ttl=86400)
            return cached.yaml_output
        
        return None
    
    def _compute_key(self, nl_input: str, app_version: str, context_hash: str) -> str:
        """
        Generate deterministic cache key
        """
        # Normalize input (lowercase, remove extra whitespace)
        normalized = ' '.join(nl_input.lower().split())
        
        # Hash combination
        key_string = f"{normalized}:{app_version}:{context_hash}"
        return hashlib.sha256(key_string.encode()).hexdigest()
```

---

## Phase 4: Multi-Agent Consensus Architecture

### Agent System Design

```python
# multi_agent_system.py

class MultiAgentDebugSystem:
    """
    Phase 4: Multiple specialized agents analyze failures
    Consensus algorithm determines root cause
    """
    
    def __init__(
        self,
        ui_agent: UIAgent,
        log_agent: LogAgent,
        network_agent: NetworkAgent,
        consensus_engine: ConsensusEngine
    ):
        self.agents = {
            "ui": ui_agent,
            "log": log_agent,
            "network": network_agent
        }
        self.consensus = consensus_engine
    
    async def analyze_failure(
        self,
        failure_data: FailureData
    ) -> ConsensusReport:
        """
        Coordinate multi-agent analysis
        """
        
        # Step 1: Dispatch to all agents in parallel
        agent_tasks = [
            self.agents["ui"].analyze(failure_data),
            self.agents["log"].analyze(failure_data),
            self.agents["network"].analyze(failure_data)
        ]
        
        agent_results = await asyncio.gather(*agent_tasks)
        
        # Step 2: Run consensus algorithm
        consensus_result = await self.consensus.find_consensus(
            agent_results,
            failure_context=failure_data
        )
        
        # Step 3: Generate comprehensive report
        report = self._generate_multi_agent_report(
            agent_results=agent_results,
            consensus=consensus_result
        )
        
        return report


class UIAgent:
    """Specialized agent for visual/UI analysis"""
    
    async def analyze(self, failure_data: FailureData) -> AgentAnalysis:
        prompt = """
        You are a UI specialist analyzing an iOS app screenshot.
        Focus on:
        - Visual state (what's displayed)
        - UI elements presence/absence
        - Layout issues
        - Animation states
        - User-facing errors
        
        Screenshot: [image]
        Expected state: {failure_data.expected_state}
        
        Provide analysis with confidence score.
        """
        
        result = await self.vision_api.analyze(
            failure_data.screenshot,
            prompt
        )
        
        return AgentAnalysis(
            agent="ui",
            findings=result.findings,
            confidence=result.confidence,
            suggested_root_cause=result.root_cause
        )


class LogAgent:
    """Specialized agent for log analysis"""
    
    async def analyze(self, failure_data: FailureData) -> AgentAnalysis:
        prompt = """
        You are a debugging specialist analyzing iOS simulator logs.
        Focus on:
        - Error messages
        - Warning signs
        - Stack traces
        - Timing issues
        - Memory problems
        
        Logs: {failure_data.logs}
        
        Identify the most critical issues.
        """
        
        result = await self.llm.analyze(
            failure_data.logs,
            prompt
        )
        
        return AgentAnalysis(
            agent="log",
            findings=result.findings,
            confidence=result.confidence,
            suggested_root_cause=result.root_cause
        )


class NetworkAgent:
    """Specialized agent for network/API analysis"""
    
    async def analyze(self, failure_data: FailureData) -> AgentAnalysis:
        prompt = """
        You are a network specialist analyzing API calls.
        Focus on:
        - HTTP status codes
        - Response times
        - Timeout issues
        - Error responses
        - Request/response patterns
        
        Network data: {failure_data.network_logs}
        
        Identify API-related root causes.
        """
        
        result = await self.llm.analyze(
            failure_data.network_logs,
            prompt
        )
        
        return AgentAnalysis(
            agent="network",
            findings=result.findings,
            confidence=result.confidence,
            suggested_root_cause=result.root_cause
        )
```

### Consensus Algorithm (MAKER-Inspired)

```python
# consensus_engine.py

class ConsensusEngine:
    """
    Implements voting-based consensus similar to MAKER paper
    """
    
    def __init__(self, min_agreement: float = 0.67):
        self.min_agreement = min_agreement
    
    async def find_consensus(
        self,
        agent_results: List[AgentAnalysis],
        failure_context: FailureData
    ) -> ConsensusResult:
        """
        Determine consensus root cause across agents
        """
        
        # Step 1: Extract root cause candidates
        candidates = self._extract_candidates(agent_results)
        
        # Step 2: Compute agreement scores
        scores = {}
        for candidate in candidates:
            scores[candidate] = self._compute_agreement_score(
                candidate,
                agent_results
            )
        
        # Step 3: Find highest agreement
        best_candidate = max(scores.items(), key=lambda x: x[1])
        root_cause, agreement_score = best_candidate
        
        # Step 4: Check if consensus reached
        if agreement_score >= self.min_agreement:
            return ConsensusResult(
                status="consensus",
                root_cause=root_cause,
                confidence=agreement_score,
                supporting_agents=self._get_supporting_agents(root_cause, agent_results),
                dissenting_opinions=self._get_dissenting_opinions(root_cause, agent_results)
            )
        else:
            return ConsensusResult(
                status="no_consensus",
                candidates=scores,
                recommendation="Manual investigation needed"
            )
    
    def _compute_agreement_score(
        self,
        candidate: RootCause,
        agent_results: List[AgentAnalysis]
    ) -> float:
        """
        Calculate weighted agreement score
        Agent confidence weights their vote
        """
        
        total_weight = 0.0
        agreement_weight = 0.0
        
        for agent in agent_results:
            total_weight += agent.confidence
            
            if self._agents_agree(candidate, agent.suggested_root_cause):
                agreement_weight += agent.confidence
        
        return agreement_weight / total_weight if total_weight > 0 else 0.0
```

---

## Cost Management & Optimization

### Tiered AI Usage

```python
# cost_optimizer.py

class CostOptimizer:
    """
    Manages AI API costs across all phases
    """
    
    def __init__(self, budget: MonthlyBudget):
        self.budget = budget
        self.current_spend = 0.0
    
    async def should_use_ai(
        self,
        analysis_type: str,
        customer_tier: str,
        priority: int
    ) -> Tuple[bool, str]:
        """
        Decide whether to invoke AI based on budget and tier
        """
        
        if self.current_spend >= self.budget.hard_limit:
            return False, "budget_exceeded"
        
        # Free tier: No AI (or very limited)
        if customer_tier == "free":
            return False, "free_tier"
        
        # Pro tier: AI on failures only
        if customer_tier == "pro":
            if analysis_type in ["failure_analysis"]:
                return True, "approved"
            return False, "tier_restriction"
        
        # Team tier: AI authoring + failures
        if customer_tier == "team":
            if analysis_type in ["failure_analysis", "test_suggestions"]:
                return True, "approved"
            return False, "tier_restriction"
        
        # Enterprise: All AI features
        if customer_tier == "enterprise":
            return True, "approved"
        
        return False, "unknown_tier"
    
    async def track_cost(
        self,
        customer_id: UUID,
        analysis_type: str,
        cost: float
    ):
        """
        Track and attribute costs
        """
        self.current_spend += cost
        
        await self.db.record_cost(
            customer_id=customer_id,
            analysis_type=analysis_type,
            cost=cost,
            timestamp=datetime.now()
        )
        
        # Alert if approaching limit
        if self.current_spend > self.budget.soft_limit:
            await self._send_budget_alert()
```

---

## Observability & Monitoring

### Key Metrics to Track

```python
# metrics.py

class Metrics:
    """
    Track all AI feature performance metrics
    """
    
    # Phase 1: Error Analysis
    ERROR_ANALYSIS_LATENCY = Histogram("error_analysis_latency_seconds")
    ERROR_ANALYSIS_COST = Counter("error_analysis_cost_dollars")
    ERROR_ANALYSIS_ACCURACY = Gauge("error_analysis_accuracy_percent")
    CACHE_HIT_RATE = Gauge("cache_hit_rate_percent")
    
    # Phase 2: Authoring Assistant
    SUGGESTIONS_GENERATED = Counter("test_suggestions_generated_total")
    SUGGESTIONS_ACCEPTED = Counter("test_suggestions_accepted_total")
    PLAYBOOK_SIZE = Gauge("playbook_patterns_total")
    
    # Phase 3: NL Interpretation
    NL_INTERPRETATION_LATENCY = Histogram("nl_interpretation_latency_seconds")
    NL_SUCCESS_RATE = Gauge("nl_interpretation_success_rate")
    CLARIFICATION_NEEDED_RATE = Gauge("nl_clarification_needed_rate")
    
    # Phase 4: Multi-Agent
    CONSENSUS_RATE = Gauge("multi_agent_consensus_rate")
    AGENT_AGREEMENT_SCORE = Histogram("agent_agreement_score")
    DIAGNOSTIC_ACCURACY = Gauge("diagnostic_accuracy_percent")
```

---

## Security & Privacy

### Data Handling

```python
# security.py

class DataSanitizer:
    """
    Sanitize sensitive data before sending to AI APIs
    """
    
    def sanitize_for_ai(
        self,
        data: Union[str, bytes],
        data_type: str
    ) -> Union[str, bytes]:
        """
        Remove PII and sensitive data
        """
        
        if data_type == "screenshot":
            # Blur faces, credit cards, SSNs
            return self._blur_sensitive_regions(data)
        
        if data_type == "logs":
            # Redact API keys, passwords, tokens
            return self._redact_secrets(data)
        
        if data_type == "network":
            # Remove auth headers, sensitive params
            return self._sanitize_network_data(data)
        
        return data
    
    def _redact_secrets(self, text: str) -> str:
        patterns = [
            r'api[_-]?key["\']?\s*[:=]\s*["\']?([a-zA-Z0-9_-]+)',
            r'password["\']?\s*[:=]\s*["\']?([^\s"\']+)',
            r'Bearer\s+([a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+)',
        ]
        
        for pattern in patterns:
            text = re.sub(pattern, r'\1***REDACTED***', text)
        
        return text
```

---

## Deployment Architecture

### Infrastructure Overview

```
┌───────────────────────────────────────────────────────┐
│                    AWS/GCP                            │
│                                                       │
│  ┌──────────────────┐    ┌──────────────────┐         │
│  │   API Gateway    │───▶│  Load Balancer   │         │
│  │  (Kong/Nginx)    │    │                  │         │
│  └──────────────────┘    └─────────┬────────┘         │
│                                    │                  │
│                 ┌──────────────────|                  │
│                 │                  │                  │
│           ┌─────▼──────┐    ┌──────▼─────────┐        │
│           │  Service   │    │  AI Services   │        │
│           │  Cluster   │    │   Cluster      │        │
│           │            │    │                │        │
│           │  (ECS/K8s) │    │ - Error        │        │
│           │            │    │   Analyzer     │        │
│           │ - API      │    │ - NL           │        │
│           │ - Playbook │    │   Interpreter  │        │
│           │            │    │ - Multi-Agent  │        │
│           │            │    │ - Embeddings   │        │
│           └────────────┘    └────────────────┘        │
│                                                       │
│  ┌───────────────────────────────────────────┐        │
│  │         Data Stores                       │        │
│  │                                           │        │
│  │  RDS (PostgreSQL)  Redis  S3  Pinecone    │        │
│  └───────────────────────────────────────────┘        │
└───────────────────────────────────────────────────────┘
```

---

## Conclusion

This architecture supports the 4-phase evolution:

1. **Phase 1:** Error analysis (AI on failures only)
2. **Phase 2:** ACE playbooks (learning layer)
3. **Phase 3:** NL interpretation (conversation layer)
4. **Phase 4:** Multi-agent consensus (intelligence layer)

**Key Principles:**
- Separation of execution (Maestro) from intelligence (AI)
- Each phase builds on previous (data compounds)
- Cost-efficient (AI only where valuable)
- Secure (PII redaction)
- Observable (comprehensive metrics)

**Next Step:** Implement Phase 1 prototype to validate architecture.

