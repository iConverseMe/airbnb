#!env ruby
require 'date'

Property = Struct.new(:id,:lat,:lng,:price)
DateAvailability = Struct.new(:id,:date,:available,:price)
Search = Struct.new(:id,:lat,:lng,:checkin,:checkout)

section = nil
sections = /Properties|Dates|Searches/

# arrays to hold all our data. big waste of memory right now.
# they should also not be global
$dates = []
$properties = []
$searches = []

def ParseDate(dateString)
  #puts "parsing #{dateString}"
  s = dateString.split(',')
  special_price = (s[3] == nil or s[3] == "\n") ? nil : s[3].chomp()
  $dates << DateAvailability.new(s[0],Date.parse(s[1]),s[2].chomp(),special_price)
end

def ParseProperty(propertyString)
  #puts "defining #{propertyString}"
  s = propertyString.split(',')
  $properties << Property.new(s[0],s[1],s[2],s[3].chomp())
end

def ParseSearch(searchString)
  #puts "searching #{searchString}"
  s = searchString.split(',')
  $searches << Search.new(s[0],s[1],s[2],Date.parse(s[3]),Date.parse(s[4].chomp()))
end

$stdin.each_line do |l|
  # Check if we are in a new section
  if sections.match(l)
    #puts "[DEBUG] Section #{l}"
    section = l.chomp()
  else
    #puts "[DEBUG] Parsing #{section} #{l}"
    case section
    when "Properties"
      ParseProperty(l)
    when "Dates"
      ParseDate(l)
    when "Searches"
      ParseSearch(l)
    end
  end
end

puts $dates, $properties, $searches