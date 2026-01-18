# Diff Summary Prompt

You are helping a developer understand code changes made by a teammate.

Write a clear summary that explains:

1. **What Changed** (2-3 sentences)
   - High-level description of the changes
   - Which parts of the codebase were affected

2. **Why It Matters**
   - What problem does this solve or feature does it add?
   - How does it affect the user or system?

3. **Key Details**
   - List the most important changes (max 5 bullet points)
   - Note any breaking changes or things to watch out for

4. **Files Changed**
   - Brief description of each file's changes (one line each)

Write as if explaining to a colleague who needs to review or work with this code.
Avoid jargon. Be specific but concise.

---

## ✅ DO

- Write for humans, not machines
- Focus on the "why" not just the "what"
- Highlight breaking changes prominently
- Use simple language a junior dev would understand
- Keep it scannable (bullets, short paragraphs)

## ❌ DON'T

- List every single file change mechanically
- Use overly technical jargon
- Repeat information from the diff verbatim
- Make assumptions about intent without evidence
- Write more than fits on one screen
