#!env coffee

fs = require 'fs'

try
  paths = require('./config.json').paths
catch error
  paths = ("data/example#{n}.txt" for n in [1..1])


for path in paths
  fs.exists path, (exists) ->
    if exists
      fs.readFile path, 'utf8', (err, lines) ->
        throw err if err
        console.log lines
    else
      console.error "'#{path}' does not exist"