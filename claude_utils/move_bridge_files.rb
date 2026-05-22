#!/usr/bin/env ruby
# Moves Bridge model and view files to Modules/Bridge/ and updates the Xcode project.

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH = File.join(__dir__, 'ScorePad.xcodeproj')
SOURCES_ROOT = File.join(__dir__, 'ScorePad')

proj = Xcodeproj::Project.open(PROJECT_PATH)
target = proj.targets.find { |t| t.name == 'ScorePad' }

# ── Helpers ──────────────────────────────────────────────────────────────────

def find_group(proj, path_array)
  grp = proj.main_group
  path_array.each do |name|
    grp = grp.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXGroup) && (c.name == name || c.path == name) }
    return nil unless grp
  end
  grp
end

def find_or_create_group(proj, parent, name, path)
  child = parent.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.path == path }
  return child if child
  child = parent.new_group(name, path)
  puts "  Created group: #{path}"
  child
end

def move_file_ref(proj, filename, from_group, to_group, new_filename = nil)
  ref = from_group.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXFileReference) && c.path == filename }
  unless ref
    puts "  WARN: file ref not found in group: #{filename}"
    return
  end
  ref.path = new_filename || filename
  from_group.children.delete(ref)
  to_group.children << ref
  puts "  Moved ref: #{filename} → #{to_group.path}/#{ref.path}"
end

# ── Locate current groups ─────────────────────────────────────────────────────

scorepad_grp = find_group(proj, ['ScorePad'])
raise 'ScorePad group not found' unless scorepad_grp

model_grp = scorepad_grp.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.path == 'Model' }
raise 'Model group not found' unless model_grp

# ── Create Modules/Bridge/Model and Modules/Bridge/Views groups ───────────────

puts "\n=== Creating group hierarchy ==="
modules_grp = find_or_create_group(proj, scorepad_grp, 'Modules', 'Modules')
bridge_grp  = find_or_create_group(proj, modules_grp,  'Bridge',  'Bridge')
bmodel_grp  = find_or_create_group(proj, bridge_grp,   'Model',   'Model')
bviews_grp  = find_or_create_group(proj, bridge_grp,   'Views',   'Views')

# ── Move filesystem files: Model ──────────────────────────────────────────────

model_files = %w[
  Rubber.swift Auction.swift AuctionResult.swift Contract.swift
  Call.swift Score.swift Position.swift Team.swift Player.swift
  Game.swift Suit.swift Bid.swift
]

puts "\n=== Moving Model files to Modules/Bridge/Model/ ==="
model_files.each do |f|
  src = File.join(SOURCES_ROOT, 'Model', f)
  dst = File.join(SOURCES_ROOT, 'Modules', 'Bridge', 'Model', f)
  if File.exist?(src)
    FileUtils.mv(src, dst)
    puts "  mv #{f}"
  else
    puts "  SKIP (not on disk): #{f}"
  end
  move_file_ref(proj, f, model_grp, bmodel_grp)
end

# Remove old Model group (now empty)
if model_grp.children.empty?
  model_grp.remove_from_project
  puts "  Removed empty Model group"
end

# ── Move filesystem files: Views ──────────────────────────────────────────────

view_files = %w[
  AuctionView.swift BiddingView.swift CallView.swift
  NewRubber.swift RubberHeader.swift RubberList.swift
  RubberListCell.swift RubberView.swift ScoreView.swift
]

puts "\n=== Moving View files to Modules/Bridge/Views/ ==="
view_files.each do |f|
  src = File.join(SOURCES_ROOT, f)
  dst = File.join(SOURCES_ROOT, 'Modules', 'Bridge', 'Views', f)
  if File.exist?(src)
    FileUtils.mv(src, dst)
    puts "  mv #{f}"
  else
    puts "  SKIP (not on disk): #{f}"
  end
  move_file_ref(proj, f, scorepad_grp, bviews_grp)
end

proj.save
puts "\n✓ Project saved."
