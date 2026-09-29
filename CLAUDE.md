# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Jekyll site for Riikka Koskenranta's blog and high school course pages (English `ena*`, Swedish `rub*`), served by GitHub Pages from `master` at riikka.koskenranta.fi. Content and UI text are in Finnish.

## Commands

- `bundle exec jekyll build`: build into `_site/` (~20 s). There are no tests, so a clean build is the check. Ruby and Node come from `.tool-versions` via asdf. Don't use Docker.
- `bundle exec jekyll serve --watch`: local server on :4000.
- `npm run build:css`: compile `less/{blog,english,swedish}/main.less` with `lessc`, then minify with `cleancss`, into `themes/<theme>/css/styles.css` and `styles.min.css`. GitHub Pages doesn't build CSS, so commit the compiled CSS with any Less change. `npm run build:css:swedish` (or `:blog`, `:english`) builds one theme. Each `main.less` imports Bootstrap 3 from `less/bootstrap`, then the theme's `variables.less`, which overrides Bootstrap's variables because the last definition of a Less variable wins.
- `ruby .github/scripts/pages-cms-courses.rb`: regenerate the Läksyt course dropdown in `.pages.yml` (CI normally does this).

`_config.yml` has `safe: true` because GitHub Pages builds it with the `github-pages` gem. Only whitelisted plugins work, and `jekyll-redirect-from` is the only one used.

## Architecture

Everything is keyed by **semester** (`YYYY-YYYY`, e.g. `2026-2027`) and **course name** (lowercase, e.g. `rub11-12.3`). The school year is split into teaching periods ("jakso", 1–5).

- `_config.yml`: `semester` is the current one. `defaults` give each `kurssit/<semester>/` path a `semester` value, one line per semester. On pages where `page.semester` isn't `site.semester`, the nav's "Kurssit" dropdown becomes a link to the archive. The site has no analytics or tracking on purpose. `exclude` must list any new repo-only file at the root, or it gets published.
- `_data/asetukset.yml`: `period`, the current teaching period. The front page and the course nav read it to show which courses are running.
- `_data/courses_<semester>.yml`: course list with `name`, `code` (scalar or list) and `period` (scalar or list; the Liquid and the Ruby script handle both). Names containing `ena` go under English and names containing `rub` under Swedish.
- `_data/navigation_<semester>.yml`: per-course nav pages. The first page links to the course root.
- `_data/schedule_<semester>_<course>.yml`: rows for the Aikataulu table. The dot in the course name becomes `_` (`rub11-12.3` → `schedule_2026-2027_rub11-12_3.yml`). Fields: `date` ("ti 6.10."), `title`, `grammar`, `digi`, `other`, optional `prework`, or `alert` for a full-width row. `course-schedule.html` parses `date` into a schema.org date, using the semester's first year for July–December and the second for January–June.
- `kurssit/<semester>/<course>/`: `index.html` (the schedule, via `{% include course-schedule.html data=site.data.schedule_... %}`), `laksyt/`, `materiaali/`, `kurssi-info/`. Each page sets `course:` in front matter, and that value must match `name` in the courses file.
- `_includes/head.liquid` → `course-variables.liquid`: for pages with `page.course`, sets `page_nav` and `page_courses` from `site.data["navigation_" + page.semester]` and `site.data["courses_" + page.semester]`. The header and navigation use them. Liquid 4 can't apply filters inside `[]`, so the key is built with `assign` first.
- `_posts/`: homework and blog posts. The current semester's posts go in `_posts/<semester>/` (the folder Pages CMS writes to). Older posts stay in the `_posts/` root. Posts use `layout: none`. Jekyll still writes each one as a bare fragment under `/YYYY/MM/DD/`, but nothing links there; they are meant to appear only through includes (`output: false` does not work for posts in Jekyll 3.10). Jekyll splits the space-separated `tags` string, and the includes test each tag exactly: the course name plus `läksyt` → that course's Läksyt page (`posts-homework.html`), the course name plus `etusivu` → course front page, but only in older semesters whose index includes `posts-frontpage.html`, `blogi` → `/blogi/`. Homework pages filter posts by date (July–June of the page's semester), not by folder.
- Theme: `_includes/theme-selector.liquid` picks the `blog`, `english` or `swedish` stylesheet from `page.theme`, or from `page.tags` (`ena` → english, `rub` → swedish). The default is `blog`. Course pages from 2020-2021 on set neither, so they use `blog`; the owner wants it that way, so don't add `theme:` to them.
- `index.html` is the course front page, sorted into current, past and upcoming by period. `kurssit/arkisto/index.html` lists every semester from 2013-2014 up to the one before `site.semester`. Both build their data keys from `site.semester`.

## Editing via Pages CMS

The owner edits content at app.pagescms.org, configured by `.pages.yml`. Each CMS save is a commit to `master`. Labels are Finnish: Läksyt = homework, Aikataulu = schedule, Materiaali = material, Jakso = teaching period, Asetukset = settings. The Kurssi options between the `# kurssit:start` and `# kurssit:end` markers in `.pages.yml` are generated, so don't hand-edit them.

GitHub Actions push bot commits to `master`:
- `pages-cms-courses.yml` reruns the course script when `_config.yml`, `_data/asetukset.yml` or `_data/courses_*.yml` change.
- `normalize-line-endings.yml` re-commits files as LF when CRLF gets in, because the web editors ignore `.gitattributes`.

After pushing, pull before further work because a bot commit may have landed. Files must use LF line endings.

## Adding a new semester

Commit `c82b495e` ("Add 2026-2027 semester") is the reference, except that its edits to `course-variables.liquid`, `index.html` and the archive page are no longer needed. The steps:
1. Add `_data/courses_<new>.yml`, `_data/navigation_<new>.yml` and an empty `_data/schedule_<new>_<course>.yml` for each course.
2. Create `kurssit/<new>/<course>/` pages. Copy them from the previous semester and change `course:` and the schedule data key.
3. In `_config.yml`, set `semester` and add a defaults line for the new path.
4. Follow the Pages CMS steps in README.md ("New semester"): Läksyt `path` → `_posts/<new>` with a `.gitkeep`, rebuild the course groups, and set `period: 1` in `_data/asetukset.yml`.
