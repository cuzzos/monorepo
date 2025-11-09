#!/bin/bash

# Script to generate Xcode project for thiccc app
# Run this on your Mac with Xcode installed

set -e

echo "🚀 Generating Xcode project for thiccc..."
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This script must be run on macOS"
    echo "   You're currently on: $OSTYPE"
    echo ""
    echo "📖 Please follow the manual instructions in CREATE-XCODE-PROJECT.md"
    exit 1
fi

# Check if xcodeproj already exists
if [ -d "thiccc.xcodeproj" ]; then
    echo "⚠️  Warning: thiccc.xcodeproj already exists"
    read -p "   Delete and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing old project..."
        rm -rf thiccc.xcodeproj
    else
        echo "❌ Aborted. Remove thiccc.xcodeproj manually if you want to recreate."
        exit 1
    fi
fi

# Check if XcodeGen is installed
if command -v xcodegen &> /dev/null; then
    echo "✅ XcodeGen found!"
    echo "🏗️  Generating Xcode project from project.yml..."
    xcodegen generate
    
    if [ -d "thiccc.xcodeproj" ]; then
        echo ""
        echo "✅ Success! Project created: thiccc.xcodeproj"
        echo ""
        echo "📖 Next steps:"
        echo "   1. Open thiccc.xcodeproj in Xcode"
        echo "   2. Select your Team in Signing & Capabilities"
        echo "   3. Build and run! (⌘R)"
        echo ""
        echo "🚀 Then follow TESTFLIGHT-QUICKSTART.md to deploy"
    else
        echo "❌ Error: Project generation failed"
        exit 1
    fi
else
    echo "⚠️  XcodeGen not found"
    echo ""
    echo "Choose an option:"
    echo ""
    echo "Option 1: Install XcodeGen (Recommended - 1 minute)"
    echo "   brew install xcodegen"
    echo "   Then run this script again"
    echo ""
    echo "Option 2: Manual Setup in Xcode (5 minutes)"
    echo "   Follow the guide in CREATE-XCODE-PROJECT.md"
    echo ""
    
    read -p "Install XcodeGen now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v brew &> /dev/null; then
            echo "🍺 Installing XcodeGen via Homebrew..."
            brew install xcodegen
            
            echo ""
            echo "✅ XcodeGen installed!"
            echo "🏗️  Generating project..."
            xcodegen generate
            
            if [ -d "thiccc.xcodeproj" ]; then
                echo ""
                echo "✅ Success! Project created: thiccc.xcodeproj"
                echo ""
                echo "📖 Next steps:"
                echo "   1. Open thiccc.xcodeproj in Xcode"
                echo "   2. Select your Team in Signing & Capabilities"
                echo "   3. Build and run! (⌘R)"
            fi
        else
            echo "❌ Homebrew not found. Install from: https://brew.sh"
            echo ""
            echo "📖 After installing Homebrew, run:"
            echo "   brew install xcodegen"
            echo "   ./generate-xcode-project.sh"
        fi
    else
        echo ""
        echo "📖 No problem! Follow CREATE-XCODE-PROJECT.md for manual setup"
    fi
fi

exit 0

