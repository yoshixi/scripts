require 'csv'

CSV.foreach('test.csv', headers: true).with_index(2) do |row, ln|
  
end
