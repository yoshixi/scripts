# coding: utf-8

require 'csv'

CSV.open("./data/pmtokyo-20190707.csv", "r") do |row|
  p row
end

