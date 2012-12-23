#!env ruby
=begin

Note
----

  Just trying to solve the challenge, for all submissions after 5:00. Not game the system.

Ambiguities
-----------

  Are the three sections of the csv necessarily in order?

  Which filters more on first run of data, lat/lng or date?
    Assuming lat/lng for now, since its first in the description
    This kind of optimization is out of scope for given data & time constraint

Strategy
--------

  InterviewStreet did not list node.js as a possible environment in their FAQ, so ruby it is.
  Brute force, memory intensive solution first.
  Did not notice that the challenge FAQ was different than the main FAQ, so missed out on the
  information about 256Mb 32bit quad core xeon on ubuntu as a testing environment.
  More about my thought process can be gleaned from github.com/jedahan/airbnb.
  It's a private repo until permission is granted to open it up.

Goals
-----

  Only use core libraries from ruby 1.8.7

Improvements
------------

  Factor out pricing algorithm
  Filter duplicates
  Apply consistent code style to variable_names, functionNames, and DataStructures
  Actually build a custom data structure, some options:
    column oriented - good if code complexity/flexibility is cheap
    flattened - good if RAM is cheap and code complexity is more expensive

  Change architecture to stream search results instead of batch
    streaming - good if data access is fast, response time is important

Thoughts
--------
  Ruby is so flexible, which is a asset and a drawback.
  It shows that my variable and function names switch between camelCase and under_scores
  as my brain switches between callback/node.js thinking to synchronous/pythony thinking.

  Fun challenge
=end

require 'date'

Property = Struct.new(:property_id,:lat,:lng,:price)
DateAvailability = Struct.new(:property_id,:date,:available,:price)
Search = Struct.new(:search_id,:lat,:lng,:checkin,:checkout)
Price = Struct.new(:search_id,:rank,:property_id,:total_price)

section = nil
sections = /Properties|Dates|Searches/

# TODO: remove from global scope
$dates = []
$properties = []
$searches = []

def ParseDate(dateString)
  s = dateString.split(',')
  special_price = (s[3] == nil or s[3] == "\n") ? nil : s[3].chomp()
  $dates << DateAvailability.new(s[0].to_i,Date.parse(s[1]),s[2].chomp(),special_price.to_i)
end

def ParseProperty(propertyString)
  s = propertyString.split(',')
  $properties << Property.new(s[0].to_i,s[1].to_f,s[2].to_f,s[3].chomp().to_i)
end

def ParseSearch(searchString)
  s = searchString.split(',')
  $searches << Search.new(s[0].to_i,s[1].to_f,s[2].to_f,Date.parse(s[3]),Date.parse(s[4].chomp()))
end

$stdin.each_line do |l|
  # Check if we are in a new section
  if sections.match(l)
    section = l.chomp()
  else
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

def local_properties(lat,lng)
  return $properties.select { |property| 
    property.lat.between?(lat-1, lat+1) and
    property.lng.between?(lng-1, lng+1)
  }
end

# Returns date information in a checkin range for a property, if 
# and only if that property is available
def available_dateinfo(property,checkin,checkout)
  # First get all the information about a property in a date range
  dateinfo = $dates.select {|date|
    date.property_id == property.property_id and
    date.date === checkin.upto(checkout-1) {}
  }
  
  # Its less painful to miss an available booking than be denied at the door
  if dateinfo.length == 0 then return nil end

  # Check if any dates in that range are unavailable
  dateinfo.each do |date|
    if date.available == 0 then return nil end
  end

  # We found some info
  return dateinfo
end

# this is gonna be O(n^3) or something stupid like that to start :(
$searches.each do |search|
  prices = []
  
  # for each property in the area properties
  local_properties(search.lat,search.lng).each do |property|
    # get date information if that property is available
    dateinfo = available_dateinfo(property, search.checkin, search.checkout)
    # if we can book
    if dateinfo != nil
      # calculate the normal cost
      total_price = property.price * (search.checkout-search.checkin)

      # factor in for special costs
      dateinfo.each do |date|
        if date.price
          total_price += date.price - property.price
        end
      end
      prices << Price.new(search.search_id, 0, property.property_id, total_price)
    end
  end

  prices = prices.sort_by{ |price| price.total_price }
  prices[0..9].each_with_index do |price, index|
    puts "#{price.search_id},#{index+1},#{price.property_id},#{price.total_price}"
  end
end