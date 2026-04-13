#!/bin/bash

# OpenCode Skills System Verification Script
# This script verifies the installation and configuration of OpenCode skills

set -e

SKILLS_DIR="$HOME/.config/opencode/skills"
CONFIG_FILE="$HOME/.config/opencode/opencode.json"
SKILLS=("code-reviewer" "performance-optimizer" "docs-generator" "refactoring-expert")

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   OpenCode Skills System - Verification Script            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if skills directory exists
echo "📁 Checking skills directory..."
if [ -d "$SKILLS_DIR" ]; then
    echo "   ✅ Skills directory found: $SKILLS_DIR"
else
    echo "   ❌ Skills directory not found: $SKILLS_DIR"
    exit 1
fi

# Check if main config exists
echo ""
echo "⚙️  Checking main configuration..."
if [ -f "$CONFIG_FILE" ]; then
    echo "   ✅ Config file found: $CONFIG_FILE"
else
    echo "   ❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

# Check each skill
echo ""
echo "🎯 Checking individual skills..."
for skill in "${SKILLS[@]}"; do
    echo ""
    echo "   Checking: $skill"

    skill_dir="$SKILLS_DIR/$skill"

    if [ ! -d "$skill_dir" ]; then
        echo "      ❌ Directory missing: $skill_dir"
        continue
    fi
    echo "      ✅ Directory found"

    # Check config.json
    if [ -f "$skill_dir/config.json" ]; then
        echo "      ✅ config.json found"
        # Try to parse JSON
        if jq . "$skill_dir/config.json" >/dev/null 2>&1; then
            echo "      ✅ config.json is valid JSON"
        else
            echo "      ❌ config.json has invalid JSON"
        fi
    else
        echo "      ❌ config.json not found"
    fi

    # Check instructions.md
    if [ -f "$skill_dir/instructions.md" ]; then
        lines=$(wc -l <"$skill_dir/instructions.md")
        echo "      ✅ instructions.md found ($lines lines)"
    else
        echo "      ❌ instructions.md not found"
    fi

    # Check metadata.json
    if [ -f "$skill_dir/metadata.json" ]; then
        echo "      ✅ metadata.json found"
        if jq . "$skill_dir/metadata.json" >/dev/null 2>&1; then
            echo "      ✅ metadata.json is valid JSON"
        else
            echo "      ❌ metadata.json has invalid JSON"
        fi
    else
        echo "      ❌ metadata.json not found"
    fi
done

# Check documentation files
echo ""
echo "📚 Checking documentation files..."
docs=("AGENTS.md" "ARCHITECTURE.md" "SETUP_SUMMARY.md" "INDEX.md" "skills/README.md")
for doc in "${docs[@]}"; do
    doc_path="$HOME/.config/opencode/$doc"
    if [ -f "$doc_path" ]; then
        lines=$(wc -l <"$doc_path")
        echo "   ✅ $doc ($lines lines)"
    else
        echo "   ❌ $doc not found"
    fi
done

# Verify opencode.json structure
echo ""
echo "🔍 Verifying opencode.json structure..."
if jq . "$CONFIG_FILE" >/dev/null 2>&1; then
    echo "   ✅ opencode.json is valid JSON"

    # Check skills section
    if jq -e '.skills' "$CONFIG_FILE" >/dev/null 2>&1; then
        echo "   ✅ Skills section exists"

        if jq -e '.skills.enabled' "$CONFIG_FILE" >/dev/null 2>&1; then
            enabled=$(jq -r '.skills.enabled' "$CONFIG_FILE")
            echo "   ✅ Skills enabled: $enabled"
        fi

        if jq -e '.skills.available_skills' "$CONFIG_FILE" >/dev/null 2>&1; then
            skill_count=$(jq '.skills.available_skills | length' "$CONFIG_FILE")
            echo "   ✅ Available skills: $skill_count"
        fi
    else
        echo "   ⚠️  Skills section not found in config"
    fi
else
    echo "   ❌ opencode.json has invalid JSON"
fi

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                  ✅ VERIFICATION COMPLETE                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Summary:"
echo "   Skills Directory: $SKILLS_DIR"
echo "   Config File: $CONFIG_FILE"
echo "   Total Skills: ${#SKILLS[@]}"
echo ""
echo "📖 Next Steps:"
echo "   1. Read: ~/.config/opencode/INDEX.md"
echo "   2. Read: ~/.config/opencode/skills/README.md"
echo "   3. Start using: opencode skill [skill-name]"
echo ""
