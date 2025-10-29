# iOS App Setup

The Xcode project file was removed because it was incorrectly formatted. Here's how to create it properly on your Mac.

## 🎯 Quick Setup (Choose One Method)

### Method 1: Automatic with XcodeGen (Fastest - 2 minutes)

**On your Mac:**

```bash
cd /path/to/thiccc/app/ios

# If you don't have XcodeGen, install it:
brew install xcodegen

# Generate the project:
xcodegen generate

# Or use the helper script:
./generate-xcode-project.sh
```

✅ **Result**: `thiccc.xcodeproj` will be created and ready to open

---

### Method 2: Manual in Xcode (Most Control - 5 minutes)

**Follow the detailed guide:**

📖 See **[CREATE-XCODE-PROJECT.md](CREATE-XCODE-PROJECT.md)** for step-by-step instructions

This method gives you the most control and is good for learning Xcode project setup.

---

## 📁 Current Structure

```
ios/
├── README.md                       ← You are here
├── CREATE-XCODE-PROJECT.md         ← Detailed manual setup guide
├── generate-xcode-project.sh       ← Automatic setup script
├── project.yml                     ← XcodeGen specification
│
├── thiccc.xcodeproj/               ← WILL BE CREATED by you
│   └── project.pbxproj             ← (on your Mac)
│
└── thiccc/                         ← Source files (already here ✅)
    ├── ThicccApp.swift             ✅ App entry point
    ├── ContentView.swift           ✅ Main UI
    ├── Core.swift                  ✅ Rust bridge
    ├── Info.plist                  ✅ App metadata
    └── Assets.xcassets/            ✅ App icon & assets
```

---

## 🚀 After Creating the Project

Once you have `thiccc.xcodeproj`:

1. **Open in Xcode**
   ```bash
   open thiccc.xcodeproj
   ```

2. **Configure Signing**
   - Go to: Signing & Capabilities
   - Enable: "Automatically manage signing"
   - Select: Your Apple Developer team

3. **Build & Run**
   - Select a simulator (e.g., iPhone 15 Pro)
   - Press ⌘R or click Run ▶️
   - App should launch! 🎉

4. **Deploy to TestFlight**
   - Follow: `../TESTFLIGHT-QUICKSTART.md`

---

## ⚙️ What Each File Does

| File | Purpose |
|------|---------|
| `project.yml` | XcodeGen spec - defines project structure |
| `generate-xcode-project.sh` | Automated project creation script |
| `CREATE-XCODE-PROJECT.md` | Manual setup instructions |
| `thiccc/` | Your app source code |

---

## 🔧 Using XcodeGen (Recommended)

### Why XcodeGen?

- ✅ Generates proper Xcode projects programmatically
- ✅ Consistent, reproducible project setup
- ✅ Easy to version control (YAML is readable)
- ✅ Avoids merge conflicts in `.pbxproj`

### Install XcodeGen

```bash
# Using Homebrew (recommended)
brew install xcodegen

# Or download from:
# https://github.com/yonaskolb/XcodeGen
```

### Generate Project

```bash
cd /path/to/thiccc/app/ios
xcodegen generate
```

That's it! The `project.yml` file contains all the configuration.

### Customize Project

Edit `project.yml` to change:
- Bundle identifier
- Deployment target
- Build settings
- Add new files
- Configure capabilities

Then regenerate:
```bash
xcodegen generate
```

---

## 🆘 Troubleshooting

### "XcodeGen not found"
**Solution**: Install it first
```bash
brew install xcodegen
```

### "Homebrew not found"
**Solution**: Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### "Project generation failed"
**Solution**: Check that all source files exist
```bash
ls -la thiccc/
# Should show: ThicccApp.swift, ContentView.swift, Core.swift, etc.
```

### "Can't open project in Xcode"
**Solution**: Make sure you're opening the `.xcodeproj`, not the `.xcworkspace`
```bash
open thiccc.xcodeproj
```

### Files appear red in Xcode
**Solution**: The files can't be found. Either:
1. Regenerate with `xcodegen generate`
2. Or manually add files: Right-click → "Add Files to thiccc..."

---

## 📚 Learn More

- **XcodeGen docs**: https://github.com/yonaskolb/XcodeGen
- **Xcode projects**: https://developer.apple.com/documentation/xcode
- **TestFlight deployment**: See `../TESTFLIGHT-QUICKSTART.md`

---

## ✅ Checklist

- [ ] Have Mac with macOS
- [ ] Have Xcode installed
- [ ] Install XcodeGen (`brew install xcodegen`)
- [ ] Run `xcodegen generate` or `./generate-xcode-project.sh`
- [ ] Open `thiccc.xcodeproj` in Xcode
- [ ] Configure signing (select your team)
- [ ] Build and run (⌘R)
- [ ] 🎉 App launches in simulator!

---

**Ready to deploy?** → See `../TESTFLIGHT-QUICKSTART.md`

