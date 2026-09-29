# riikkak.github.io
[![Build Status](https://travis-ci.org/riikkak/riikkak.github.io.svg)](https://travis-ci.org/riikkak/riikkak.github.io) [![devDependency Status](https://david-dm.org/riikkak/riikkak.github.io/dev-status.svg)](https://david-dm.org/riikkak/riikkak.github.io?type=dev)

My professional blog and school course websites.

## Editing (Pages CMS)

Content is edited at [app.pagescms.org](https://app.pagescms.org) (sign in with GitHub, open `riikkak/riikkak.github.io`). The config is in `.pages.yml`. Each save is a commit to `master`, and GitHub Pages rebuilds the site in a minute or two.

- **Läksyt**: homework posts in `_posts/<semester>/`. The filename is generated from today's date and the title, and **Kurssi** sets the `<course> läksyt` tag. Kurssi only lists the courses of the current Jakso (all courses if the period has none).
- **One group per course**: Aikataulu (`_data/schedule_<semester>_<course>.yml`), Materiaali and Kurssi-info.
- **Asetukset → Jakso**: the current teaching period (`_data/asetukset.yml`). Changing it runs the `Update Pages CMS course list` action, which rewrites the Kurssi options in `.pages.yml` (between the `kurssit:start` and `kurssit:end` markers) and commits them within a minute. Reload the CMS to see the new list. To run it by hand: `ruby .github/scripts/pages-cms-courses.rb`.
- **Media**: uploads go to `media/`.

Posts from earlier semesters stay in the `_posts/` root and are not shown in the CMS.

### New semester

After the usual setup (data files, course pages, `_config.yml`):

1. In `.pages.yml`, point the Läksyt `path` to `_posts/<new-semester>` and add an empty `_posts/<new-semester>/.gitkeep`.
2. Replace the course groups with the courses in `_data/courses_<new-semester>.yml`. The first group defines the `&aikataulu` and `&sivu` field lists that the other groups reuse. The Kurssi options are updated by the action once `semester` in `_config.yml` and the new courses file are pushed.
3. Set Jakso to 1 in `_data/asetukset.yml`.
