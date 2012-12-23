#!env ruby

require 'date'

Property = Struct.new(:property_id,:lat,:lng,:price)
DateAvailability = Struct.new(:property_id,:date,:available,:price)
Search = Struct.new(:search_id,:lat,:lng,:checkin,:checkout)
Price = Struct.new(:search_id,:rank,:property_id,:total_price)

# TODO: remove from global scope
$dates = []
$properties = []
$searches = []

section = nil
$stdin.each_line do |line|
  # Check if we are in a new section
  if sections.match(/Properties|Dates|Searches/)
    section = line.chomp()
  else
    line = line.split(',')
    case section
    when "Properties"
      $properties << Property.new(line[0].to_i,line[1].to_f,line[2].to_f,line[3].to_i)
    when "Dates"
      special_price = (line[3] == nil or line[3] == "\n") ? nil : line[3].to_i
      $dates << DateAvailability.new(line[0].to_i,Date.parse(line[1]),line[2].to_i,special_price)
    when "Searches"
      $searches << Search.new(line[0].to_i,line[1].to_f,line[2].to_f,Date.parse(line[3]),Date.parse(line[4])
    end
  end
end

# Filter local properties
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