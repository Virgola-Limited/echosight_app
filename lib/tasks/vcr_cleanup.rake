# lib/tasks/vcr_cleanup.rake
require 'fileutils'

namespace :vcr do
  desc 'Clean up unused VCR cassettes based on spec descriptions'
  task cleanup: :environment do
    cassette_library_dir = 'spec/vcr_cassettes'
    referenced_cassettes = Set.new

    # Configure RSpec to load the spec files without running them
    RSpec.configure do |config|
      config.pattern = "**/*_spec.rb"
    end

    # Load the spec files to access the example groups and examples
    RSpec::Core::Runner.run([])

    # Iterate through example groups to collect cassette names
    RSpec.world.example_groups.each do |group|
      group.descendants.each do |descendant|
        next unless descendant.metadata[:vcr]

        # Construct cassette path from group descriptions
        parts = []
        current_group = descendant
        while current_group
          parts.unshift(current_group.description)
          current_group = current_group.parent
        end
        cassette_name = parts.join('/')
        referenced_cassettes << cassette_name
      end
    end

    raise "No referenced cassettes" if referenced_cassettes.empty?

    # Delete unreferenced cassettes
    Dir.glob("#{cassette_library_dir}/**/*.yml").each do |cassette_file|
      relative_path = cassette_file.sub(/^#{cassette_library_dir}\//, '').sub(/\.yml$/, '')
      unless referenced_cassettes.include?(relative_path)
        puts "Deleting unused VCR cassette: #{cassette_file}"
        FileUtils.rm(cassette_file)
      end
    end

    puts "Cleanup complete. Checked #{referenced_cassettes.size} referenced cassettes."
  end
end
