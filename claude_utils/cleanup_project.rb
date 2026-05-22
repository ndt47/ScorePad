#!/usr/bin/env ruby
# Removes duplicate Sources build phase entries and stale file references.

require 'xcodeproj'

PROJECT_PATH = File.join(__dir__, '..', 'ScorePad.xcodeproj')
TARGET_NAME  = 'ScorePad'

proj   = Xcodeproj::Project.open(PROJECT_PATH)
target = proj.targets.find { |t| t.name == TARGET_NAME }
sources_phase = target.build_phases.find { |p| p.is_a?(Xcodeproj::Project::Object::PBXSourcesBuildPhase) }

# --- Remove stale file references (file deleted from disk) ---
stale = proj.files.select { |f| !File.exist?(f.real_path.to_s) rescue true }
stale.each do |ref|
  puts "Removing stale reference: #{ref.real_path}"
  sources_phase.files.select { |bf| bf.file_ref == ref }.each { |bf| sources_phase.remove_build_file(bf) }
  ref.remove_from_project
end

# --- Remove duplicate Sources build phase entries ---
seen = {}
sources_phase.files.to_a.each do |bf|
  path = bf.file_ref&.real_path&.to_s
  next unless path
  if seen[path]
    puts "Removing duplicate build file: #{path}"
    sources_phase.remove_build_file(bf)
  else
    seen[path] = true
  end
end

# --- Remove duplicate file references (keep first occurrence) ---
seen_refs = {}
proj.files.to_a.each do |ref|
  path = ref.real_path.to_s
  if seen_refs[path]
    puts "Removing duplicate file ref: #{path}"
    ref.remove_from_project
  else
    seen_refs[path] = true
  end
end

proj.save
puts "✓ Project cleaned."
