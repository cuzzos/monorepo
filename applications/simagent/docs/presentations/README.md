# SimAgent Presentations

This folder contains presentation materials for SimAgent.

## Available Decks

### Technical Co-Founder Deck
**File:** `technical-cofounder-deck.md`  
**Format:** Marp (Markdown Presentation)  
**Audience:** Technical co-founder candidates  
**Length:** ~20 slides  
**Focus:** Technical architecture, market opportunity, product roadmap, unit economics

---

## How to View/Present

### Option 1: Marp CLI (Recommended)

**Install Marp:**
```bash
npm install -g @marp-team/marp-cli
```

**Generate HTML:**
```bash
cd /Users/eganm/personal/cuzzo_monorepo/applications/simagent/docs/presentations
marp technical-cofounder-deck.md -o technical-cofounder-deck.html
open technical-cofounder-deck.html
```

**Generate PDF:**
```bash
marp technical-cofounder-deck.md -o technical-cofounder-deck.pdf --pdf
```

**Present mode (live):**
```bash
marp -s technical-cofounder-deck.md
# Opens browser at http://localhost:8080
```

---

### Option 2: Marp for VS Code

**Install extension:**
1. Open VS Code
2. Search for "Marp for VS Code" in extensions
3. Install it
4. Open `technical-cofounder-deck.md`
5. Click "Open Preview" (top right icon)
6. Press F5 to present

---

### Option 3: Export to PowerPoint/Keynote

**Via Marp CLI:**
```bash
marp technical-cofounder-deck.md -o deck.pptx --pptx
```

Then open in PowerPoint/Keynote and customize styling as needed.

---

## Customizing the Deck

### Change Theme

Edit the frontmatter in the markdown file:

```yaml
---
marp: true
theme: gaia  # or: default, uncover
paginate: true
---
```

### Add Images

```markdown
![bg](./path/to/image.png)  # Background image
![width:500px](./logo.png)  # Inline image with width
```

### Two-Column Layout

```markdown
<div style="display: flex;">
<div style="flex: 1;">

Left column content

</div>
<div style="flex: 1;">

Right column content

</div>
</div>
```

---

## Tips for Presenting

1. **Technical co-founder audience:**
   - Deep dive on architecture slides
   - Be ready to whiteboard smart test selection flow
   - Emphasize the technical moat

2. **Keep slide deck open in preview:**
   - Edit markdown live
   - Changes reflect immediately
   - Iterate based on questions

3. **Have docs ready:**
   - Link to `/docs/brainstorming/` for deep dives
   - Show actual code examples if asked
   - Reference research papers in `/docs/research/`

---

## Future Decks to Create

- **Investor Deck** (VC/Angel) - Focus on market, traction, team
- **Customer Demo Deck** (Sales) - Focus on problem/solution, pricing, ROI
- **Partner Deck** (GitHub, GitLab) - Focus on integration, shared customers
- **Conference Talk** (Developer audience) - Focus on technical deep dive, live demo

---

## Notes

- All numbers in deck are sourced from `/docs/brainstorming/financial/`
- Competitive analysis from `/docs/brainstorming/stakeholder-perspectives/`
- Technical details from `/docs/brainstorming/technical/`
- Update deck if source documents change

