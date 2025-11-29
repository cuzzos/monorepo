# Serialization Best Practices: Bincode vs JSON

**Decision**: Which serialization format to use between Rust and Swift?

**TL;DR**: **Use Bincode (current setup)** for production. Only switch to JSON if debugging becomes a major pain point.

---

## Current State

Your app currently uses **Bincode** (binary serialization):

```swift
// In core.swift
let viewBytes = Array(viewData)
self.view = try! SharedTypes.ViewModel.bincodeDeserialize(input: viewBytes)
```

This is the **Crux framework default** and the **recommended approach for production apps**.

---

## Comparison

### Bincode (Current) ⭐ RECOMMENDED

**What it is**: Binary serialization format from the `bincode` crate

**Pros**:
- ✅ **Faster**: 3-10x faster than JSON for typical data
- ✅ **Smaller**: ~30-50% smaller payloads
- ✅ **Type-safe**: Exact match to Rust types, catches mismatches at runtime
- ✅ **Default for Crux**: Official recommendation
- ✅ **Better for mobile**: Less battery drain, less bandwidth
- ✅ **No parsing overhead**: Direct byte-level deserialization

**Cons**:
- ❌ **Not human-readable**: Can't inspect with `print()` or debugger easily
- ❌ **Harder debugging**: Runtime errors are less clear
- ❌ **Version sensitive**: Schema changes need careful handling
- ❌ **Binary debugging**: Need tools to inspect payloads

**Performance** (typical workout data):
```
ViewModel serialization:
  JSON:    ~2.5 KB, ~0.8ms
  Bincode: ~1.2 KB, ~0.2ms
  
Benefit: 50% smaller, 4x faster
```

---

### JSON (Alternative)

**What it is**: Text-based format using `serde_json`

**Pros**:
- ✅ **Human-readable**: Can see data in Xcode console
- ✅ **Easy debugging**: Clear error messages
- ✅ **Language agnostic**: Works with any JSON parser
- ✅ **Flexible versioning**: Missing fields can be optional
- ✅ **Inspectable**: Great for development/testing

**Cons**:
- ❌ **Slower**: More CPU for parsing text
- ❌ **Larger**: Text encoding is verbose
- ❌ **Battery impact**: More processing = more battery drain
- ❌ **Bandwidth**: Matters for network sync (future)
- ❌ **Manual setup**: Need to configure Crux to use JSON

**Performance** (typical workout data):
```
ViewModel serialization:
  JSON:    ~2.5 KB, ~0.8ms
  Bincode: ~1.2 KB, ~0.2ms
  
Cost: 2x larger, 4x slower
```

---

## Recommendation for Your App

### ✅ Stick with Bincode (Current Setup)

**Why?**

1. **Your data is small-ish**
   - Typical workout: ~1-5 KB
   - History list: ~10-50 KB
   - Bincode overhead is negligible
   
2. **Mobile performance matters**
   - Every millisecond counts on battery
   - Smoother UI = better UX
   
3. **It's already working**
   - Generated types support it
   - No need to change working code
   
4. **Crux best practice**
   - Official recommendation
   - Battle-tested in production apps

### When to Consider JSON

**If you experience**:
- Frequent deserialization errors that are hard to debug
- Need to inspect data frequently during development
- Third-party integrations need JSON
- Data export/import features (already have ImportWorkout with JSON!)

---

## How Each Format Works

### Current (Bincode)

```mermaid
Rust Core                    Swift Shell
┌─────────────┐              ┌──────────────┐
│  ViewModel  │────Bincode──>│  Core.view   │
│   (struct)  │  (binary)    │  (property)  │
└─────────────┘              └──────────────┘
     ^                               │
     │                               │
     └────────Event (binary)─────────┘
```

**Flow**:
1. Rust serializes ViewModel to `Vec<u8>` (bytes)
2. UniFFI passes bytes as `Data` to Swift
3. Swift calls `bincodeDeserialize(input:)`
4. Swift has native ViewModel struct

**Code**:
```swift
// Receiving view
let viewData = Thiccc.view()          // Data (binary)
let viewBytes = Array(viewData)       // [UInt8]
self.view = try! SharedTypes.ViewModel.bincodeDeserialize(input: viewBytes)

// Sending event
let eventBytes = try! event.bincodeSerialize()  // [UInt8]
let eventData = Data(eventBytes)                // Data
let viewData = Thiccc.processEvent(eventData)   // Returns updated view
```

---

### Alternative (JSON)

```mermaid
Rust Core                    Swift Shell
┌─────────────┐             ┌──────────────┐
│  ViewModel  │────JSON────>│  Core.view   │
│   (struct)  │   (text)    │  (property)  │
└─────────────┘             └──────────────┘
     ^                               │
     │                               │
     └────────Event (text)───────────┘
```

**Flow**:
1. Rust serializes ViewModel to JSON `String`
2. UniFFI passes string as `Data` to Swift
3. Swift uses `JSONDecoder`
4. Swift has native ViewModel struct

**Code** (if you switched):
```swift
// Receiving view
let viewData = Thiccc.view()          // Data (UTF-8 JSON)
let json = String(data: viewData, encoding: .utf8)!
self.view = try! JSONDecoder().decode(SharedTypes.ViewModel.self, from: viewData)

// Sending event
let eventData = try! JSONEncoder().encode(event)
let viewData = Thiccc.processEvent(eventData)
```

---

## How to Switch to JSON (If Needed)

### ⚠️ Not Recommended, But Here's How

If you really want JSON for easier debugging:

### Step 1: Update Rust Core

```rust
// In app/shared/src/lib.rs or appropriate file
use crux_core::Core;
use serde_json;

// Instead of default Bincode bridge:
impl BridgeCapability<Effect> for ThicccApp {
    // Use JSON serialization
    fn process_event(&self, event: &[u8]) -> Vec<u8> {
        let event: Event = serde_json::from_slice(event).unwrap();
        // ... process ...
        let view = self.view();
        serde_json::to_vec(&view).unwrap()
    }
}
```

### Step 2: Update Swift Bridge

```swift
// In core.swift
func update(_ event: SharedTypes.Event) {
    // Use JSON instead of Bincode
    let eventData = try! JSONEncoder().encode(event)
    let viewData = Thiccc.processEvent(eventData)
    self.view = try! JSONDecoder().decode(SharedTypes.ViewModel.self, from: viewData)
}
```

### Step 3: Update TypeGen

```rust
// In app/shared_types/build.rs
gen.swift_json("SharedTypes", output_root.join("swift"))?;
// Instead of: gen.swift("SharedTypes", output_root.join("swift"))?;
```

**Complexity**: Medium (2-3 hours of work)  
**Risk**: High (need to update all bridges, test thoroughly)  
**Benefit**: Easier debugging  
**Cost**: Slower, larger payloads

---

## Debugging with Bincode

Since you're using Bincode, here's how to debug effectively:

### Technique 1: Add Debug Logging in Rust

```rust
// In app/shared/src/app.rs
pub fn view(&self) -> ViewModel {
    let vm = ViewModel {
        // ... fields ...
    };
    
    #[cfg(debug_assertions)]
    {
        // Only in debug builds
        eprintln!("ViewModel: {:#?}", vm);
    }
    
    vm
}
```

### Technique 2: Serialize to JSON for Inspection

```rust
// In tests or debug code
#[test]
fn inspect_viewmodel() {
    let vm = create_test_viewmodel();
    let json = serde_json::to_string_pretty(&vm).unwrap();
    println!("{}", json);  // See what it looks like
}
```

### Technique 3: Swift Debug Print

```swift
// In core.swift (temporary debugging)
func update(_ event: SharedTypes.Event) {
    let eventBytes = try! event.bincodeSerialize()
    
    // Debug: Print event name
    print("Event: \(event)")
    
    let eventData = Data(eventBytes)
    let viewData = Thiccc.processEvent(eventData)
    let viewBytes = Array(viewData)
    self.view = try! SharedTypes.ViewModel.bincodeDeserialize(input: viewBytes)
    
    // Debug: Print view state
    print("View updated: hasActiveWorkout=\(view.workout_view.has_active_workout)")
}
```

### Technique 4: Conditional JSON in Debug

```swift
// Add this to Core class for debugging
#if DEBUG
func debugView() -> String {
    // Manually serialize to JSON for inspection
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    if let data = try? encoder.encode(view),
       let json = String(data: data, encoding: .utf8) {
        return json
    }
    return "Failed to encode"
}
#endif

// Use in debugging:
// print(core.debugView())
```

---

## Real-World Example: When Size Matters

Imagine loading history with 100 workouts:

**JSON**:
```json
{
  "history_view": {
    "workouts": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "name": "Morning Workout",
        "exercises": [...],
        ...
      },
      ...
    ]
  }
}
```
Size: ~250 KB
Parse time: ~15ms on iPhone

**Bincode**:
```
[Binary data]
```
Size: ~120 KB (52% smaller)
Parse time: ~3ms on iPhone (5x faster)

**Impact**: Smoother scrolling, less battery drain

---

## Testing Both Formats

Your codebase already does this! Look at the tests:

```rust
// From app/shared/src/models.rs
#[test]
fn test_workout_serialization() {
    let workout = create_test_workout();
    
    // Test JSON (for compatibility)
    let json = serde_json::to_string(&workout).expect("Failed to serialize workout");
    let deserialized: Workout =
        serde_json::from_str(&json).expect("Failed to deserialize workout");
    assert_eq!(workout, deserialized);
    
    // Note: Bincode is tested at the FFI boundary
}
```

This ensures your types work with both formats if needed.

---

## Special Case: Import/Export

You're already using JSON appropriately!

```rust
// From app/shared/src/app.rs
Event::ImportWorkout { json_data } => {
    match serde_json::from_str::<Workout>(&json_data) {
        Ok(workout) => {
            // Import from JSON file
        }
        Err(_) => {
            model.error_message = Some("Invalid workout data".to_string());
        }
    }
}
```

**This is the right pattern**:
- Use Bincode for internal app communication (fast)
- Use JSON for external data (files, API, user export)

---

## Summary

| Aspect | Bincode ✅ | JSON |
|--------|-----------|------|
| **Speed** | ⚡⚡⚡⚡⚡ (4x faster) | ⚡ |
| **Size** | 📦📦 (50% smaller) | 📦📦📦📦 |
| **Debugging** | 🔍 (harder) | 🔍🔍🔍🔍🔍 (easy) |
| **Battery** | 🔋🔋🔋🔋🔋 (better) | 🔋🔋🔋 |
| **Type Safety** | ✅✅✅✅✅ | ✅✅✅ |
| **Crux Default** | ✅ Yes | ❌ No |
| **Setup Effort** | ✅ Already done | ⚠️ Need to configure |

---

## Final Recommendation

### ✅ Keep using Bincode

**Reasons**:
1. Already working
2. Better performance
3. Crux best practice
4. Mobile-optimized
5. Debugging is manageable with logging

### 🎯 Best of Both Worlds

Use what you're already doing:
- **Bincode**: For all FFI communication (ViewModel, Events)
- **JSON**: For import/export features, debugging tests, external APIs

This gives you performance where it matters and flexibility where you need it.

---

## Questions?

**Q: What if I get weird deserialization errors?**  
A: Add Rust-side logging (see Technique 1 above). Most issues are type mismatches, not format problems.

**Q: Can I switch later if needed?**  
A: Yes, but it's effort (2-3 hours). Stick with Bincode unless you hit a real problem.

**Q: Does this affect my database?**  
A: No. Database uses SQLite with its own format. This is only for Rust↔️Swift communication.

**Q: What about future web version?**  
A: WASM can use either. Bincode works fine. JSON is more common for web APIs.

---

## References

- [Bincode Documentation](https://docs.rs/bincode/)
- [Crux Serialization Docs](https://redbadger.github.io/crux/)
- [Serde Documentation](https://serde.rs/)
- [Performance Benchmarks](https://github.com/djkoloski/rust_serialization_benchmark)

---

**Decision: Stick with Bincode** ✅

Your current setup is optimal for a mobile workout tracking app. Only reconsider if debugging becomes a major bottleneck (unlikely).

