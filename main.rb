#!env ruby
require 'date'

Property = Struct.new(:property_id,:lat,:lng,:price)
DateAvailability = Struct.new(:property_id,:date,:available,:price)
Search = Struct.new(:search_id,:lat,:lng,:checkin,:checkout)
Price = Struct.new(:search_id,:rank,:property_id,:total_price)

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
  $dates << DateAvailability.new(s[0].to_i,Date.parse(s[1]),s[2].chomp(),special_price.to_i)
end

def ParseProperty(propertyString)
  #puts "defining #{propertyString}"
  s = propertyString.split(',')
  $properties << Property.new(s[0].to_i,s[1].to_f,s[2].to_f,s[3].chomp().to_i)
end

def ParseSearch(searchString)
  #puts "searching #{searchString}"
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
    date.date === checkin.upto(checkout) {}
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

# this is gonna be O(n^3) or something stupid like that to start.
$searches.each do |search|
  prices = []
  
  # for each property in the area properties
  local_properties(search.lat,search.lng).each do |property|
    # get date information if that property is available
    dateinfo = available_dateinfo(property, search.checkin, search.checkout)
    # if we can book
    if dateinfo != nil
      total_price = 0
      # calculate the normal cost
      for day in search.checkin...search.checkout
        total_price += property.price
      end
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

#puts $dates, $properties, $searches