---
name: check-site
description: Build and serve the Jekyll site locally, then screenshot key pages (front page, current and archived courses) at phone and desktop widths with Chrome DevTools and check the browser console. Use to run or preview the site, or to check a change to layouts, includes, styles, JavaScript or the schedule table before committing.
argument-hint: "[extra paths, e.g. /kurssit/2026-2027/rub13.3/laksyt/]"
allowed-tools: Bash(bundle exec jekyll *), Bash(npm run build:css*), Bash(curl -s *)
---

# Check the site

## 1. Build

1. If a file under `styles/` changed, run `npm run build:css` and check that `git status` shows the matching `dist/css/` changes. GitHub Pages doesn't build CSS, so the compiled files must be committed.
2. Run `bundle exec jekyll build` (about 20 s). It must finish without errors or Liquid warnings. There are no tests, so this is the baseline check.

## 2. Serve

`--skip-initial-build` serves the `_site` from step 1 as it is, so build again first if `_config.yml` or the data changed since. Start `bundle exec jekyll serve --skip-initial-build` with `run_in_background`, then wait until `curl -s -o /dev/null -w '%{http_code}' http://localhost:4000/` prints 200. If port 4000 is already taken (maybe the user's own server), leave that server alone and use `--port 4001` instead.

## 3. Pages

Check these, plus any paths given in `$ARGUMENTS`:

| Page | What it covers |
|---|---|
| `/` | Front page: course lists by period |
| `/kurssit/<semester>/<course>/` | A current course: schedule table and course nav |
| `/kurssit/<semester>/<course>/laksyt/` | Homework posts |
| `/kurssit/arkisto/` | Course archive |
| `/kurssit/2019-2020/rub7.2/` | An archived course with the older page structure |
| `/kurssit/2013-2014/ena1/info/` | Info page with the affix sidebar (only 2013-2014 info pages have one) |
| `/404.html` | Error page |

Take `<semester>` from `_config.yml`. For `<course>`, pick one whose `period` in `_data/courses_<semester>.yml` includes the `period` in `_data/asetukset.yml`.

## 4. Screenshots

Use the Chrome DevTools MCP tools (`new_page`, `navigate_page`, `resize_page`, `take_screenshot`, `list_console_messages`, `click`). For each page:

1. Take a screenshot at phone width (375×812) and at desktop width (1280×800).
2. Read the console messages. Errors matter, especially a failed jQuery `integrity` check or a stylesheet that didn't load.

On one course page, click the menu button (`.navbar-toggle`) at phone width and check that the menu opens. At desktop width, open the Kurssit dropdown.

In the screenshots, check the fonts (Bricolage Grotesque for headings and the navbar brand, Public Sans for body text) and colours, the header owl and the nav, and that on phones the schedule table stacks into rows without scrolling sideways. Both fonts fall back to the system font, so text that looks like the system font means the Google Fonts didn't load.

If the Chrome DevTools tools aren't available, fetch each page with `curl`, check for status 200 and a link to `/dist/css/styles.min.css`, and say that you skipped the screenshots.

## 5. Finish

Stop the server. Report what you checked, any visual problems or console errors (with the page and width), and whether the compiled CSS is committed.
