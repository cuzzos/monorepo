# Monorepo Structure & Best Practices

This repository follows a monorepo structure with multiple applications under the `applications/` directory.

## Directory Structure

```
Goonlytics/
├── .cursor/
│   └── rules/              # Shared Cursor AI context files
│       └── swift-ios.mdc   # Shared iOS/Swift development rules
├── applications/
│   ├── thiccc/             # Fitness tracking app
│   │   └── .cursor/
│   │       └── rules/
│   │           ├── swift-ios.mdc      # Symlink to shared rules
│   │           ├── rust-coverage.mdc  # Project-specific rules
│   │           └── ...
│   └── sharp9/             # [Description of sharp9]
│       └── .cursor/
│           └── rules/
│               └── swift-ios.mdc      # Symlink to shared rules
└── docs/
    └── research/
```

## Cursor AI Context Files

### Shared Rules

Shared Cursor context files are stored at the monorepo root in `.cursor/rules/`. These files contain conventions, patterns, and guidelines that apply across multiple projects.

**Current shared rules:**
- `swift-ios.mdc` - iOS/Swift development standards and patterns

### Project-Specific Rules

Each application can have its own project-specific rules in `applications/<project>/.cursor/rules/`. These should contain conventions unique to that project.

### How It Works

We use **symbolic links (symlinks)** to share common context files across projects:

```bash
# The shared file lives here:
.cursor/rules/swift-ios.mdc

# Projects link to it:
applications/thiccc/.cursor/rules/swift-ios.mdc -> ../../../../.cursor/rules/swift-ios.mdc
applications/sharp9/.cursor/rules/swift-ios.mdc -> ../../../../.cursor/rules/swift-ios.mdc
```

**Benefits:**
- ✅ Single source of truth for shared conventions
- ✅ Each project can be opened as an independent Cursor workspace
- ✅ Changes to shared rules automatically apply to all projects
- ✅ Projects maintain their own specific rules alongside shared ones

## Opening Projects in Cursor

You can open any application directory as its own Cursor workspace:

```bash
# Open thiccc independently
cd applications/thiccc
cursor .

# Open sharp9 independently
cd applications/sharp9
cursor .

# Or open the entire monorepo
cd /path/to/Goonlytics
cursor .
```

Each project will have access to:
1. Shared rules via symlinks (e.g., `swift-ios.mdc`)
2. Its own project-specific rules (if any)

## Adding a New Application

When adding a new application to the monorepo:

1. Create the application directory:
   ```bash
   mkdir -p applications/<new-app>
   ```

2. Set up Cursor rules directory:
   ```bash
   mkdir -p applications/<new-app>/.cursor/rules
   ```

3. Link to shared rules as needed:
   ```bash
   cd applications/<new-app>/.cursor/rules
   ln -s ../../../../.cursor/rules/swift-ios.mdc swift-ios.mdc
   # Add other shared rules as needed
   ```

4. Add project-specific rules:
   ```bash
   # Create new .mdc files directly in the project's .cursor/rules/
   touch applications/<new-app>/.cursor/rules/project-specific.mdc
   ```

## Adding New Shared Rules

To create a new shared rule that multiple projects can use:

1. Create the rule at the monorepo root:
   ```bash
   touch .cursor/rules/<new-rule>.mdc
   ```

2. Link it in each project that needs it:
   ```bash
   cd applications/<project>/.cursor/rules
   ln -s ../../../../.cursor/rules/<new-rule>.mdc <new-rule>.mdc
   ```

## Git Configuration

The `.gitignore` is configured to:
- ✅ Track the shared `.cursor/rules/` directory at the root
- ✅ Track symlinks in project `.cursor/rules/` directories
- ❌ Ignore user-specific `.cursor/` settings and cache files

```gitignore
# Ignore user-specific Cursor settings but keep shared rules
**/.cursor/
!.cursor/
!.cursor/rules/
```

This means:
- Shared rules and symlinks are committed to git
- User-specific Cursor settings remain local
- New team members get the shared rules automatically

## Best Practices

### When to Use Shared Rules
- Coding conventions that apply across multiple projects
- Common architectural patterns
- Shared technology stacks (e.g., Swift/iOS, Rust)
- Organization-wide standards

### When to Use Project-Specific Rules
- Project-specific architecture decisions
- Unique technology choices
- Domain-specific conventions
- Temporary development guidelines

### Updating Shared Rules
When updating a shared rule:
1. Edit the file at `.cursor/rules/<rule>.mdc`
2. Test in one project to ensure it works as expected
3. Commit the changes - all projects using the symlink will automatically get the update

### Verifying Symlinks
To verify symlinks are working correctly:

```bash
# Check if symlink exists and points to the right place
ls -la applications/*/. cursor/rules/

# Verify the symlink resolves to the actual file
readlink applications/thiccc/.cursor/rules/swift-ios.mdc
# Should output: ../../../../.cursor/rules/swift-ios.mdc
```

## Troubleshooting

### Symlink Broken
If a symlink appears broken:
```bash
# Remove the broken symlink
rm applications/<project>/.cursor/rules/<rule>.mdc

# Recreate it
cd applications/<project>/.cursor/rules
ln -s ../../../../.cursor/rules/<rule>.mdc <rule>.mdc
```

### Cursor Not Finding Rules
If Cursor isn't recognizing the rules:
1. Ensure you're opening the project directory (not a subdirectory)
2. Restart Cursor
3. Check that the symlink is valid: `ls -la .cursor/rules/`

### Adding Rules to Git
If new shared rules aren't being tracked by git:
```bash
# Force add the specific file (overrides .gitignore if needed)
git add -f .cursor/rules/<new-rule>.mdc

# Verify it's staged
git status
```

## Questions?

For questions about this setup or suggestions for improvements, please reach out to the team or create an issue.

