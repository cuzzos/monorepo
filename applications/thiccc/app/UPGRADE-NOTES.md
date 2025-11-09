# Upgrade to Rust Edition 2024

## What Changed

Your iOS application has been updated to use **Rust Edition 2024**, the latest stable edition released in February 2025 with Rust 1.85.0.

### Package Versions

- **Rust Edition**: Upgraded from 2021 → **2024**
- **Rust Compiler**: 1.90.0 (supports edition 2024)
- **crux_core**: Kept at v0.7.6 (stable API)
- **serde**: Updated to latest 1.0.228
- **All transitive dependencies**: Updated to latest compatible versions

### Why Crux 0.7 Instead of 0.16?

Crux 0.16 introduced significant breaking API changes that move to a Command-based architecture. For this proof of concept, we're using the stable 0.7 API which:
- Has well-documented patterns
- Provides all features needed for basic apps
- Works seamlessly with Rust 2024 edition
- Is easier to understand and extend

When you're ready to scale, you can migrate to 0.16+ for the new Command API.

## What You Get with Rust 2024 Edition

1. **Future/IntoFuture in Prelude** - async traits automatically available
2. **Reserved `gen` Keyword** - preparing for generator syntax
3. **Improved Error Messages** - better compiler diagnostics
4. **Safety Improvements** - disallows references to `static mut`
5. **Performance Optimizations** - better code generation

## Verification

All tests pass successfully:
```bash
cd shared && cargo test
```

Results:
```
test tests::test_increment ... ok
test tests::test_model_default ... ok
test tests::test_view ... ok
```

## Next Steps

1. Continue developing features with the stable API
2. When ready for production, consider migrating to crux_core 0.16+ for:
   - New Command-based architecture
   - Better composability
   - More modern patterns

## Documentation

- Main README: `app/README.md`
- Core README: `app/shared/README.md`
- Rust 2024 Guide: https://doc.rust-lang.org/edition-guide/rust-2024/
- Crux Documentation: https://github.com/redbadger/crux

---

**Note**: Your code is now using the latest Rust edition (2024) with all dependencies updated to their latest compatible versions while maintaining a stable, well-tested API.

