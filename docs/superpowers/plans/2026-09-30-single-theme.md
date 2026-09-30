# Single Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the `blog` theme the only theme on the site and delete the `english` and `swedish` themes and everything that exists only to select them.

**Architecture:** Today `_includes/theme-selector.liquid` picks one of three stylesheets per page. It reads `theme:` front matter, which 649 archived course pages (2013-2014 to 2019-2020) set to `english` or `swedish`, and page `tags` (a dead branch: no page has `tags:`, and posts use `layout: none`). We replace the selector with fixed blog `<link>`s in `head.liquid`, give the header one owl, then delete the unused Less sources, compiled CSS, owl images and npm scripts, and finally strip the now-ignored `theme:` lines from front matter.

**Tech Stack:** Jekyll 3.10 via the `github-pages` gem (Liquid 4, `safe: true`), Less 4 + clean-css via npm scripts, Bootstrap 3.4.1 (vendored), asdf for Ruby/Node (`.tool-versions`).

**Spec:** No separate spec. The request was: "remove all other color themes from site and keep current (blog?) theme as the only theme for all pages." `blog` is the right theme to keep. It is the default in `theme-selector.liquid` and is already used by the front page, `/blogi/`, `404.html` and every course page from 2020-2021 on.

## Global Constraints

- The blog theme must not change. `themes/blog/css/styles.css` and `styles.min.css` stay byte-identical, and pages that already use blog render the same HTML apart from whitespace.
- Keep the existing paths: `/themes/blog/css/styles.min.css`, `/img/owl-blog.png`, `less/blog/`. Don't flatten or rename anything in this plan.
- Don't edit `less/bootstrap/` (vendored unmodified).
- GitHub Pages builds with `safe: true`, so add no plugins.
- Every file uses LF line endings.
- Build with `bundle exec jekyll build` using the asdf Ruby from `.tool-versions`. Don't use Docker.
- Commit compiled CSS together with any Less change.
- Work on the branch `worktree-single-theme` and never push to `master`: merging deploys the site. Pages CMS and bots commit to `master`, so rebase onto `origin/master` before pushing.
- The 649 archived pages will switch to the blog colours, fonts and owl. That is the intended result, not a regression.

## Review Focus

1. **Archived English pages** (121 files under `kurssit/2013-2014/ena*`) had a serif body font, News Cycle and their own owl. They must link the blog stylesheet, the Lobster + Cabin fonts and `owl-blog.png`. `check-theme.sh` checks `kurssit/2013-2014/ena1/index.html` (Task 1).
2. **Phone header:** `less/common.less:92` hides the owl on phones with `.author + .owl`, so on non-course pages the owl div must stay the next sibling of the author div after the header is restructured. `check-theme.sh` checks this on `/`, `/blogi/` and `404.html` (Task 1).
3. **Dangling references to deleted files** anywhere in the built site, including CSS, `404.html` and redirect stubs. Checked with a site-wide grep for `/themes/<name>/` and `owl-<name>.png` (Task 2).
4. **The blog CSS changing when the npm script is rewritten.** Checked with `npm run build:css` followed by `git diff --exit-code themes/blog` (Task 2).
5. **The front-matter edit on 651 files touching anything else** (body text, line endings, trailing newlines). Checked with `git diff --numstat` and a tally of the changed lines, and the built site must be byte-identical (Task 3).

## Scratch space

Every verification step builds into `/tmp/single-theme-check/`, outside the repo. Use literal paths as written; some agent harnesses refuse commands that build paths from shell variables. In a Claude background job you may substitute `$CLAUDE_JOB_DIR/tmp/single-theme-check/`, but do it consistently in every step.

## File map

| Path | Change | Task |
|---|---|---|
| `_includes/theme-selector.liquid` | delete | 1 |
| `_includes/head.liquid` | inline the blog font and stylesheet links | 1 |
| `_includes/header.liquid` | one owl div, always `owl-blog.png` | 1 |
| `_layouts/{default,content-main,content-posts,home}.html` | drop `theme=page_theme` | 1 |
| `CLAUDE.md` (Theme bullet) | describe the single theme | 1 |
| `less/english/`, `less/swedish/` | delete | 2 |
| `themes/english/`, `themes/swedish/` | delete | 2 |
| `img/owl-english.png`, `img/owl-swedish.png` | delete | 2 |
| `package.json` | one `build:css` script | 2 |
| `less/bootstrap-overrides.less:5-8` | comment says "the theme" | 2 |
| `CLAUDE.md` (build:css bullet) | describe the single build | 2 |
| 651 pages with `theme:` front matter | delete the `theme:` line | 3 |

---

### Task 1: Serve the blog theme on every page

**Files:**
- Delete: `_includes/theme-selector.liquid`
- Modify: `_includes/head.liquid:13-14`
- Modify: `_includes/header.liquid` (whole file, 19 lines)
- Modify: `_layouts/default.html:8`, `_layouts/content-main.html:8`, `_layouts/content-posts.html:8`, `_layouts/home.html:8`
- Modify: `CLAUDE.md` (the bullet starting `- Theme:`)
- Test: `/tmp/single-theme-check/check-theme.sh` (scratch, not committed)

**Interfaces:**
- Consumes: nothing.
- Produces: no Liquid variable `page_theme` and no `theme` include parameter. Tasks 2 and 3 rely on nothing reading `page.theme`, `page_theme` or `include.theme`.

- [ ] **Step 1: Build the baseline site and the list of themed pages**

Run from the repo root before editing anything:

```bash
mkdir -p /tmp/single-theme-check
bundle exec jekyll build --destination /tmp/single-theme-check/site-before
git grep -lE '^theme: (english|swedish)$' | sed -E 's/\.md$/.html/' | sort > /tmp/single-theme-check/expected.txt
wc -l < /tmp/single-theme-check/expected.txt
```

Expected: the build ends with `done in ~20 seconds`, and the count is `649`.

- [ ] **Step 2: Write the check script**

Create `/tmp/single-theme-check/check-theme.sh`:

```sh
#!/bin/sh
# Usage: check-theme.sh <built site dir>
# Exits 0 when every page uses the blog theme and the header keeps .owl right after .author.
site="$1"
fail=0

if grep -rlE --include='*.html' 'themes/(english|swedish)|owl-(english|swedish)|family=(News\+Cycle|Ubuntu)' "$site" | head -5 | grep .; then
  echo "FAIL: pages above (first 5) still use english/swedish theme assets"; fail=1
fi

for p in kurssit/2013-2014/ena1/index.html kurssit/2018-2019/rub6.4/index.html kurssit/2026-2027/rub11-12.3/index.html blogi/index.html index.html 404.html; do
  grep -q 'href="/themes/blog/css/styles.min.css"' "$site/$p" || { echo "FAIL: $p lacks the blog stylesheet"; fail=1; }
  grep -q 'family=Lobster&family=Cabin' "$site/$p" || { echo "FAIL: $p lacks the blog fonts"; fail=1; }
  grep -q 'src="/img/owl-blog.png"' "$site/$p" || { echo "FAIL: $p lacks the blog owl"; fail=1; }
done

# less/common.less hides the owl on phones with `.author + .owl`, so on
# non-course pages the owl div must directly follow the author div.
for p in blogi/index.html index.html 404.html; do
  tr -d ' \n' < "$site/$p" | grep -q 'Koskenranta</a></h1></div><divclass="owl">' || { echo "FAIL: $p: .owl no longer follows .author"; fail=1; }
done

[ "$fail" = 0 ] && echo "PASS"
exit $fail
```

- [ ] **Step 3: Run the check against the baseline to see it fail**

Run: `sh /tmp/single-theme-check/check-theme.sh /tmp/single-theme-check/site-before; echo "exit=$?"`

Expected (the first five paths may vary):

```
…/site-before/kurssit/2018-2019/rub6.4/kotitehtavat/index.html
… (4 more paths)
FAIL: pages above (first 5) still use english/swedish theme assets
FAIL: kurssit/2013-2014/ena1/index.html lacks the blog stylesheet
FAIL: kurssit/2013-2014/ena1/index.html lacks the blog fonts
FAIL: kurssit/2013-2014/ena1/index.html lacks the blog owl
FAIL: kurssit/2018-2019/rub6.4/index.html lacks the blog stylesheet
FAIL: kurssit/2018-2019/rub6.4/index.html lacks the blog fonts
FAIL: kurssit/2018-2019/rub6.4/index.html lacks the blog owl
exit=1
```

- [ ] **Step 4: Put the blog links in `head.liquid` and delete the selector**

In `_includes/head.liquid`, replace lines 13-14:

```liquid
{% comment %} Sets page_theme, and page_nav/page_courses for course pages. The layouts pass them to the header and navigation. {% endcomment %}
{% include theme-selector.liquid %}
```

with:

```liquid
<link rel="stylesheet"
      href="https://fonts.googleapis.com/css2?family=Lobster&family=Cabin:wght@400;700&display=swap">
<link rel="stylesheet" href="/themes/blog/css/styles.min.css">

{% comment %} Sets page_nav/page_courses for course pages. The layouts pass them to the header and navigation. {% endcomment %}
```

Keep the `{% if page.course %}` block that follows. Then run:

```bash
git rm _includes/theme-selector.liquid
```

- [ ] **Step 5: Give the header a single owl**

Replace the whole of `_includes/header.liquid` with the following (the file has no trailing newline; keep it that way):

```liquid
<header class="header">
    <div class="container">
        <div class="wrapper">
            {% if page.course %}
            {% include course-description.liquid courses=page_courses %}
            {% else %}
            <div class="author">
                <h1><a href="/">Riikka Koskenranta</a></h1>
            </div>
            {% endif %}
            <div class="owl">
                <a href="/"><img src="/img/owl-blog.png" alt="" height="88" width="90" /></a>
            </div>
        </div>
    </div>
</header>
```

- [ ] **Step 6: Drop the `theme` parameter from the layouts**

```bash
sed -i '' 's/{% include header.liquid theme=page_theme %}/{% include header.liquid %}/' _layouts/default.html _layouts/content-main.html _layouts/content-posts.html _layouts/home.html
git grep -nE 'page_theme|page\.theme|include\.theme|theme-selector' -- _includes _layouts
```

Expected: `git grep` prints nothing. (`sed -i ''` is BSD/macOS syntax; on GNU sed use `sed -i`.)

- [ ] **Step 7: Update the Theme bullet in `CLAUDE.md`**

Replace this bullet:

```markdown
- Theme: `_includes/theme-selector.liquid` picks the `blog`, `english` or `swedish` stylesheet from `page.theme`, or from `page.tags` (`ena` → english, `rub` → swedish). The default is `blog`. It sets `page_theme`, which the layouts pass to `header.liquid` for the owl image. Course pages from 2020-2021 on set neither, so they use `blog`; the owner wants it that way, so don't add `theme:` to them.
```

with:

```markdown
- Theme: the site has one theme, `blog`. `_includes/head.liquid` links its Google Fonts (Lobster, Cabin) and `/themes/blog/css/styles.min.css` on every page, and `header.liquid` always shows `/img/owl-blog.png`. The old `english` and `swedish` themes were removed on purpose, so nothing reads `theme:` front matter; don't add it back.
```

- [ ] **Step 8: Build and run the check to see it pass**

```bash
bundle exec jekyll build --destination /tmp/single-theme-check/site-task1
sh /tmp/single-theme-check/check-theme.sh /tmp/single-theme-check/site-task1; echo "exit=$?"
```

Expected: `PASS` and `exit=0`.

- [ ] **Step 9: Diff the whole site against the baseline**

`sitemap.xml` stamps the build time, so it is excluded. On Apple's `diff`, `-w -B` alone does not hide whitespace-only lines, so `-I '^[[:space:]]*$'` is required. Without it, all 1,061 pages show one spurious change each.

```bash
cd /tmp/single-theme-check
diff -r -w -B -I '^[[:space:]]*$' -x sitemap.xml site-before site-task1 > task1.diff
grep '^diff ' task1.diff | awk '{print $NF}' | sed 's#^site-task1/##' | sort > changed.txt
if diff expected.txt changed.txt > /dev/null; then echo "SAME FILE SET"; else echo "FILE SETS DIFFER"; fi
grep -c '^Only in' task1.diff
grep -E '^[<>]' task1.diff | sed -E 's/^([<>]) +/\1 /' | sort | uniq -c
cd -
```

Expected (measured on a prototype of this task):

```
SAME FILE SET
0
 121 < <a href="/"><img src="/img/owl-english.png" alt="" height="88" width="90" /></a>
 528 < <a href="/"><img src="/img/owl-swedish.png" alt="" height="88" width="90" /></a>
 121 < <link rel="stylesheet" href="/themes/english/css/styles.min.css">
 528 < <link rel="stylesheet" href="/themes/swedish/css/styles.min.css">
 121 < href="https://fonts.googleapis.com/css2?family=News+Cycle:wght@400;700&display=swap">
 528 < href="https://fonts.googleapis.com/css2?family=Ubuntu&display=swap">
 649 > <a href="/"><img src="/img/owl-blog.png" alt="" height="88" width="90" /></a>
 649 > <link rel="stylesheet" href="/themes/blog/css/styles.min.css">
 649 > href="https://fonts.googleapis.com/css2?family=Lobster&family=Cabin:wght@400;700&display=swap">
```

This shows that only the 649 themed pages changed, and only in their fonts, stylesheet and owl. Every other page, the phone owl markup included, is unchanged.

- [ ] **Step 10: Check it visually**

Run `bundle exec jekyll serve` and open these pages at desktop width and at 375 px (phone):

- http://localhost:4000/kurssit/2013-2014/ena1/ (was the English theme)
- http://localhost:4000/kurssit/2018-2019/rub6.4/ (was the Swedish theme)
- http://localhost:4000/kurssit/2026-2027/rub11-12.3/ (already blog; the reference)

Expected: all three look alike: purple header (`#5b527f`), beige background (`#ebd8b7`), Lobster headings, the blog owl, and at phone width the owl still shows on course pages. Also open http://localhost:4000/blogi/ at 375 px: the owl is hidden there. Stop the server afterwards.

- [ ] **Step 11: Commit**

```bash
git add -A _includes _layouts CLAUDE.md
git commit -m "$(cat <<'EOF'
Use the blog theme on every page

Archived 2013-2020 course pages picked the English or Swedish theme
through theme: front matter. Link the blog stylesheet and owl
everywhere instead.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Delete the English and Swedish theme files

**Files:**
- Delete: `less/english/` (`custom.less`, `main.less`, `variables.less`), `less/swedish/` (same three), `themes/english/css/styles{,.min}.css`, `themes/swedish/css/styles{,.min}.css`, `img/owl-english.png`, `img/owl-swedish.png`
- Modify: `package.json` (`scripts`)
- Modify: `less/bootstrap-overrides.less:5-8` (comment only)
- Modify: `CLAUDE.md` (the bullet starting ``- `npm run build:css` ``)

**Interfaces:**
- Consumes: from Task 1, no template references `themes/english`, `themes/swedish`, `owl-english` or `owl-swedish`.
- Produces: `npm run build:css` is the only CSS build script and builds `themes/blog/css/styles.css` and `styles.min.css`.

- [ ] **Step 1: Write the failing check for leftover theme files**

```bash
ls less themes; ls img | grep owl
```

Expected now: `less` lists `blog bootstrap bootstrap-overrides.less common.less english swedish`, `themes` lists `blog english swedish`, and there are three owl files. After this task only `blog` (plus the shared Less files) and `owl-blog.png` should remain.

- [ ] **Step 2: Delete the files**

```bash
git rm -r less/english less/swedish themes/english themes/swedish img/owl-english.png img/owl-swedish.png
```

- [ ] **Step 3: Replace the npm scripts**

In `package.json`, replace the whole `"scripts"` object:

```json
  "scripts": {
    "build:css": "npm run build:css:blog && npm run build:css:english && npm run build:css:swedish",
    "build:css:blog": "lessc less/blog/main.less themes/blog/css/styles.css && cleancss -o themes/blog/css/styles.min.css themes/blog/css/styles.css",
    "build:css:english": "lessc less/english/main.less themes/english/css/styles.css && cleancss -o themes/english/css/styles.min.css themes/english/css/styles.css",
    "build:css:swedish": "lessc less/swedish/main.less themes/swedish/css/styles.css && cleancss -o themes/swedish/css/styles.min.css themes/swedish/css/styles.css"
  },
```

with:

```json
  "scripts": {
    "build:css": "lessc less/blog/main.less themes/blog/css/styles.css && cleancss -o themes/blog/css/styles.min.css themes/blog/css/styles.css"
  },
```

- [ ] **Step 4: Make the overrides comment singular**

In `less/bootstrap-overrides.less`, replace lines 5-8:

```less
// The themes were designed on a Bootstrap 3.0 release candidate. Bootstrap
// 3.4 changed some defaults the design relies on; these restore the old
// values. Loaded after Bootstrap's variables and before each theme's own
// variables.less, so a theme can still override them.
```

with:

```less
// The theme was designed on a Bootstrap 3.0 release candidate. Bootstrap
// 3.4 changed some defaults the design relies on; these restore the old
// values. Loaded after Bootstrap's variables and before the theme's own
// variables.less, so the theme can still override them.
```

(`//` comments never reach the compiled CSS.)

- [ ] **Step 5: Update the build bullet in `CLAUDE.md`**

Replace this bullet:

```markdown
- `npm run build:css`: compile `less/{blog,english,swedish}/main.less` with `lessc`, then minify with `cleancss`, into `themes/<theme>/css/styles.css` and `styles.min.css`. GitHub Pages doesn't build CSS, so commit the compiled CSS with any Less change. `npm run build:css:swedish` (or `:blog`, `:english`) builds one theme. Each `main.less` imports Bootstrap 3.4.1 from `less/bootstrap` (vendored unmodified), then `less/bootstrap-overrides.less`, then the theme's `variables.less`. The last definition of a Less variable wins, so the overrides file restores the Bootstrap 3.0 RC defaults the themes were designed on, and a theme can still override both.
```

with:

```markdown
- `npm run build:css`: compile `less/blog/main.less` with `lessc`, then minify with `cleancss`, into `themes/blog/css/styles.css` and `styles.min.css`. GitHub Pages doesn't build CSS, so commit the compiled CSS with any Less change. `main.less` imports Bootstrap 3.4.1 from `less/bootstrap` (vendored unmodified), then `less/bootstrap-overrides.less`, then `less/blog/variables.less`. The last definition of a Less variable wins, so the overrides file restores the Bootstrap 3.0 RC defaults the theme was designed on, and `variables.less` can still override both.
```

- [ ] **Step 6: Rebuild the CSS and confirm the blog output is unchanged**

A fresh worktree has no `node_modules`, so install first:

```bash
npm ci
npm run build:css
git diff --exit-code themes/blog && echo "blog CSS unchanged"
git status --short themes
```

Expected: `blog CSS unchanged`, and `git status` shows only the deletions under `themes/english` and `themes/swedish`. (A prototype confirmed that the current `lessc`/`cleancss` rebuild reproduces the committed blog CSS byte for byte.)

- [ ] **Step 7: Build the site and check for dangling references**

```bash
bundle exec jekyll build --destination /tmp/single-theme-check/site-task2
sh /tmp/single-theme-check/check-theme.sh /tmp/single-theme-check/site-task2; echo "exit=$?"
diff -rq -x sitemap.xml /tmp/single-theme-check/site-task1 /tmp/single-theme-check/site-task2
grep -rhoE '/themes/[a-z]+/' /tmp/single-theme-check/site-task2 | sort | uniq -c
grep -rhoE 'owl-[a-z]+\.png' /tmp/single-theme-check/site-task2 | sort | uniq -c
```

Expected:
- `PASS` and `exit=0`.
- `diff -rq` prints exactly four lines: `Only in …/site-task1/themes: english`, `Only in …/site-task1/themes: swedish`, `Only in …/site-task1/img: owl-english.png`, `Only in …/site-task1/img: owl-swedish.png`.
- The two greps list only `/themes/blog/` and `owl-blog.png`.

- [ ] **Step 8: Commit**

```bash
git add -A less themes img package.json CLAUDE.md
git commit -m "$(cat <<'EOF'
Remove the English and Swedish themes

No page links them any more. Delete their Less sources, compiled CSS
and owl images, and reduce the npm scripts to a single build:css.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Drop `theme:` front matter

After Task 1 nothing reads `theme:`, so the 651 lines left in front matter are dead: 528 `theme: swedish` and 121 `theme: english` in `kurssit/2013-2014` … `kurssit/2019-2020`, plus `theme: blog` in `404.html` and `blogi/index.html`. Leaving them would suggest to the next editor that themes still work. All of them are at line 4, inside the front matter, and none of the files contain CRLF (both checked while writing this plan).

**Files:**
- Modify: the 651 files listed by `git grep -lE '^theme: (blog|english|swedish)$'`

**Interfaces:**
- Consumes: from Task 1, no template reads `page.theme`.
- Produces: no file in the repo has `theme:` front matter.

- [ ] **Step 1: Confirm the scope (the failing check)**

```bash
git grep -hE '^theme:' | sort | uniq -c
git grep -nE 'page\.theme|page_theme' -- _includes _layouts '*.html' '*.md' '*.liquid' ':!docs'
```

Expected: `2 theme: blog`, `121 theme: english`, `528 theme: swedish`, and the second command prints nothing.

- [ ] **Step 2: Delete the lines**

`perl -i` keeps each file's bytes (line endings, missing final newline) exactly as they were, which BSD `sed -i` does not guarantee.

```bash
git grep -z -lE '^theme: (blog|english|swedish)$' | xargs -0 perl -i -ne 'print unless /^theme: (blog|english|swedish)$/'
```

- [ ] **Step 3: Verify the edit touched only those lines**

```bash
git grep -nE '^theme:'; echo "grep exit=$?"
git diff --numstat | wc -l
git diff --numstat | awk '$1 != 0 || $2 != 1' | head
git diff -U0 | grep -E '^[-+]' | grep -vE '^(---|\+\+\+) ' | sort | uniq -c
git diff --check && echo "no whitespace errors"
```

Expected:
- `grep exit=1` (no matches).
- `651`.
- The `awk` line prints nothing (every file: 0 added, 1 removed).
- Exactly `2 -theme: blog`, `121 -theme: english`, `528 -theme: swedish`.
- `no whitespace errors`.

- [ ] **Step 4: Build and confirm the output is byte-identical**

```bash
bundle exec jekyll build --destination /tmp/single-theme-check/site-task3
diff -r -x sitemap.xml /tmp/single-theme-check/site-task2 /tmp/single-theme-check/site-task3 && echo "site unchanged"
```

Expected: `site unchanged`.

- [ ] **Step 5: Commit**

```bash
git add -A kurssit 404.html blogi
git commit -m "$(cat <<'EOF'
Drop theme front matter

Nothing reads theme: since the site has a single theme.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Final check and draft pull request

**Files:** none.

**Interfaces:**
- Consumes: the three commits from Tasks 1-3 on `worktree-single-theme`.
- Produces: a draft PR against `master` for the owner to review and merge. Merging deploys the site.

- [ ] **Step 1: Rebase onto the latest `master`**

Pages CMS and the bot workflows commit to `master` directly.

```bash
git fetch origin
git rebase origin/master
```

Expected: a clean rebase. If a CMS commit added a new page with `theme:` (unlikely: the CMS doesn't write that key), rerun Task 3 Steps 2-4 and amend.

- [ ] **Step 2: Final build and check**

```bash
bundle exec jekyll build
sh /tmp/single-theme-check/check-theme.sh _site; echo "exit=$?"
git grep -nE 'english|swedish' -- _includes _layouts package.json less ':!less/bootstrap'
```

Expected: the build succeeds with no Liquid errors, the check prints `PASS`, and the `git grep` prints nothing.

- [ ] **Step 3: Push and open a draft PR**

```bash
git push -u origin worktree-single-theme
gh pr create --draft --base master --title "Use the blog theme on every page" --body "$(cat <<'EOF'
Makes `blog` the only theme and removes the English and Swedish themes.

- Archived course pages from 2013-2014 to 2019-2020 (649 pages) now use the blog colours, fonts and owl, like every page since 2020-2021.
- Deletes `theme-selector.liquid`, the English and Swedish Less sources, compiled CSS and owl images, and the `theme:` front matter that selected them.
- The blog CSS is byte-identical, and pages that already used blog render the same HTML.

Checked: a full site diff against `master` shows only the 649 archived pages changing, and only in their font, stylesheet and owl lines. `npm run build:css` reproduces the committed blog CSS.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Out of scope

- Merging `less/common.less` into `less/blog/`, or moving `themes/blog/css/` to a shorter path. Both are possible now that there is one theme, but they change paths and would need their own diff check.
- Rewriting the completed entries in `TODO.md` that mention "three themes": they record history.
