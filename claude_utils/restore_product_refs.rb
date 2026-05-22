#!/usr/bin/env ruby
# Restores product file references for each target (removed by the faulty cleanup script).

require 'xcodeproj'

PROJECT_PATH = File.join(__dir__, '..', 'ScorePad.xcodeproj')
proj = Xcodeproj::Project.open(PROJECT_PATH)

products_group = proj.main_group.children.find { |g| g.respond_to?(:name) && g.name == 'Products' }
unless products_group
  products_group = proj.main_group.new_group('Products')
  puts "Created Products group"
end

proj.targets.each do |target|
  next if target.product_reference

  extension = case target.product_type
    when 'com.apple.product-type.application' then 'app'
    else 'xctest'
  end

  filename = "#{target.product_name}.#{extension}"

  # Create a raw PBXFileReference
  ref = proj.new(Xcodeproj::Project::Object::PBXFileReference)
  ref.path = filename
  ref.source_tree = 'BUILT_PRODUCTS_DIR'
  ref.include_in_index = '0'
  ref.explicit_file_type = target.product_type == 'com.apple.product-type.application' \
    ? 'wrapper.application' : 'wrapper.cfbundle'

  products_group.children << ref
  target.product_reference = ref
  puts "Restored: #{filename}"
end

proj.save
puts "✓ Product refs restored."
