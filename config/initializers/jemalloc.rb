# config/initializers/jemalloc.rb

if ENV['LD_PRELOAD']&.include?('libjemalloc.so')
  require 'jemalloc'
  puts "jemalloc loaded successfully"
else
  warn "jemalloc is not preloaded. Performance may be affected."
end