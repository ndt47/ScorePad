#!/usr/bin/env ruby
# Adds BridgeModule.swift and removes BridgeGridCard.swift from the Xcode project.

require 'xcodeproj'

PROJECT_PATH = File.join(__dir__, '..', 'ScorePad.xcodeproj')
SOURCES_ROOT = File.join(__dir__, '..', 'ScorePad')
TARGET_NAME  = 'ScorePad'

proj   = Xcodeproj::Project.open(PROJECT_PATH)
target = proj.targets.find { |t| t.name == TARGET_NAME }
raise "Target '#{TARGET_NAME}' not found" unless target

sources_phase = target.build_phases.find { |p| p.is_a?(Xcodeproj::Project::Object::PBXSourcesBuildPhase) }

# --- Remove BridgeGridCard.swift ---
grid_card_path = File.join(SOURCES_ROOT, 'Modules/Bridge/Views/BridgeGridCard.swift')
to_remove = proj.files.find { |f| f.real_path.to_s == grid_card_path }
if to_remove
  sources_phase.files.each do |bf|
    if bf.file_ref == to_remove
      sources_phase.remove_build_file(bf)
      break
    end
  end
  to_remove.remove_from_project
  puts "Removed: Modules/Bridge/Views/BridgeGridCard.swift"
else
  puts "SKIP (not in project): BridgeGridCard.swift"
end

# --- Add BridgeModule.swift ---
bridge_module_path = File.join(SOURCES_ROOT, 'Modules/Bridge/BridgeModule.swift')
unless File.exist?(bridge_module_path)
  puts "SKIP (file not on disk): BridgeModule.swift"
else
  already = proj.files.any? { |f| f.real_path.to_s == bridge_module_path }
  if already
    puts "SKIP (already in project): BridgeModule.swift"
  else
    scorepad_group = proj.main_group.children.find { |g| g.respond_to?(:path) && g.path == 'ScorePad' }
    modules_group = scorepad_group.children.find { |g| g.respond_to?(:name) && g.name == 'Modules' }
    bridge_group  = modules_group.children.find  { |g| g.respond_to?(:name) && g.name == 'Bridge' }
    raise 'Bridge group not found' unless bridge_group

    file_ref = bridge_group.new_reference(bridge_module_path)
    file_ref.path = 'BridgeModule.swift'
    file_ref.source_tree = '<group>'
    sources_phase.add_file_reference(file_ref)
    puts "Added: Modules/Bridge/BridgeModule.swift"
  end
end

proj.save
puts "✓ Project saved."
