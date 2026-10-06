---
name: new-semester
description: Set up a new school year on the site from its course list - course data, navigation, course pages, _config.yml, the Pages CMS course groups and the teaching period. Use when a new lukuvuosi starts and the owner has sent the courses.
disable-model-invocation: true
argument-hint: "<YYYY-YYYY> [courses: name, code, periods]"
---

# New semester

Set up the semester in `$ARGUMENTS`. This runs "Adding a new semester" in CLAUDE.md and "New semester" in README.md.

## 1. Get the course list

You need the semester (`YYYY-YYYY`, normally the year after `semester` in `_config.yml`) and, for each course:

- `name`: the lowercase course name, e.g. `rub11-12.3` or `ena01-02.8`. Names with `ena` go under English and names with `rub` under Swedish.
- `code`: the course code, or a list of codes.
- `period`: the teaching period (jakso, 1–5), or a list of periods.

If the arguments don't give all of this, ask for it. Don't guess codes or periods.

## 2. Write the courses file

Pull first, since Pages CMS and the bots commit to `master`. Then write `_data/<semester>/courses.yml` in the format of the previous semester's file:

```yaml
- name: rub11-12.3
  code:
    - 6
    - 1
  desc:
  period:
    - 2
    - 3

- name: rub112.4
  code: 4
  desc:
  period: 3
```

## 3. Run the scaffold

```sh
ruby .claude/skills/new-semester/scaffold.rb <semester>
```

It creates the files that don't exist yet and leaves existing ones alone, so rerun it after fixing the courses file:

- `_data/<semester>/schedules/<course>.yml` (empty) and `_data/<semester>/navigation.yml`
- `kurssit/<semester>/<course>/` with the Aikataulu, Läksyt, Materiaali and Kurssi-info pages
- `_posts/<semester>/.gitkeep`, the folder Pages CMS writes homework to

Then it updates:

- `_config.yml`: `semester`, plus a `defaults` line for `kurssit/<semester>`
- `.pages.yml`: the Läksyt `path`, and one course group per course. The first group keeps the `&aikataulu` and `&sivu` field lists that the others reuse.
- `_data/asetukset.yml`: `period: 1`
- the Kurssi options in `.pages.yml`, by running `.github/scripts/pages-cms-courses.rb`

If it stops at `.pages.yml`, the file no longer has the shape the script expects. Rebuild the course groups by hand as README.md describes.

## 4. Check

- Read `git status` and `git diff`. A typo in a course name shows up as a wrong folder or data key.
- Run `bundle exec jekyll build`. It must finish without errors.
- In `_site`, the front page lists the period 1 courses as current, `kurssit/arkisto/` includes the previous semester, and each `kurssit/<semester>/<course>/` has its four pages.
- Run `/check-site` if you also want screenshots.

Leave the previous semester's `_posts/<old-semester>/` folder where it is. Homework pages pick posts by date, not by folder.

## 5. Hand off

Pushing this to `master` switches the live site to the new semester, so push when the owner wants the new year to show. After the push, the owner reloads Pages CMS to see the new course groups.
