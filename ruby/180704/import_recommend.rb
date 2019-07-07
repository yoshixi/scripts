require 'csv'
require 'pry'

female_20_idx, male_20_idx, female_30_idx, male_30_idx = 2, 8, 14, 20
segment_female_20, segment_male_20, segment_female_30, segment_male_30 = [19, 20, 21], [10, 11, 12], [22, 23], [13, 14]
male_30_last_idx = 25
recommend_instanse = {}
blank_rows = [7, 13, 19]

CSV.foreach('180628_nanaco.csv', headers: false).with_index do |row, ln|
  next if ln < 2 || blank_rows.include?(ln)
  case ln
  when female_20_idx
    recommend_instanse = { title_01: row[1], title_02: row[2], segments: segment_female_20, shops: [] }
  when male_20_idx
    # create female 20 recommend
    p recommend_instanse
    recommend_instanse = { title_01: row[1], title_02: row[2], segments: segment_male_20, shops: [] }
  when female_30_idx
    # create male 20 recommend
    p recommend_instanse
    recommend_instanse = { title_01: row[1], title_02: row[2], segments: segment_female_30, shops: [] }
  when male_30_idx
    # create female 30 recommend
    p recommend_instanse
    recommend_instanse = { title_01: row[1], title_02: row[2], segments: segment_male_30, shops: [] }
  when male_30_last_idx
    # create male 30 recommend
  else
  end
  shop = { name: row[3], shop_comment: row[5], tabelog_url: row[6], image_urls: [row[7], row[8], row[9]], shop_id: row[11] }
  recommend_instanse[:shops] << shop
end

def create_recomend_resources(recommend_instanse: )
  recommend = Recommend.create(title_01: recommend_instanse[:title_01], title_02: recommend_instanse[:title_02])
  recommend_instanse[:segments].each do |segment_id|
    RecommendSegment.create(recommend: recommend, segment_id: segment_id)
  end
  recommend_instanse[:shops].each do |shop|
    shop_hash = tabelog_scraper(base_url: shop[:tabelog_url])
    if shop[:shop_id] == 'none'
      shop = Shop.create(shop_hash)
    else
      shop = Shop.find(shop[:shop_id])
      shop.update(shop_hash)
    end
    shop[:image_urls].each do |url|
      shop.shop_photos.create(photo_url: url, user_id: 408, is_public: true)
    end
  end
end

def tabelog_scraper(base_url:)
  tr_name_arr =['店名', 'ジャンル', '住所', '交通手段', '営業時間', '定休日', '電話番号']
  data_hash = {}
  begin
    base_url = 'https://' + base_url.match(%r{(s.|)tabelog.com\/(\w*\/){4}})[0]
    charset = nil
    html = open(base_url) do |f|
      charset = f.charset # 文字種別を取得
      f.read # htmlを読み込んで変数htmlに渡す
    end
    puts "get request"

    doc = Nokogiri::HTML(html)
    tr_list = doc.css('#contents-rstdata table tr')

    tr_list.each do |tr|
      key = tr.css('th').inner_text.gsub(/\s/, "")
      val = tr.css('td').inner_text.strip
      data_hash.store(key, val).gsub(/\n/," ").gsub(/\s*/, "\s")

      # tabelogのdataからlon, lat取得
      if key == '住所'
        lonlat_str = tr.css('td img.js-map-lazyload.lazy-loaded').attribute('data-original')
        lonlats = lonlat_str.scan(/(&center=|)([1-9]\d*|0)(\.\d+)/)
        latitude =lonlats[0][1] + lonlats[0][2]
        longitude =lonlats[1][1] + lonlats[1][2]
      end
    end
    name = data_hash['店名'].try(:chomp)
    genre = data_hash['ジャンル'].try(:tr,'、', ' ')
    address = data_hash['住所'].try(:gsub, /\n.*/, '')
    access = data_hash['交通手段'].try(:sub, /\n.*/, '')
    hours = data_hash['営業時間']
    holidays = data_hash['定休日']
    budget = data_hash['予算'].try(:chomp)
    reservation_number = data_hash['電話番号']
  rescue
    return nil
  end

  # 食べログから取れなかったらgeocoding
  if longitude.nil? && latitude.nil?
    lonlat = get_geocode(name, 0)
    lonlat = get_geocode(address, 1) if lonlat[:lat].to_f <= 0 || lonlat[:lng].to_f <= 0
    latitude = lonlat[:lat]
    longitude = lonlat[:lng]
  end

  {
    name: name,
    address: address,
    longitude: longitude,
    latitude: latitude,
    reservation_number: reservation_number,
    access: access,
    hours: hours,
    holidays: holidays,
    store_budget: budget,
    user_budget: budget,
    genre: genre,
    tabelog_url: base_url
  }
end

def get_geocode(params, count)
  re_hash = {}
  key = ENV['GOOGLE_API_KEY']
  uri = URI.parse(URI.encode "https://maps.google.com/maps/api/geocode/json?address=#{params}&sensor=false&key=#{key}")
  res = Net::HTTP.get(uri)
  parsed = JSON.parse(res, {:symbolize_names => true})

  if parsed[:status] == "OK"
    results = parsed[:results][0]
    geo = results[:geometry][:location]
    lat = geo[:lat]
    lng = geo[:lng]
    re_hash.store(:lat, lat)
    re_hash.store(:lng, lng)
    puts "formatted_address #{results[:formatted_address]}"
    puts 'name で叩いた' if count == 0
    puts 'addressで叩いた' if count == 1
    return re_hash
  else
    return { lat: 45.6412626, lng: 154.0031455 } if count == 1 #日本のlonlat
    return { lat: 0, lng: 0 }
  end
end
