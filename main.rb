#!env ruby
require 'date'

Property = Struct.new(:property_id,:lat,:lng,:price)
Availability = Struct.new(:property_id,:date,:available,:price)
Search = Struct.new(:search_id,:lat,:lng,:checkin,:checkout)
Price = Struct.new(:search_id,:rank,:property_id,:total_price)

# TODO: remove from global scope
$dates = []
$properties = []
$searches = []

section = nil
$stdin.each_line do |line|
  # Check if we are in a new section
  if /Properties|Dates|Searches/.match(line)
    section = line.chomp()
  else
    line = line.split(',')
    case section
    when "Properties"
      $properties << Property.new(line[0].to_i,line[1].to_f,line[2].to_f,line[3].to_i)
    when "Dates"
      special_price = (line[3] == nil or line[3] == "\n") ? nil : line[3].to_i
      $dates << Availability.new(line[0].to_i,Date.parse(line[1]),line[2].to_i,special_price)
    when "Searches"
      $searches << Search.new(line[0].to_i,line[1].to_f,line[2].to_f,Date.parse(line[3]),Date.parse(line[4]))
    end
  end
end

# Filter local properties
def local_properties(lat,lng)
  return $properties.select { |property| 
    property.lat.between?(lat-1, lat+1) && property.lng.between?(lng-1, lng+1)
  }
end

# Returns date information in a checkin range for a property, if 
# and only if that property is available
def available_dateinfo(property, checkin, checkout)
  # First get all the information about a property in a date range
  dateinfo = $dates.select {|date|
    date.property_id == property.property_id &&
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

# Calculate the cost of a stay
def get_cost(property, checkin, checkout)
  # get date information if that property is available
  if dateinfo = available_dateinfo(property, checkin, checkout)
    # calculate the normal cost
    total_price = property.price * (checkout-checkin)

    # factor in for special costs
    dateinfo.each do |date|
      if date.price
        total_price += date.price - property.price
      end
    end
  else
    return nil
  end

  return total_price
end

# this is gonna be O(n^3) or something stupid like that to start :(
$searches.each do |search|
  prices = []
  
  # for each property in the area
  local_properties(search.lat,search.lng).each do |property|
    # record the cost of a stay, if available
    if price = get_cost(property, search.checkin, search.checkout)
      prices << Price.new(search.search_id, 0, property.property_id, price)
    end
  end

  # display prices
  prices = prices.sort_by{ |price| price.total_price }
  prices[0..9].each_with_index do |price, index|
    puts "#{price.search_id},#{index+1},#{price.property_id},#{price.total_price}"
  end
end