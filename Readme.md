Questions
---------

  Are the three sections necessarily in order?
    Version 1 we will assume is in order

  Which filters more on first run of data, lat/lng or date?
    Assuming lat/lng for now, since its first in the description

Strategy
--------

  3 hours, was planning on using node until I found out its not supported by this interview website. Switching to ruby, where I am rusty, so going to have to brute force before architecting a nicer solution. Wonder if it would be cheating to write in node anyway and just have ruby hit the api. Or if theres a way to run node in the JVM.

  Testing on a 13" laptop. Hopfully it will be testing on something comparable in power.

Running
-------

    ./main.rb

Backend Problem
---------------

  You will be provided with availability and pricing data for a set of rental properties.  Your program will determine the cheapest properties for a given date range in a specific geographic area.
 
  You will read input from STDIN and print output to STDOUT.
 
#### Input
  The input is in CSV format with three sections of data.  "Properties", "Dates", and "Searches".  Each section will begin with a single line labeling the section followed by a number of lines with that section's data.
 
### Output
 
  Your program should output the properties that match each search, up to a maximum of 10 properties per search.  Some searches may return no results.
 
  The results should be ordered by cheapest total price for the stay, also matching the availability dates and geographic filter.  (If two properties have the same total price, sort by property_id ascending).  For the geographic filter, use a bounding box that is 2 degrees square in total (ie, +/- 1.0 degrees from each coordinate).  If a property is unavailable for any date during the range, it is not a valid result.  If a property has a variable price in the specified date range, that variable price overrides the base nightly price for that night.  The total price is the sum of the nightly prices for the entire stay.
 
  Note that properties do not need to be available on the checkout date itself, just on the day before.
 
  Your program should produce output with the following columns.  Each result for a given search should appear on it's own line.  A search with zero results does not need to be included in the output.
 
  - search_id (integer)
  - rank (integer, starting with 1, max of 10)
  - property_id (integer)
  - total_price (integer dollars, total price of stay)