# config/initializers/jemalloc.rb

puts "==== Runtime Environment ===="
puts "Rails.root: #{Rails.root}"
puts "PWD: #{Dir.pwd}"
puts "HOME: #{ENV['HOME']}"
puts "RENDER_PROJECT_DIR: #{ENV['RENDER_PROJECT_DIR']}"

jemalloc_path = '/opt/render/project/src/jemalloc/lib/libjemalloc.so'

puts "Debug: Checking for jemalloc at: #{jemalloc_path}"
puts "Debug: LD_PRELOAD = #{ENV['LD_PRELOAD']}"
puts "Debug: LD_LIBRARY_PATH = #{ENV['LD_LIBRARY_PATH']}"

if File.exist?(jemalloc_path)
  puts "jemalloc library found at #{jemalloc_path}"
  if ENV['LD_PRELOAD'] == jemalloc_path
    puts "jemalloc is correctly preloaded"
    begin
      require jemalloc_path
      puts "Successfully loaded jemalloc"
    rescue LoadError => e
      puts "Failed to load jemalloc: #{e.message}"
    end
  else
    warn "jemalloc is installed but not correctly preloaded. Current LD_PRELOAD: #{ENV['LD_PRELOAD']}"
  end
else
  warn "jemalloc library not found at #{jemalloc_path}. Performance may be affected."
end

# Try to detect if jemalloc is being used
begin
  require 'fiddle'
  je_malloc = Fiddle::Function.new(
    Fiddle::Handle::DEFAULT['je_malloc'],
    [Fiddle::TYPE_SIZE_T],
    Fiddle::TYPE_VOIDP
  )
  puts "jemalloc seems to be in use (je_malloc function found)"
rescue => e
  puts "Could not detect jemalloc usage: #{e.message}"
end

puts "==== All Environment Variables ===="
ENV.sort.each { |key, value| puts "#{key}: #{value}" }