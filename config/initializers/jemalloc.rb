# config/initializers/jemalloc.rb

def find_jemalloc
  potential_paths = [
    ENV['LD_PRELOAD'],
    '/opt/render/project/src/jemalloc/lib/libjemalloc.so',
    '/opt/render/project/jemalloc/lib/libjemalloc.so',
    File.join(Rails.root, 'jemalloc', 'lib', 'libjemalloc.so')
  ]

  potential_paths.each do |path|
    if path && File.exist?(path)
      puts "Found jemalloc at: #{path}"
      return path
    else
      puts "jemalloc not found at: #{path}"
    end
  end

  nil
end

puts "Debug: Checking for jemalloc"
puts "Debug: LD_PRELOAD = #{ENV['LD_PRELOAD']}"
puts "Debug: LD_LIBRARY_PATH = #{ENV['LD_LIBRARY_PATH']}"

jemalloc_path = find_jemalloc

if jemalloc_path
  puts "jemalloc library found at #{jemalloc_path}"
  if ENV['LD_PRELOAD']&.include?('libjemalloc.so')
    puts "jemalloc is preloaded"
  else
    warn "jemalloc is installed but not preloaded. Performance may be affected."
  end
else
  warn "jemalloc library not found. Performance may be affected."
end

puts "Debug: Current environment variables:"
ENV.each { |key, value| puts "#{key} = #{value}" }