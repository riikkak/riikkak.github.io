# Cleanup backlog

Tick the ones that have been done to mark progress.

## Privacy and third-party requests

- [x] Update Google Fonts urls. The current `css?family=` URLs are an old format without `display=swap`. ~5 min

## Frontend libraries and build

- [ ] Upgrade Bootstrap 3.0.0 → 3.4.1 (JS in `dist/js/`, Less in `less/bootstrap/`) and jQuery 1.11.3 → 3.7. This clears known security issues that the site doesn't trigger but scanners flag. Rebuild the CSS and check all three themes visually. ~1–2 h
- [x] Replace Grunt with npm scripts (`lessc` + `cleancss`). Drops about 10 devDependencies and the lodash/minimatch `overrides`. Check that the output is byte-identical to the committed `themes/*/css/*.css`. ~1 h
- [ ] Pin Node in `.tool-versions` (`nodejs 24`). Optionally add `engines` to `package.json`. ~5 min
- [ ] Bump major version of `package.json` when all changes have been made. ~5 min

## Ruby

- [ ] Add `faraday-retry` to the `Gemfile` to silence the build-time Faraday message. GitHub Pages ignores the Gemfile, so this is safe. ~2 min

## Templates and maintenance

- [ ] Look up data keys from `page.semester` instead of the hardcoded per-semester `case` in `_includes/course-variables.liquid`, `index.html` and `kurssit/arkisto/index.html`. Removes a manual new-semester step, and a missed step currently makes the nav disappear silently. Liquid 4 needs an `assign` first, not a filter inside `[]`. ~1 h
- [ ] Merge the 14 near-identical `defaults` blocks in `_config.yml` by working out `archived` from `page.semester != site.semester`. Fits well with the item above. ~30 min
- [ ] Add trailing slashes to the course-root links in `_includes/navigation.liquid:9,26`, so each click skips a redirect. ~5 min
- [ ] Add a `404.html` page instead of GitHub's generic one. Use the blog theme. ~15 min
- [ ] Write a real `<meta name="description">` in `_includes/head.liquid` => "Riikka Koskenrannan (REK) opettamat kurssit Kastellin lukiossa. Kurssimateriaalit ja -aikataulut.". ~10 min
- [ ] `_includes/header.liquid:7` uses `{{theme}}`, which leaks from `theme-selector.liquid` via `head.liquid`. It works but is fragile; assign it explicitly. ~10 min
- [ ] Stop generating `redirects.json` (`redirect_from: { json: false }` in `_config.yml`). ~2 min

## Content

- [ ] Check old `http://` external links in content (tiedostot.otava.fi, svenska.yle.fi, daringfireball.net, …) and likely-dead domains (jobsearch.about.com, app.emended.com, otava.flinga.fi). Update to https or remove link if the url is dead. ~1 h
- [ ] Shrink the largest media: three ~2 MB `media/rub5/suulliset_harjoitukset_*.jpg` and the ~4 MB PDFs (`media/rub3/Medier_suullinen.pdf`, `media/rub6/RUB6_opintokortti.pdf`, `media/rub5/Suullinen_aanto.pdf`). Git history won't get smaller. ~15 min
- [ ] Remove 2016-2017 courses which are empty (`kurssit/2016-2017/{rub10.2,rub10.3,rub10.4,rub9.3}`). ~5 min

## CI and CMS

- [ ] Retry `git pull --rebase` + `git push` in `.github/workflows/pages-cms-courses.yml` and `normalize-line-endings.yml`, so a CMS save landing at the same moment doesn't fail the job. ~10 min
- [ ] Add `.github/dependabot.yml` for the `github-actions` ecosystem only, monthly. ~5 min
- [ ] `.github/scripts/pages-cms-courses.rb`: give a clear error when `_data/courses_<semester>.yml` is missing, and warn when the Läksyt `path` in `.pages.yml` doesn't match the semester. ~20 min

