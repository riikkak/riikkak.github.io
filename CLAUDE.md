# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Jekyll site for Riikka Koskenranta's blog and high school course pages (English `ena*`, Swedish `rub*`), served by GitHub Pages from `master` at riikka.koskenranta.fi. Content and UI text are in Finnish.

## Commands

- `bundle exec jekyll build`: build into `_site/` (~20 s). There are no tests, so a clean build is the check. Ruby and Node come from `.tool-versions` via asdf. Don't use Docker.
- `bundle exec jekyll serve --watch`: local server on :4000.
- `npm run build:css`: compile `styles/main.less` with `lessc`, then minify with `cleancss`, into `dist/css/styles.css` and `styles.min.css`. GitHub Pages doesn't build CSS, so commit the compiled CSS with any Less change. `main.less` imports Bootstrap 3.4.1 from `styles/bootstrap` (vendored unmodified), then `styles/variables.less`, and holds all of the site's own rules. The last definition of a Less variable wins, so `variables.less` first restores the Bootstrap 3.0 RC defaults the design was built on, then sets the site's colours and fonts.
- `ruby .github/scripts/pages-cms-courses.rb`: regenerate the Läksyt course dropdown in `.pages.yml` (CI normally does this).

`_config.yml` has `safe: true` because GitHub Pages builds it with the `github-pages` gem. Only whitelisted plugins work, and `jekyll-redirect-from` is the only one used.

## Claude Code hooks and skills

`.claude/settings.json` runs two hooks on Edit and Write. `.claude/hooks/protect-paths.sh` refuses edits in `_site/`, `dist/css/` and `styles/bootstrap/`. `.claude/hooks/rebuild-css.sh` runs `npm run build:css` after an edit in `styles/`, so commit the `dist/css/` changes it makes. The project skills are `/new-semester` (see "Adding a new semester") and `/check-site`, which builds and serves the site and screenshots key pages at phone and desktop widths with the Chrome DevTools MCP.

## Architecture

Everything is keyed by **semester** (`YYYY-YYYY`, e.g. `2026-2027`) and **course name** (lowercase, e.g. `rub11-12.3`). The school year is split into teaching periods ("jakso", 1–5).

- `_config.yml`: `semester` is the current one. `defaults` give each `kurssit/<semester>/` path a `semester` value, one line per semester. On pages where `page.semester` isn't `site.semester`, the nav's "Kurssit" dropdown becomes a link to the archive. The site has no analytics or tracking on purpose. `exclude` must list any new repo-only file at the root, or it gets published.
- `_data/asetukset.yml`: `period`, the current teaching period. The front page and the course nav read it to show which courses are running.
- `_data/courses_<semester>.yml`: course list with `name`, `code` (scalar or list) and `period` (scalar or list; the Liquid and the Ruby script handle both). The archive puts names containing `ena` under English and names containing `rub` under Swedish; the front page lists all languages together.
- `_data/navigation_<semester>.yml`: per-course nav pages. The first page links to the course root.
- `_data/schedule_<semester>_<course>.yml`: rows for the Aikataulu table. The dot in the course name becomes `_` (`rub11-12.3` → `schedule_2026-2027_rub11-12_3.yml`). Fields: `date` ("ti 6.10."), `title`, `grammar`, `digi`, `other`, optional `prework`, or `alert` for a full-width row. `course-schedule.html` parses `date` into a schema.org date, using the semester's first year for July–December and the second for January–June.
- `kurssit/<semester>/<course>/`: `index.html` (the schedule, via `{% include course-schedule.html data=site.data.schedule_... %}`), `laksyt/`, `materiaali/`, `kurssi-info/`. Each page sets `course:` in front matter, and that value must match `name` in the courses file.
- `_includes/head.liquid` → `course-variables.liquid`: for pages with `page.course`, sets `page_nav` and `page_courses` from `site.data["navigation_" + page.semester]` and `site.data["courses_" + page.semester]`. The header and navigation use them. Liquid 4 can't apply filters inside `[]`, so the key is built with `assign` first.
- `_posts/`: homework and blog posts. The current semester's posts go in `_posts/<semester>/` (the folder Pages CMS writes to). Older posts stay in the `_posts/` root. Posts use `layout: none`. Jekyll still writes each one as a bare fragment under `/YYYY/MM/DD/`, but nothing links there; they are meant to appear only through includes (`output: false` does not work for posts in Jekyll 3.10). Jekyll splits the space-separated `tags` string, and the includes test each tag exactly: the course name plus `läksyt` → that course's Läksyt page (`posts-homework.html`), and the course name plus `etusivu` → course front page, but only in older semesters whose index includes `posts-frontpage.html`. Homework pages filter posts by date (July–June of the page's semester), not by folder.
- Styles: the site has one stylesheet. `_includes/head.liquid` links `/dist/css/styles.min.css` on every page, and `header.liquid` always shows `/img/owl-blog.png`. The old `english` and `swedish` themes were removed on purpose, so nothing reads `theme:` front matter; don't add it back.
- Fonts: Bricolage Grotesque for headings and Public Sans for body text are self-hosted in `dist/fonts/`. They are the latin and latin-ext files Google Fonts serves, with their OFL licences, and the `@font-face` rules are in `main.less`. `head.liquid` preloads the two latin files every page uses. Don't load the fonts from Google again: the browser only finds its font files after the first paint, so text flashed in the system font on first visits. The old `english` and `swedish` themes were removed on purpose, so nothing reads `theme:` front matter; don't add it back.
- Headings: each page has one h1, its title (from `content-main` or `content-posts`, or in the page itself on the front page, archive and 404). The header's site name and course code are `<p class="h1">`, styled as an h1 but not a heading, and post titles are h2. So page content starts at `##` and post content at `###`, without skipping levels. The Sisältö field descriptions in `.pages.yml` tell the owner the same.
- JavaScript: the site has one script, `dist/js/site.js`, loaded by `_includes/footer.liquid`. It has no dependencies and no build step. It replaces the Bootstrap 3 plugins the site used: collapse for the phone menu (`data-toggle="collapse"`) and dropdown for the nav menus (`data-toggle="dropdown"`, with Bootstrap 3.4.1's keyboard handling). It switches Bootstrap's CSS classes (`collapse`, `in` and `collapsing`; `open` on the dropdown's `li`). The 2013-2014 info page sidebars that used affix are `position: sticky` in `main.less`. jQuery and Bootstrap's JavaScript were removed on purpose, so extend `site.js` instead of adding them back.
- `index.html` is the course front page. Its left column lists the courses running in the current period, then those that have ended; the right column lists upcoming courses grouped by the period they start in. A course is running from its first period to its last. `kurssit/arkisto/index.html` lists every semester from 2013-2014 up to the one before `site.semester`. Both build their data keys from `site.semester`.

## Editing via Pages CMS

The owner edits content at app.pagescms.org, configured by `.pages.yml`. Each CMS save is a commit to `master`. Labels are Finnish: Läksyt = homework, Aikataulu = schedule, Materiaali = material, Jakso = teaching period, Asetukset = settings. The Kurssi options between the `# kurssit:start` and `# kurssit:end` markers in `.pages.yml` are generated, so don't hand-edit them.

GitHub Actions push bot commits to `master`:
- `pages-cms-courses.yml` reruns the course script when `_config.yml`, `_data/asetukset.yml` or `_data/courses_*.yml` change.
- `normalize-line-endings.yml` re-commits files as LF when CRLF gets in, because the web editors ignore `.gitattributes`.

After pushing, pull before further work because a bot commit may have landed. Files must use LF line endings.

## Adding a new semester

`/new-semester <YYYY-YYYY>` runs these steps: after `_data/courses_<new>.yml` is written, `.claude/skills/new-semester/scaffold.rb` does the rest. Commit `c82b495e` ("Add 2026-2027 semester") is the reference, except that its edits to `course-variables.liquid`, `index.html` and the archive page are no longer needed. The steps:
1. Add `_data/courses_<new>.yml`, `_data/navigation_<new>.yml` and an empty `_data/schedule_<new>_<course>.yml` for each course.
2. Create `kurssit/<new>/<course>/` pages. Copy them from the previous semester and change `course:` and the schedule data key.
3. In `_config.yml`, set `semester` and add a defaults line for the new path.
4. Follow the Pages CMS steps in README.md ("New semester"): Läksyt `path` → `_posts/<new>` with a `.gitkeep`, rebuild the course groups, and set `period: 1` in `_data/asetukset.yml`.
