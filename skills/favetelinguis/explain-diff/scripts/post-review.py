#!/usr/bin/env python3
"""Post an agreed explain-diff comment list as one GitHub PR review.

Reads the "Suggested review comments" list in the exact format explain-diff
step 6 prints, submits it as a single COMMENT review on the pinned head, then
reads the comments back and checks every anchor landed where the list says.

The host comes from the PR URL, so GitHub Enterprise hosts work without
GH_HOST (`gh api` otherwise defaults to github.com).

Usage:
  post-review.py LIST_FILE             post, then verify
  post-review.py LIST_FILE --dry-run   print the target and payload only
  post-review.py LIST_FILE --verify ID verify an already posted review
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

HEADER = re.compile(r"^PR (https?://([^/\s]+)/([^/\s]+)/([^/\s]+)/pull/(\d+)), head `([0-9a-f]{40})`\s*$")
HEADING = re.compile(
    r"^\*\*(\d+)\. (?:(General)|Line: `([^`]+)` lines? (\d+)(?:-(\d+))? \((LEFT|RIGHT)\))\*\*\s*$"
)
OPEN_FENCE = re.compile(r"^(`{3,})text\s*$")


def fail(message):
    sys.exit(f"post-review: {message}")


def parse(text):
    lines = text.splitlines()
    target = None
    items = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("Local diff, base"):
            fail("this list is for a local diff; there is no PR to post to")
        header = HEADER.match(line)
        if header:
            url, host, owner, repo, number, head = header.groups()
            target = {"url": url, "host": host, "owner": owner, "repo": repo, "number": int(number), "head": head}
        heading = HEADING.match(line)
        if heading:
            number, general, path, start, end, side = heading.groups()
            i += 1
            while i < len(lines) and not lines[i].strip():
                i += 1
            fence = OPEN_FENCE.match(lines[i]) if i < len(lines) else None
            if not fence:
                fail(f"comment {number}: expected a ```text block after its heading")
            ticks = len(fence.group(1))
            body = []
            i += 1
            while i < len(lines) and not re.fullmatch(r"`{%d,}\s*" % ticks, lines[i]):
                body.append(lines[i])
                i += 1
            if i == len(lines):
                fail(f"comment {number}: unclosed ```text block")
            item = {"number": int(number), "body": "\n".join(body)}
            if not general:
                item.update(path=path, side=side, line=int(end or start))
                if end:
                    item["start_line"] = int(start)
            items.append(item)
        i += 1

    if not target:
        fail("no `PR <url>, head `<sha>`` header line found")
    if not items:
        fail("no comments found")
    if [item["number"] for item in items] != list(range(1, len(items) + 1)):
        fail("comments must be numbered 1..n in order")
    generals = [item for item in items if "path" not in item]
    if len(generals) > 1 or (generals and items[0] is not generals[0]):
        fail("at most one general comment, and it must come first")
    for item in items:
        if "start_line" in item and item["start_line"] >= item["line"]:
            fail(f"comment {item['number']}: range start must be below its end")
    return target, items


def payload(target, items):
    review = {"commit_id": target["head"], "event": "COMMENT", "body": "", "comments": []}
    for item in items:
        if "path" not in item:
            review["body"] = item["body"]
            continue
        comment = {"path": item["path"], "line": item["line"], "side": item["side"], "body": item["body"]}
        if "start_line" in item:
            comment.update(start_line=item["start_line"], start_side=item["side"])
        review["comments"].append(comment)
    return review


def gh(target, *args):
    result = subprocess.run(["gh", "api", "--hostname", target["host"], *args], capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    return result.stdout


def pulls(target, suffix=""):
    return f"repos/{target['owner']}/{target['repo']}/pulls/{target['number']}{suffix}"


def anchor(comment):
    lines = f"{comment['start_line']}-{comment['line']}" if comment.get("start_line") else str(comment["line"])
    return f"{comment['path']}:{lines} {comment['side']}"


def post(target, review):
    current = gh(target, pulls(target), "--jq", ".head.sha").strip()
    if current != target["head"]:
        print(f"warning: PR head moved to {current}; anchoring on the reviewed head {target['head']}")
    handle, path = tempfile.mkstemp(prefix="post-review-", suffix=".json")
    with os.fdopen(handle, "w") as file:
        json.dump(review, file)
    try:
        response = json.loads(gh(target, "--method", "POST", pulls(target, "/reviews"), "--input", path))
    except RuntimeError as error:
        fail(f"posting failed: {error}\npayload kept at {path}")
    os.remove(path)
    print(f"posted review {response['id']} ({response['state']}): {response['html_url']}")
    return response["id"]


def verify(target, review, review_id):
    # The per-review comments endpoint reports line as null on some hosts; the
    # PR-wide comments endpoint carries the real anchors.
    pages = json.loads(gh(target, "--paginate", "--slurp", pulls(target, "/comments")))
    posted = [comment for page in pages for comment in page if comment.get("pull_request_review_id") == review_id]
    landed = {anchor(comment) for comment in posted}
    missing = []
    for expected in review["comments"]:
        found = anchor(expected) in landed
        print(f"{'ok  ' if found else 'MISS'} {anchor(expected)}")
        if not found:
            missing.append(anchor(expected))
    if missing or len(posted) != len(review["comments"]):
        fail(f"review {review_id}: anchors differ from the list; landed: {sorted(landed)}")
    print(f"verified {len(posted)} line comment(s) on review {review_id}")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("list_file", help="file holding the agreed Suggested review comments list")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="print the target and payload without posting")
    mode.add_argument("--verify", type=int, metavar="REVIEW_ID", help="verify an already posted review")
    args = parser.parse_args()

    with open(args.list_file) as file:
        target, items = parse(file.read())
    review = payload(target, items)

    if args.dry_run:
        print(f"target: {target['host']} {pulls(target, '/reviews')} at {target['head']}")
        print(json.dumps(review, indent=2, ensure_ascii=False))
        return
    try:
        review_id = args.verify or post(target, review)
        verify(target, review, review_id)
    except RuntimeError as error:
        fail(str(error))


if __name__ == "__main__":
    main()
