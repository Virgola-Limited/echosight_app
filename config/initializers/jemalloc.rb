# config/initializers/jemalloc.rb

if ENV['LD_PRELOAD']&.include?('libjemalloc.so')
  puts "jemalloc is preloaded"
else
  warn "jemalloc is not preloaded. Performance may be affected."
end