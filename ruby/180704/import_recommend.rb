require 'csv'

female_20_idx, male_20_idx, female_30_idx, male_30_idx = 2, 8, 14, 20
segment_female_20, segment_male_20, segment_female_30, segment_male_30 = [19, 20, 21], [10, 11, 12], [22, 23], [13, 14]
recommend_instanse = {}

CSV.foreach('180628_nanaco.csv', headers: false).with_index do |row, ln|
  begin
  next if ln < 2
  next unless row[3].nil?

  case ln
  when female_20_idx
    p recommend_instanse
    recommend_instanse = { title_01: row[1], title_02: row[2], segments: segment_female_20, shops: [] }
  when male_20_idx
    p recommend_instanse
    recommend_instanse = { title_01: row[1], title_02: row[2], segments: segment_male_20, shops: [] }
  when female_30_idx
    p recommend_instanse
    recommend_instanse = { title_01: row[1], title_02: row[2], segments: segment_female_30, shops: [] }
  when male_30_idx
    p recommend_instanse
    recommend_instanse = { title_01: row[1], title_02: row[2], segments: segment_male_30, shops: [] }
  else
  end
  shop = { name: row[3], shop_comment: row[5], tabelog_url: row[6], image_urls: [row[7], row[8], row[9]] }
  recommend_instanse[:shops] << shop
  rescue => e

  end
end
