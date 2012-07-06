#!/usr/bin/env ruby

raise 'no bro' unless ARGV.count == 1

file= ARGV[0]
raise "#{file} already exists." if File.exists?(file)
$file= file

#puts "Starting..."
#puts "Delete #{file} to stop."
#while true
#  File.open(file,"a") {|fout| fout<< '.'}
#  sleep 0.2
#  break if !File.exists?(file)
#end
#
#puts "File deleted by external process. Shutting down."

at_exit { bye }
#Kernel.trap('INT') { bye }
def bye
  puts "Bye!"
  File.unlink $file if $file
end

puts "Starting..."
File.write(file,"a")
while sleep 0.1; end
