# TestFlight Quick Start Checklist

A condensed checklist to get your app to TestFlight fast.

## ✅ Pre-Flight Checklist

### One-Time Setup (Do Once)
- [x] Enroll in Apple Developer Program ($99/year)
  - https://developer.apple.com/programs/
  - **Wait time**: 1 business day for approval
- [x] Create app icon: 1024x1024 PNG
- [x] Write simple privacy policy (required for TestFlight)
  - Can be: "This app does not collect any user data"
  - Host on GitHub Pages, Google Docs (make public), or use generator

---

## 🚀 Launch Sequence

### 1️⃣ Xcode Setup (15 minutes)

**Initial setup (one-time):**

```bash
# On your Mac - Run the setup script
cd /path/to/thiccc
./setup-mac.sh

# This installs Rust, XcodeGen, builds libraries, and generates Xcode project
```

**Then open the project:**

```bash
cd app/ios
open thiccc/Thiccc.xcodeproj
```

**In Xcode:**
- [ ] Select project → Target "Thiccc" → General tab
- [ ] Set **Bundle Identifier**: `com.thiccc.app` (or your domain)
- [ ] Set **Version**: `1.0.0`
- [ ] Set **Build**: `1`
- [ ] Verify **Deployment Target**: iOS 18.0
- [ ] Go to **Signing & Capabilities** tab
- [ ] ✅ Check "Automatically manage signing"
- [ ] Select your **Team** (Apple Developer account)
- [ ] Add app icon to `Assets.xcassets` → `AppIcon`

### 2️⃣ Create App in App Store Connect (10 minutes)

1. Go to: https://appstoreconnect.apple.com/
2. **My Apps** → **+** → **New App**
3. Fill in:
   - **Name**: "thiccc"
   - **Bundle ID**: `com.thiccc.app`
   - **SKU**: `THICCC001`
4. Click **Create**
5. Go to **App Information**
6. Add **Privacy Policy URL**

### 3️⃣ Build & Archive (10 minutes)

**In Xcode:**
- [ ] Select **Any iOS Device (arm64)** from device dropdown
- [ ] Menu: **Product** → **Clean Build Folder** (⇧⌘K)
- [ ] Menu: **Product** → **Archive**
- [ ] Wait for Organizer to open

### 4️⃣ Upload to TestFlight (15 minutes)

**In Organizer:**
- [ ] Select your archive
- [ ] Click **Validate App** → wait for success
- [ ] Click **Distribute App**
- [ ] Choose **App Store Connect** → **Upload**
- [ ] Click through prompts → **Upload**
- [ ] Wait for "Upload Successful"

### 5️⃣ Wait for Processing (10-30 minutes)

- [ ] Go to App Store Connect → **TestFlight** tab
- [ ] Watch for build status: "Processing" → "Ready to Submit"
- [ ] Check email for completion notification
- [ ] Answer **Export Compliance** question (usually "No" for basic apps)

### 6️⃣ Add Testers (5 minutes)

**Internal Testers (immediate access):**
- [ ] TestFlight tab → **Internal Testing**
- [ ] Click **+** next to "Internal Testers"
- [ ] Enter email addresses
- [ ] Testers receive invite immediately

**External Testers (1-2 day review):**
- [ ] TestFlight tab → **External Testing**
- [ ] Create a group → Add testers
- [ ] Fill in test information
- [ ] Submit for review
- [ ] Wait for Apple approval

### 7️⃣ Testers Install (5 minutes)

**Send these instructions to testers:**

1. Install TestFlight: https://apps.apple.com/app/testflight/id899247664
2. Open invitation email on iPhone/iPad
3. Tap "View in TestFlight"
4. Tap "Install" in TestFlight app
5. Open "thiccc" from home screen

---

## 🔄 Updating Your App

When you make changes:

**In Xcode:**
- [ ] Increment **Build** number (`1` → `2` → `3`, etc.)
- [ ] Product → Clean Build Folder
- [ ] Product → Archive
- [ ] Validate & Upload (same as steps 4-5 above)

Testers get automatic notification in TestFlight!

---

## ⚠️ Common Gotchas

| Problem | Solution |
|---------|----------|
| "Archive" grayed out | Select "Any iOS Device" not a simulator |
| Signing errors | Use "Automatically manage signing" |
| Processing stuck | Wait 30 min, check email for issues |
| Testers can't install | Make sure they have TestFlight app installed |
| Build rejected | Check email, usually privacy policy missing |

---

## 📊 Timeline

| Milestone | Time |
|-----------|------|
| Developer account approval | 1 day |
| First-time setup | 1 hour |
| Build & upload | 30 minutes |
| Processing | 10-30 minutes |
| Internal testing ready | **Immediate** |
| External testing approved | 1-2 days |

---

## 💰 Costs

- **Apple Developer Account**: $99/year
- **TestFlight**: Free
- **Total**: **$99/year**

---

## 🆘 Need Help?

- **Full guide**: See `TESTFLIGHT-GUIDE.md` in this folder
- **Apple Forums**: https://developer.apple.com/forums/
- **TestFlight Docs**: https://developer.apple.com/testflight/

---

## 🎯 Success Criteria

You're done when:
- ✅ Build shows "Ready to Test" in TestFlight
- ✅ Testers receive invitation email
- ✅ Testers can install and open app
- ✅ You can see feedback in TestFlight

**Then**: Iterate based on feedback! 🚀

