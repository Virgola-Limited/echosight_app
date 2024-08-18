# config/initializers/jemalloc.rb

jemalloc_path = File.join(ENV['RENDER_APP_DIR'], 'jemalloc', 'lib', 'libjemalloc.so')

puts "Debug: Checking for jemalloc at: #{jemalloc_path}"
puts "Debug: LD_PRELOAD = #{ENV['LD_PRELOAD']}"
puts "Debug: LD_LIBRARY_PATH = #{ENV['LD_LIBRARY_PATH']}"

if File.exist?(jemalloc_path)
  puts "jemalloc library found at #{jemalloc_path}"
  if ENV['LD_PRELOAD']&.include?('libjemalloc.so')
    puts "jemalloc is preloaded"
  else
    warn "jemalloc is installed but not preloaded. Performance may be affected."
  end
else
  warn "jemalloc library not found at #{jemalloc_path}. Performance may be affected."
end

puts "Debug: Current environment variables:"
ENV.each { |key, value| puts "#{key} = #{value}" }