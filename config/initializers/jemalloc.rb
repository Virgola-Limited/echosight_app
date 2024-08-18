# config/initializers/jemalloc.rb

def debug_print(message)
  puts "JEMALLOC_DEBUG: #{message}"
end

debug_print "==== Jemalloc Initializer Start ===="
debug_print "Rails.root: #{Rails.root}"
debug_print "PWD: #{Dir.pwd}"
debug_print "HOME: #{ENV['HOME']}"

jemalloc_path = ENV['LD_PRELOAD']

debug_print "Checking for jemalloc at: #{jemalloc_path}"
if jemalloc_path && File.exist?(jemalloc_path)
  debug_print "jemalloc library found at #{jemalloc_path}"
  begin
    require 'fiddle'
    je_malloc = Fiddle::Function.new(
      Fiddle::Handle::DEFAULT['je_malloc'],
      [Fiddle::TYPE_SIZE_T],
      Fiddle::TYPE_VOIDP
    )
    debug_print "jemalloc successfully detected (je_malloc function found)"
  rescue => e
    debug_print "Failed to detect jemalloc: #{e.message}"
    debug_print "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
  end
else
  debug_print "Warning: jemalloc library not found. Performance may be affected."
end

debug_print "==== File System Check ===="
debug_print `ls -l /usr/lib/*jemalloc* 2>&1`
debug_print `ls -l /usr/lib/x86_64-linux-gnu/*jemalloc* 2>&1`

debug_print "==== Environment Variables ===="
debug_print "LD_PRELOAD: #{ENV['LD_PRELOAD']}"
debug_print "LD_LIBRARY_PATH: #{ENV['LD_LIBRARY_PATH']}"

debug_print "==== Process Information ===="
debug_print "Process ID: #{Process.pid}"
debug_print "Parent Process ID: #{Process.ppid}"
debug_print "Process Command Line: #{File.read("/proc/#{Process.pid}/cmdline").gsub("\0", ' ')}"

debug_print "==== Jemalloc Initializer End ===="