#!/usr/bin/env ruby
# Removes broken file references (no source_tree) from Sources build phase and project,
# then re-adds the files with correct paths.

require 'xcodeproj'

PROJECT_PATH = File.join(__dir__, '..', 'ScorePad.xcodeproj')
SOURCES_ROOT = File.join(__dir__, '..', 'ScorePad')
TARGET_NAME  = 'ScorePad'

proj   = Xcodeproj::Project.open(PROJECT_PATH)
target = proj.targets.find { |t| t.name == TARGET_NAME }
sources_phase = target.build_phases.find { |p| p.is_a?(Xcodeproj::Project::Object::PBXSourcesBuildPhase) }

# Files that have broken references (no source_tree attribute)
broken_filenames = %w[
  GameModule.swift
  GameRegistry.swift
  PersonProfile.swift
  PlayerRosterView.swift
  PlayerPickerField.swift
  BridgeDetailView.swift
  AppRootView.swift
  GameTypeGridView.swift
]

# Remove broken build files from Sources phase
sources_phase.files.to_a.each do |bf|
  ref = bf.file_ref
  next unless ref
  begin
    ref.real_path  # will raise if source_tree is missing
  rescue => _
    # broken ref — remove from build phase
    puts "Removing broken build file: #{ref.path}"
    sources_phase.remove_build_file(bf)
  end
end

# Remove broken file refs from project entirely
proj.files.to_a.each do |ref|
  begin
    ref.real_path
  rescue => _
    puts "Removing broken file ref: #{ref.path}"
    ref.remove_from_project
  end
end

proj.save
puts "✓ Broken refs removed. Now re-adding correct refs..."

# Re-add correct file references using add_file helper
def find_or_create_group(proj, parent, path_components)
  return parent if path_components.empty?
  name = path_components.first
  child = parent.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.name == name }
  unless child
    child = parent.new_group(name, name)
    puts "  Created group: #{name}"
  end
  find_or_create_group(proj, child, path_components[1..])
end

def add_file(proj, target, sources_phase, rel_path, group_path)
  abs_path = File.join(SOURCES_ROOT, rel_path)
  unless File.exist?(abs_path)
    puts "  SKIP (no file): #{rel_path}"
    return
  end
  all_refs = proj.files.map { |f| f.real_path.to_s rescue nil }.compact
  if all_refs.include?(abs_path)
    puts "  SKIP (already in project): #{rel_path}"
    return
  end
  scorepad_group = proj.main_group.children.find { |g| g.respond_to?(:path) && g.path == 'ScorePad' }
  raise 'ScorePad group not found' unless scorepad_group
  group = find_or_create_group(proj, scorepad_group, group_path)
  file_ref = group.new_reference(abs_path)
  file_ref.path = File.basename(abs_path)
  file_ref.source_tree = '<group>'
  sources_phase.add_file_reference(file_ref)
  puts "  Added: #{rel_path}"
end

proj   = Xcodeproj::Project.open(PROJECT_PATH)
target = proj.targets.find { |t| t.name == TARGET_NAME }
sources_phase = target.build_phases.find { |p| p.is_a?(Xcodeproj::Project::Object::PBXSourcesBuildPhase) }

add_file(proj, target, sources_phase, 'Core/GameModule.swift',                          ['Core'])
add_file(proj, target, sources_phase, 'Core/GameRegistry.swift',                         ['Core'])
add_file(proj, target, sources_phase, 'Core/Players/PersonProfile.swift',                ['Core', 'Players'])
add_file(proj, target, sources_phase, 'Core/Players/PlayerRosterView.swift',             ['Core', 'Players'])
add_file(proj, target, sources_phase, 'Core/Players/PlayerPickerField.swift',            ['Core', 'Players'])
add_file(proj, target, sources_phase, 'Modules/Bridge/Views/BridgeDetailView.swift',    ['Modules', 'Bridge', 'Views'])
add_file(proj, target, sources_phase, 'Views/AppRootView.swift',                         ['Views'])
add_file(proj, target, sources_phase, 'Views/GameTypeGridView.swift',                    ['Views'])

proj.save
puts "✓ Project saved."
