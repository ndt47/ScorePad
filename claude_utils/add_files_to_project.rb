#!/usr/bin/env ruby
# Adds new files created during the multi-game module refactor to the Xcode project.
# Safe to re-run — skips files already in the project.

require 'xcodeproj'

PROJECT_PATH = File.join(__dir__, 'ScorePad.xcodeproj')
SOURCES_ROOT = File.join(__dir__, 'ScorePad')
TARGET_NAME  = 'ScorePad'

proj   = Xcodeproj::Project.open(PROJECT_PATH)
target = proj.targets.find { |t| t.name == TARGET_NAME }
raise "Target '#{TARGET_NAME}' not found" unless target

sources_phase = target.build_phases.find { |p| p.is_a?(Xcodeproj::Project::Object::PBXSourcesBuildPhase) }

# Returns the PBXGroup for a given path array, creating groups along the way.
# path_components: array of group names relative to the ScorePad group.
# parent: the starting group (defaults to the ScorePad main group).
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

# Adds a Swift file to the project if not already present.
# rel_path: path relative to SOURCES_ROOT, e.g. "Core/GameModule.swift"
# group_path: array of group names, e.g. ["Core"]
def add_file(proj, target, sources_phase, rel_path, group_path)
  abs_path = File.join(SOURCES_ROOT, rel_path)
  unless File.exist?(abs_path)
    puts "  SKIP (file not on disk): #{rel_path}"
    return
  end

  # Check if already in project
  all_refs = proj.files.map(&:real_path).map(&:to_s)
  if all_refs.include?(abs_path)
    puts "  SKIP (already in project): #{rel_path}"
    return
  end

  # Find/create the group
  scorepad_group = proj.main_group.children.find { |g| g.respond_to?(:path) && g.path == 'ScorePad' }
  raise 'ScorePad group not found' unless scorepad_group
  group = find_or_create_group(proj, scorepad_group, group_path)

  # Add the file reference
  file_ref = group.new_reference(abs_path)
  file_ref.path = File.basename(abs_path)
  file_ref.source_tree = '<group>'

  # Add to Sources build phase
  sources_phase.add_file_reference(file_ref)
  puts "  Added: #{rel_path}"
end

puts "=== Phase 1: Core scaffold files ==="
add_file(proj, target, sources_phase, 'Core/GameModule.swift',   ['Core'])
add_file(proj, target, sources_phase, 'Core/GameRegistry.swift', ['Core'])

puts "\n=== Phase 2: Player roster files ==="
add_file(proj, target, sources_phase, 'Core/Players/PersonProfile.swift',     ['Core', 'Players'])
add_file(proj, target, sources_phase, 'Core/Players/PlayerRosterView.swift',  ['Core', 'Players'])
add_file(proj, target, sources_phase, 'Core/Players/PlayerPickerField.swift', ['Core', 'Players'])

puts "\n=== Phase 4: Bridge module + adapter views ==="
add_file(proj, target, sources_phase, 'Modules/Bridge/BridgeModule.swift',             ['Modules', 'Bridge'])
add_file(proj, target, sources_phase, 'Modules/Bridge/Views/BridgeSessionListView.swift', ['Modules', 'Bridge', 'Views'])
add_file(proj, target, sources_phase, 'Modules/Bridge/Views/BridgeDetailView.swift',      ['Modules', 'Bridge', 'Views'])
add_file(proj, target, sources_phase, 'Modules/Bridge/Views/BridgeGridCard.swift',        ['Modules', 'Bridge', 'Views'])

puts "\n=== Phase 5: App navigation views ==="
add_file(proj, target, sources_phase, 'Views/AppRootView.swift',      ['Views'])
add_file(proj, target, sources_phase, 'Views/GameTypeGridView.swift',  ['Views'])

proj.save
puts "\n✓ Project saved."
