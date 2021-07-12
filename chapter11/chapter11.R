
## The data have been dowloaded at:
#
#? https://earthquake.usgs.gov/earthquakes/search/#%7B%22currentfeatureid%22%3Anull%2C%22mapposition%22%3A%5B%5B-86.83673%2C-16.875%5D%2C%5B86.83673%2C376.875%5D%5D%2C%22autoUpdate%22%3A%5B%22autoUpdate%22%5D%2C%22feed%22%3A%22search_undefined%22%2C%22listFormat%22%3A%22default%22%2C%22restrictListToMap%22%3A%5B%5D%2C%22sort%22%3A%22newest%22%2C%22basemap%22%3A%22grayscale%22%2C%22overlays%22%3A%5B%22plates%22%5D%2C%22timezone%22%3A%22utc%22%2C%22viewModes%22%3A%5B%22list%22%2C%22map%22%5D%2C%22event%22%3Anull%2C%22search%22%3A%7B%22name%22%3A%22Search%20Results%22%2C%22params%22%3A%7B%22starttime%22%3A%222021-07-05%2000%3A00%3A00%22%2C%22endtime%22%3A%222021-07-12%2023%3A59%3A59%22%2C%22minmagnitude%22%3A7%2C%22orderby%22%3A%22time%22%7D%7D%7D
#
# from 1900 (included) to 2007 (excluded), only for a magnitude >= 7

#### Load library
rm(list = ls())
graphics.off()

library(data.table)
library(stringi)

options(max.print = 500)

#### Load data
earthquakes = fread("../data/dataEarthquakes.csv")
earthquakes[, year := format(time, "%Y")]
earthquakes[, n := .N, by = year]
earthquakes = unique(earthquakes[, .(year, n)])

plot(earthquakes$year, earthquakes$n, type = "l")
points(earthquakes$year, earthquakes$n, pch = 20)
