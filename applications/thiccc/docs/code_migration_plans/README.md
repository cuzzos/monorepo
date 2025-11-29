# Code Migration Plans - app.rs Refactoring

**Goal:** Break apart the 2469-line `app.rs` file into modular components following Crux framework conventions.

## Migration Phases

| Phase | File | Status | Time Est. | Risk |
|-------|------|--------|-----------|------|
| 1 | [01-EXTRACT-TESTS.md](./01-EXTRACT-TESTS.md) | ✅ Complete | 30 min | Low |
| 2 | [02-EXTRACT-TYPES.md](./02-EXTRACT-TYPES.md) | ✅ Complete | 1 hour | Medium |
| 3 | [03-SPLIT-UPDATE-LOGIC.md](./03-SPLIT-UPDATE-LOGIC.md) | ✅ Complete | 1-2 hours | Medium |

## Quick Start

```bash
# Start with Phase 1
cd app/shared
cargo test  # Verify baseline
```

Then follow each phase in order.

## Expected Outcome

**Before:**
```
app/shared/src/app.rs - 2469 lines (everything)
```

**After (ALL PHASES COMPLETE!):**
```
app/shared/src/app/
├── mod.rs                    (291 lines - orchestration only)
├── events.rs                 (246 lines)
├── model.rs                  (186 lines)
├── view_models.rs            (265 lines)
├── effects.rs                (34 lines)
├── update/                   (715 lines across 10 files)
│   ├── mod.rs                (84 lines - routing)
│   ├── app_lifecycle.rs      (22 lines)
│   ├── workout.rs            (114 lines)
│   ├── exercise.rs           (78 lines)
│   ├── sets.rs               (93 lines)
│   ├── timer.rs              (67 lines)
│   ├── history.rs            (45 lines)
│   ├── import_export.rs      (54 lines)
│   ├── plate_calculator.rs   (66 lines)
│   └── capabilities.rs       (104 lines)
└── tests/                    (1,172 lines across 5 files)
```

**Key Metrics:**
- **Original file**: 2,469 lines
- **Main orchestration file (`mod.rs`)**: 291 lines (88% reduction!)
- **Average update module size**: ~71 lines
- **All 87 tests passing** ✅

## References

- [Crux Weather Example](https://github.com/redbadger/crux/tree/master/examples/weather)
- [SHARED-CRATE-MAP.md](../SHARED-CRATE-MAP.md) - Current codebase structure

