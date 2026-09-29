# Rewrites the Kurssi options in .pages.yml (between the kurssit:start and
# kurssit:end markers) to the courses of the current teaching period, so the
# Läksyt dropdown only offers courses that are running now.
#
# Reads: _config.yml (semester), _data/asetukset.yml (period),
#        _data/courses_<semester>.yml (course periods).
# Run by .github/workflows/pages-cms-courses.yml; can also be run locally.
require "yaml"

CONFIG = ".pages.yml"
MARKERS = /^(?<indent>[ ]*)# kurssit:start[^\n]*\n(?<body>.*?)^[ ]*# kurssit:end/m

# In GitHub Actions, prefix warnings so they show up as annotations.
def warn_ci(message)
  warn(ENV["GITHUB_ACTIONS"] ? "::warning::#{message}" : "Warning: #{message}")
end

semester = YAML.load_file("_config.yml")["semester"] or abort "_config.yml: no semester set"
period = YAML.load_file("_data/asetukset.yml")["period"].to_i

courses_file = "_data/courses_#{semester}.yml"
unless File.exist?(courses_file)
  abort "#{courses_file} not found. _config.yml says the semester is #{semester}; " \
        "add the courses file first (see \"Adding a new semester\" in CLAUDE.md)."
end
courses = YAML.load_file(courses_file)
abort "#{courses_file} has no courses" unless courses.is_a?(Array) && !courses.empty?

current = courses.select { |c| Array(c["period"]).map(&:to_i).include?(period) }
if current.empty?
  warn_ci "No #{semester} courses in period #{period}; offering all courses instead."
  current = courses
end

text = File.read(CONFIG, encoding: "UTF-8")

laksyt = YAML.safe_load(text, aliases: true)["content"].find { |c| c["name"] == "laksyt" }
if laksyt && laksyt["path"] != "_posts/#{semester}"
  warn_ci "#{CONFIG}: the Läksyt path is #{laksyt['path']}, but the semester is #{semester}. " \
          "New homework posts will go to the wrong folder; set it to _posts/#{semester}."
end
match = text.match(MARKERS) or abort "#{CONFIG}: kurssit:start/kurssit:end markers not found"
indent = match[:indent]
body = current.map do |c|
  "#{indent}- name: \"#{c['name']} läksyt\"\n#{indent}  label: #{c['name'].upcase}\n"
end.join
updated = text[0...match.begin(:body)] + body + text[match.end(:body)..]

names = current.map { |c| c["name"] }.join(", ")
if updated == text
  puts "Period #{period}: already up to date (#{names})"
else
  File.write(CONFIG, updated, encoding: "UTF-8")
  puts "Period #{period}: #{names}"
end
