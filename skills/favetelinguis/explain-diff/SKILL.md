---
name: explain-diff
description: Explain a diff or PR in your own words, get grilled until your model matches the code, and leave with review comments.
disable-model-invocation: true
argument-hint: "[PR number or URL]"
---

Align the human's **mental model** of a change with what the change actually does. A **blind reviewer** reviews the change knowing nothing of the model, a **comparison reviewer** sets both against the model, a grilling closes every gap, and the human leaves with review comments ready to post. The blind reviewer's independence is the point: the mental model goes to the comparison reviewer only.

The reviews stay **sealed** until the grilling reaches them. When a reviewer returns, tell the human only that it finished. A finding reaches the human only as an answer key, after they have answered the question it belongs to.

Start every sub-agent with a fresh context window.

## Process

### 1. Pin the change

The argument picks the **change**. Either way it ends as a base commit, a head commit, and a detached worktree at the head, so every reviewer reads files as the change leaves them and the human's checkout stays as it is.

- **No argument** means the current diff: everything the current branch would bring if merged now, committed or not. Take the default branch from `git symbolic-ref --short refs/remotes/origin/HEAD` (fall back to `gh repo view --json defaultBranchRef`); base is `git merge-base <default> HEAD`. Head is a snapshot of the working tree, untracked files included, built through a temporary index so the real index is untouched:

  ```bash
  index=$(mktemp)
  cp "$(git rev-parse --git-path index)" "$index"
  GIT_INDEX_FILE=$index git add -A
  head=$(git commit-tree "$(GIT_INDEX_FILE=$index git write-tree)" -p HEAD -m "explain-diff snapshot")
  rm "$index"
  ```

- **A PR number or URL**: read it with `gh pr view <arg> --json number,url,baseRefName,headRefOid`. The PR must belong to the repository checked out here (compare against `gh repo view --json nameWithOwner`); when it belongs elsewhere, tell the human to rerun from a checkout of that repository and stop. Fetch both sides with `git fetch origin "+refs/heads/<baseRefName>:refs/remotes/origin/<baseRefName>" "pull/<number>/head"`. Head is `headRefOid`; base is `git merge-base origin/<baseRefName> <head>`.

Then `git worktree add --detach "$(mktemp -d)" <head>`. The diff command for every reviewer is `git -C <worktree> diff <base>...HEAD`.

Done when `git diff --stat <base> <head>` is non-empty. An empty diff means there is nothing to explain: say so, remove the worktree, and stop.

### 2. Start the blind review

Dispatch the blind reviewer now, before the human says anything about the change, and continue to step 3 while it runs. Its prompt carries:

- The worktree path, with the instruction to work only inside it.
- The instruction to call the Skill tool with "production-readiness-check", using `<base>` as the fixed point.
- The tracker doc path and, for a PR, the PR URL, so production-readiness-check can find the originating spec.
- The human is out of reach: where production-readiness-check would ask the user, take its "no spec available" branch. If the reviewer cannot dispatch sub-agents of its own, it runs each axis (Standards, Spec, Production, and Integration when it applies) one after the other, each in its own section.
- The brief: "Return the production-readiness-check report as production-readiness-check presents it."

### 3. Take the mental model

Ask the human these three, then stop and wait:

1. **What**: what is this change about, and what do you expect it to do?
2. **How**: how is it implemented? Where do the main pieces live, and how do they fit together?
3. **Worries**: is there anything in particular you are worried about?

Keep the answers verbatim as the mental model. "I don't know" is a valid answer: it marks the edge of what the human knows. Done when all three are answered; ask once more for any the human skipped.

### 4. Compare

When the blind review returns, dispatch the comparison reviewer with the worktree path, the diff command, the mental model verbatim, and the blind review report verbatim. The brief:

"Review every hunk of the diff yourself and write your own account of what the change does and how. Then check each blind review finding against the code: confirm or dismiss it with file:line evidence. Then compare your account and the confirmed findings with the mental model and return:

- **Anchors**: what the mental model gets right, each with file:line evidence.
- **Gaps**, ordered so a gap's prerequisites come before it. Each gap carries its kind, file:line evidence with the hunk quoted, the answer key, and whether the code or the model looks wrong. The kinds:
  - **misunderstanding**: the model misreads what the code does.
  - **blind spot**: the code does something the model leaves out.
  - **unmet expectation**: the model expects something the code lacks.
  - **worry**: one the human raised, confirmed or dismissed.
  - **issue**: a confirmed review finding the model does not account for.

Under 600 words."

Done when every gap in the list has evidence and an answer key.

### 5. Grill to alignment

Call the Skill tool with "grilling". The gaps are the design tree and the anchors are settled ground. On top of grilling:

- **Zone of proximal development**: every question starts from an anchor or a closed gap and reaches one step past it. A wrong or blank answer means the step was too long: ask a smaller question in between. A confident right answer means move ahead faster.
- **Understanding questions** close misunderstandings and blind spots. Point at the hunk (path:line), ask the human to explain or predict what it does, and keep the answer key back until they have answered; then confirm or correct with the evidence. These take the place of grilling's recommended answer. You still look up every fact yourself; what the human supplies is reasoning.
- **Decision questions** close unmet expectations, confirmed worries, and issues, in grilling's format with a recommended answer: fix it in this change, track it as a follow-up ticket, or accept it as is.
- When the human's answer shows the code is wrong and the model is right, the gap becomes an issue and goes to a decision question.

Done when every gap is closed: each misunderstanding and blind spot restated correctly in the human's own words, each issue, unmet expectation, and worry carrying a decision.

### 6. Agree the review comments

Draft the **suggested review comments**: one per gap decided "fix it in this change" or "track it as a follow-up ticket", plus at most one general comment for what belongs to the change as a whole. Write each body exactly as the human would post it, in their voice, ready to paste.

Anchor each comment so it can be posted with `gh` as it stands:

- A **line comment** carries the path from the repository root, the line (or `start-end` range), and the side: `RIGHT` with the head line number for added or unchanged lines, `LEFT` with the base line number for deleted lines. Read the numbers from the worktree diff. The line must sit inside a diff hunk, since GitHub only accepts line comments there; a remark on a line outside every hunk goes in a general comment with `path:line` in its body.
- A **general comment** carries no anchor.

Present the list in this form, numbered from 1, general comments first:

````markdown
## Suggested review comments

PR <url>, head `<headRefOid>`

**1. General**

```text
<body>
```

**2. Line: `src/orders/service.ts` line 42 (RIGHT)**

```text
<body>
```

**3. Line: `src/orders/service.ts` lines 40-45 (RIGHT)**

```text
<body>
```
````

For the current diff with no PR, the header line is `Local diff, base <base>`: the anchors hold for the working tree as it stands now.

The human edits by number ("change 3 to ...", "remove 2", "add a line comment on ...", several in one message). Apply every edit, renumber from 1, and reprint the full list in every reply, with nothing beside it but a question for an edit you could not apply. Done when the human agrees the list. Remove the worktree with `git worktree remove --force <worktree>`. The agreed list is the output; posting it is the human's next step. When the human asks you to post it, save the list verbatim to a file and run [`scripts/post-review.py`](scripts/post-review.py) `<file>`: it posts one `COMMENT` review on the pinned head to the PR URL's host, then verifies every anchor. Check the payload with `--dry-run` first.
