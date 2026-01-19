# Future Development Ideas

Optional enhancements for the code analysis toolchain.

---

## Design Decisions (January 2026)

Documenting key architectural choices made during the refactor.

### Why diff-file only (no `--source`)?

We considered two approaches for getting the diff:
1. **Upload source** → Dagger computes `git diff` inside container
2. **Pre-computed diff** → User runs `git diff` locally, passes file to Dagger

**We chose option 2 because:**
- Uploading the monorepo adds ~12s overhead with zero benefit
- Git computes diffs locally in <1s
- The justfile handles pre-computation transparently
- Keeps the Dagger function simple and single-purpose

**Pattern:** Git computes diff (fast, local) → Dagger runs LLM (containerized, reproducible)

### Why no containerized Ollama?

We considered running Ollama inside Dagger for a "self-contained" CI experience.

**We removed it because:**
- Docker on Mac can't use Metal GPU → CPU-only → ~60s per inference
- Most CI runners lack GPUs, making LLM review impractical
- Practical CI setups would use self-hosted runners with GPUs or remote Ollama
- Added significant complexity for a rarely-used feature

**Recommendation:** Run Ollama natively for local dev (fast), or connect to a remote Ollama server for CI.

### Why `ExecutePrompts` (plural)?

One function that accepts multiple prompts and runs them in parallel.

**Benefits:**
- `just review` runs all review prompts with one call
- Parallel execution means ~30s total, regardless of prompt count
- Flexible: can mix prompts from different folders
- Single implementation to maintain

---

## 1. Parallel File Reviews (High Impact)

Instead of sending the entire diff to the model at once, split by file and review concurrently.

**Benefits:**
- Faster overall review time (parallel execution)
- Per-file feedback is easier to act on
- Avoids context window limits on large PRs
- Can prioritize files (security-sensitive first)

**Implementation sketch:**
```go
func (m *Code) ReviewDiffParallel(ctx context.Context, source *dagger.Directory, base, head string) ([]*FileReview, error) {
    // 1. Get list of changed files: git diff --name-only base..head
    // 2. For each file, spawn a goroutine that:
    //    - Gets the file's diff: git diff base..head -- <file>
    //    - Sends to Ollama for review
    // 3. Collect results with proper error handling
    // 4. Return structured []*FileReview
}

type FileReview struct {
    FilePath string
    Summary  string
    Issues   []Issue
    Rating   int
}
```

**Dagger advantage:** Can use `dag.Container()` per file and Dagger handles parallelism automatically.

---

## 2. Smarter Chunking (Medium Impact)

For massive PRs that exceed context windows, chunk intelligently rather than truncating.

**Chunking strategies:**
- **By file type**: Review all `.rs` files together (same language context), then `.swift`, etc.
- **By directory**: Group by feature area (`api/`, `models/`, `views/`)
- **By semantic boundary**: Use tree-sitter to split at function/class boundaries
- **By priority**: Security-sensitive files first (auth, crypto, API keys)

**Implementation considerations:**
- Need a "summarizer" pass that combines per-chunk reviews
- Could use a smaller model for initial triage, larger model for deep review
- Track token counts per chunk to stay within limits

---

## 3. Differential Caching

Cache reviews at the file+content hash level to skip unchanged files.

**How it works:**
1. For each file in the diff, compute SHA256 of its new content
2. Check cache: `reviews/<hash>.json`
3. If cached and recent (< 7 days?), skip review
4. If not cached, review and store result

**Cache key structure:**
```
<file_hash>-<model_name>-<prompt_hash>.json
```

**Storage location:**
```
~/.cache/dagger-code-review/
├── index.db                      # SQLite for fast lookups
└── reviews/
    ├── a1b2c3d4.json            # Cached review by content hash
    └── e5f6g7h8.json
```

**Pruning strategy:**
```go
type CacheConfig struct {
    MaxAgeDays  int   // Default: 30 - delete reviews older than this
    MaxSizeMB   int   // Default: 100 - prune oldest 20% when exceeded
    MaxEntries  int   // Default: 1000 - hard cap on entries
}
```

Automatic pruning triggers:
1. On every review: check if cache > MaxSizeMB, prune oldest 20%
2. On startup: delete entries older than MaxAgeDays
3. Manual: `dagger -m ./devtools/code call prune-cache`

**Invalidation:**
- Model change → invalidate all
- Prompt change → invalidate affected reviews
- Time-based expiry (reviews go stale as codebase evolves)

---

## 4. Remote Ollama Setup

Run Ollama on a separate machine for better performance or team sharing.

### Option A: Spare Laptop / Mac Mini (Simple)

Run Ollama on a spare machine on your local network.

**Pros:**
- Zero ongoing cost
- Simple setup
- Good for solo development

**Cons:**
- Must be on same network (or use VPN/Tailscale)
- Single point of failure
- Machine must stay running

**Setup:**
```bash
# On the spare machine
OLLAMA_HOST=0.0.0.0:11434 ollama serve

# From your main machine (same network)
dagger -m ./devtools/code call review-diff \
    --source=. --base=main --head=HEAD \
    --ollama-host="192.168.1.X:11434"
```

### Option B: Tailscale + Home Server (Recommended)

Use Tailscale for secure access from anywhere without exposing ports to the internet.

**Pros:**
- Secure: no ports exposed to internet
- Access from anywhere (coffee shop, office, travel)
- Free for personal use
- Works across networks

**Setup:**
```bash
# 1. Install Tailscale on both machines
# https://tailscale.com/download

# 2. On home server, start Ollama
OLLAMA_HOST=0.0.0.0:11434 ollama serve

# 3. From anywhere, use the Tailscale IP (100.x.x.x)
dagger -m ./devtools/code call review-diff \
    --source=. --base=main --head=HEAD \
    --ollama-host="100.x.x.x:11434"
```

**Why Tailscale?**
- Creates a private network between your devices
- No port forwarding or firewall changes needed
- Traffic is encrypted end-to-end
- Works even when both machines are behind NAT

### Option C: Home Server with NVIDIA GPU (Best Performance)

For maximum local inference speed, run Ollama on a dedicated machine with an NVIDIA GPU.

**Why GPU matters for LLMs:**

LLM inference is **memory bandwidth bound**, not compute bound. Each token requires loading the entire model from memory:

| Hardware | Memory Bandwidth | gemma3:4b Speed | gemma3:1b Speed |
|----------|------------------|-----------------|-----------------|
| Apple M1/M2 | 100-200 GB/s | ~10-20 tok/s | ~30-50 tok/s |
| Apple M2 Pro/Max | 200-400 GB/s | ~30-50 tok/s | ~80-120 tok/s |
| **RTX 4090** | **1,008 GB/s** | **~100-150 tok/s** | **~200+ tok/s** |
| RTX 3090 | 936 GB/s | ~90-130 tok/s | ~180+ tok/s |

An RTX 4090 is **5-10x faster** than Apple Silicon for the same models.

**Hardware requirements:**
- NVIDIA RTX 4090 (~$1,600) or RTX 3090 (~$800 used)
- 24GB VRAM handles models up to ~14B parameters
- Basic PC: any modern CPU, 32GB+ RAM, 500W+ PSU
- Total cost: ~$2,000-3,000

**Setup:**
```bash
# 1. Install NVIDIA drivers + CUDA
# 2. Install Ollama: curl -fsSL https://ollama.com/install.sh | sh
# 3. Pull models
ollama pull gemma3:4b

# 4. Start Ollama (listen on all interfaces)
OLLAMA_HOST=0.0.0.0:11434 ollama serve

# 5. Access via Tailscale from anywhere
dagger -m ./devtools/code call execute-prompts \
    --diff-file=diff.txt \
    --prompts="review-code/for-basic" \
    --ollama-host="100.x.x.x:11434"
```

**Why this beats cloud:**
- No ongoing costs after hardware purchase
- Sub-second response latency (no network round-trip to cloud)
- Can run larger models (70B+ with quantization)
- Privacy: code never leaves your network

### Option D: Cloud GPU (For Teams / CI)

Run Ollama on a cloud instance for team access or CI pipelines.

**When to consider:**
- Multiple team members need access
- Need GPU for faster inference
- Want always-on availability
- CI/CD pipelines need LLM review

**Cost considerations:**
- CPU-only: ~$20-50/month (adequate for `gemma3:1b`, slow)
- GPU (T4): ~$150-300/month (~50 tok/s)
- GPU (A10/L4): ~$300-500/month (~100 tok/s)
- GPU (A100): ~$1,000+/month (overkill for code review)
- Use spot/preemptible instances for 60-70% savings

**Providers:**
- **RunPod**: Pay-per-hour ($0.40-1.00/hr), best for occasional use
- **Vast.ai**: Cheapest GPUs, community providers
- **Lambda Labs**: Dedicated GPU servers
- **GCP/AWS**: Enterprise reliability, higher cost

---

## 5. Markdown Report Output

Save reviews to markdown files for tracking and sharing.

**Proposed structure:**
```
.reviews/
├── 2026-01-18_feature-auth.md
├── 2026-01-19_fix-login-bug.md
└── index.json  # Quick lookup metadata
```

**Usage:**
```bash
dagger -m ./devtools/code call review-diff \
    --source=. --base=main --head=feature-auth \
    --output=.reviews/
```

**Open questions:**
- Should output be per-review or per-file?
- How to handle multiple reviews of the same branch?
- Should old reviews be auto-pruned?

---

## Notes

- Start with parallel file reviews—biggest bang for buck
- Chunking only matters for very large PRs (100+ files)
- Caching is most valuable in CI where same files get re-reviewed
- Tailscale + home server is the sweet spot for solo remote access
- **For best performance:** RTX 4090 + Tailscale gives 5-10x speedup over Apple Silicon
- Smaller models (1B) are ~3x faster than larger (4B) with similar quality for code review
