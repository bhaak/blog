#!/usr/bin/env -S ruby -W2 -w

require 'optparse'
require 'date'

options = {}
parser = OptionParser.new do |opts|
 opts.banner = "Usage: ruby create_post.rb [options] TITLE"
 opts.separator ""
 opts.separator "Options:"

 opts.on("-c", "--categories CATS", "Comma-separated categories") { |v| options[:categories] = v }
 opts.on("-t", "--tags TAGS", "Comma-separated tags") { |v| options[:tags] = v }
 opts.on("-h", "--help", "Prints this help") do
   puts opts
   exit
 end
end

begin
 parser.parse!
rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
 puts "Error: #{e.message}"
 puts parser
 exit 1
end

if ARGV.empty?
 puts parser
 exit 1
end

title = ARGV.join(' ')
slug = title.downcase.gsub(/\s+/, '-')
date = Date.today.iso8601
filename = "content/posts/#{date}-#{slug}.md"

cmd = ["hugo", "new", filename]
system(*cmd)

if options[:categories] || options[:tags]
 # Using File.read/write to update front matter
 # This assumes hugo created the file successfully
 content = File.read(filename)

 # Ensure the title matches the user input
 content.sub!(/^title\s*=.*$/, "title = '#{title}'")

 if options[:categories]
   cats = options[:categories].split(',').map(&:strip)
   if content.match?(/^categories\s*=/)
     content.sub!(/^categories\s*=.*$/, "categories = #{cats}")
   else
     content.sub!(/^title\s*=.*$/, "\\0\ncategories = #{cats}")
   end
 end

 if options[:tags]
   tags = options[:tags].split(',').map(&:strip)
   if content.match?(/^tags\s*=/)
     content.sub!(/^tags\s*=.*$/, "tags = #{tags}")
   else
     content.sub!(/^title\s*=.*$/, "\\0\ntags = #{tags}")
   end
 end

 File.write(filename, content)

end

puts "Created #{filename}"
