# Scaffolds a new semester from its course list, following "Adding a new
# semester" in CLAUDE.md. Write _data/<semester>/courses.yml first, then run:
#
#   ruby .claude/skills/new-semester/scaffold.rb 2027-2028
#
# Creates the files that don't exist yet: an empty schedule file per course,
# _data/<semester>/navigation.yml, the four pages of each course and
# _posts/<semester>/.gitkeep. Then points _config.yml, .pages.yml and
# _data/asetukset.yml at the new semester and reruns
# .github/scripts/pages-cms-courses.rb. Existing files are left alone, so it
# can be rerun after fixing the course list.
require "fileutils"
require "yaml"

Dir.chdir(File.expand_path("../../..", __dir__))

semester = ARGV[0].to_s
years = semester.match(/\A(\d{4})-(\d{4})\z/) or abort "Usage: ruby #{$PROGRAM_NAME} YYYY-YYYY"
abort "#{semester}: the years must be consecutive" unless years[2].to_i == years[1].to_i + 1

courses_file = "_data/#{semester}/courses.yml"
abort "#{courses_file} not found. Write the course list first." unless File.exist?(courses_file)
courses = YAML.load_file(courses_file)
abort "#{courses_file} has no courses" unless courses.is_a?(Array) && !courses.empty?

names = courses.map { |c| c["name"].to_s }
bad = names.reject { |n| n.match?(/\A[a-z0-9.-]+\z/) && n.match?(/ena|rub/) }
abort "#{courses_file}: names must be lowercase and contain ena or rub: #{bad.join(', ')}" unless bad.empty?
dupes = names.select { |n| names.count(n) > 1 }.uniq
abort "#{courses_file}: duplicate names: #{dupes.join(', ')}" unless dupes.empty?
courses.reject { |c| c["period"] }.each do |c|
  warn "Warning: #{c['name']} has no period, so it never shows as a current course."
end

def create(path, content)
  if File.exist?(path)
    puts "exists   #{path}"
    return
  end
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content)
  puts "created  #{path}"
end

def update(path)
  text = File.read(path, encoding: "UTF-8")
  updated = yield(text.dup)
  if updated == text
    puts "same     #{path}"
  else
    File.write(path, updated, encoding: "UTF-8")
    puts "updated  #{path}"
  end
end

# Data keys can't contain the dot of a course name: rub11-12.3 → rub11-12_3.
def key(name)
  name.tr(".", "_")
end

courses.each do |course|
  name = course["name"]
  dir = "kurssit/#{semester}/#{name}"
  create("_data/#{semester}/schedules/#{key(name)}.yml", "")
  create("#{dir}/index.html", <<~PAGE)
    ---
    layout: content-main
    title: Aikataulu
    course: #{name}
    ---

    {% include course-schedule.html data=site.data.#{semester}.schedules.#{key(name)} prework=false %}
  PAGE
  create("#{dir}/laksyt/index.html", <<~PAGE)
    ---
    layout: content-posts
    title: Läksyt
    course: #{name}
    sitemap:
        changefreq: weekly
    ---

    {% include posts-homework.html course=page.course %}
  PAGE
  %w[Materiaali Kurssi-info].each do |title|
    create("#{dir}/#{title.downcase}/index.md", <<~PAGE)
      ---
      layout: content-main
      title: #{title}
      course: #{name}
      published: true
      ---
    PAGE
  end
end

navigation = courses.map do |course|
  <<~NAV
    # ----- #{course['name'].upcase} ----- #
    - course: #{course['name']}
      pages:
        - page: Aikataulu
        - page: Läksyt
          url: laksyt
        - page: Materiaali
        - page: Kurssi-info
  NAV
end
create("_data/#{semester}/navigation.yml", navigation.join)
create("_posts/#{semester}/.gitkeep", "")

update("_config.yml") do |text|
  text.sub!(/^semester: .*$/, "semester: #{semester}") or abort "_config.yml: no semester line"
  line = %(  - {scope: {path: "kurssit/#{semester}"}, values: {semester: "#{semester}"}}\n)
  unless text.include?(line)
    last = text.rindex(/^  - \{scope: \{path: "kurssit\//) or abort "_config.yml: no kurssit defaults lines"
    text.insert(text.index("\n", last) + 1, line)
  end
  text
end

update(".pages.yml") do |text|
  text.sub!(%r{^(    path: )_posts/\S+$}) { "#{$1}_posts/#{semester}" } or abort ".pages.yml: Läksyt path not found"

  # The course groups sit between the Läksyt collection and Asetukset.
  laksyt = text.index(/^  - name: laksyt\n/) or abort ".pages.yml: Läksyt collection not found"
  first = text.index(/^  - name: /, laksyt + 1)
  stop = text.index(/^  - name: asetukset\n/) or abort ".pages.yml: Asetukset not found"
  groups = text[first...stop]
  # The first group defines the Aikataulu and page field lists; keep them as they are.
  aikataulu = groups[/^        fields: &aikataulu\n(?:          .*\n)+/]
  sivu = groups[/^        fields: &sivu\n(?:          .*\n)+/]
  unless aikataulu && sivu
    abort ".pages.yml: the &aikataulu and &sivu field lists weren't found. Rebuild the course groups by hand."
  end

  blocks = courses.map do |course|
    name = course["name"]
    id = key(name)
    <<~GROUP.gsub(/^(?=.)/, "  ")
      - name: #{id}
        label: #{name.upcase}
        type: group
        items:
          - name: #{id}_aikataulu
            label: Aikataulu
            type: file
            path: _data/#{semester}/schedules/#{id}.yml
            format: yaml
            list: true
            fields: *aikataulu
          - name: #{id}_materiaali
            label: Materiaali
            type: file
            path: kurssit/#{semester}/#{name}/materiaali/index.md
            fields: *sivu
          - name: #{id}_kurssiinfo
            label: Kurssi-info
            type: file
            path: kurssit/#{semester}/#{name}/kurssi-info/index.md
            fields: *sivu

    GROUP
  end
  text[first...stop] = blocks.join
    .sub("        fields: *aikataulu\n") { aikataulu }
    .sub("        fields: *sivu\n") { sivu }
  text
end

update("_data/asetukset.yml") do |text|
  text.sub!(/^period: .*$/, "period: 1") or abort "_data/asetukset.yml: no period line"
  text
end

system("ruby", ".github/scripts/pages-cms-courses.rb") or abort "pages-cms-courses.rb failed"

config = YAML.safe_load(File.read(".pages.yml", encoding: "UTF-8"), aliases: true)
paths = config["content"].flat_map { |c| c["items"] || [] }.map { |item| item["path"] }
missing = paths.reject { |path| File.exist?(path) }
abort ".pages.yml points at missing files: #{missing.join(', ')}" unless missing.empty?
