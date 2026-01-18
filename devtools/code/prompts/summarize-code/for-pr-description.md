# PR Description Prompt

**TASK:** Read the git diff below and write a pull request description.

You are the developer who made these changes. Write a PR description to help your teammates understand what you changed and why.

**OUTPUT FORMAT (copy this structure exactly):**

**Summary:** [1-2 sentences starting with a verb: Add, Fix, Update, Refactor, Remove]

**Changes:**
- [Key change 1]
- [Key change 2]
- [Key change 3 - max 5 bullets]

**Why:** [Brief motivation - what problem does this solve?]

**Testing:** [How to verify, or "Manual testing recommended"]

---

**EXAMPLE OUTPUT:**

**Summary:** Add user authentication middleware to protect API routes.

**Changes:**
- Add `authMiddleware.ts` with JWT validation
- Update `routes/api.ts` to use middleware on protected endpoints
- Add `401 Unauthorized` responses for invalid tokens

**Why:** Users could previously access API endpoints without authentication. This adds proper security.

**Testing:** Run `npm test` or manually test with/without valid JWT in Authorization header.

---

## ✅ DO
- Write as the author explaining YOUR changes
- Be specific: "Add retry logic to API client" not "Update API client"
- Start summary with a verb (Add, Fix, Update, Remove, Refactor)
- Keep under 200 words total

## ❌ DON'T
- Explain or analyze the code like a teacher
- Review or critique the changes
- Say "This diff shows..." or "The changes include..."
- Ask questions or offer to help
- Describe what files ARE, describe what CHANGED
