require 'open-uri'
require 'json'

class TVCrawler
  TV_SHOWS_LIST_URL = 'http://en.wikipedia.org/wiki/List_of_television_programs_by_name'
  BASE_URL = 'http://en.wikipedia.org'
  
  def crawl
    resource_urls = self.get_resource_urls
    resource_urls.each do |resource_url|
      begin
        info_box = self.get_info_box(resource_url[0])
        unless info_box.nil?
          sleep(rand * 2)
          info_box = info_box[0] 
          run_dates = self.get_run_dates(info_box)
          dates = self.parse_dates(run_dates)
          title = self.get_title(info_box)
          unless title.nil? || title.empty?
            data_hash = {
              title: title,
              genres: self.get_genres(info_box),
              creators: self.get_creators(info_box),
              cast: self.get_cast(info_box),
              country_of_origin: self.get_country(info_box),
              seasons: self.get_seasons(info_box),
              episodes: self.get_episodes(info_box),
              start_date: dates[0],
              end_date: dates[1]
            }
            file_name = data_hash[:title].gsub(/[^\w]/, '_') + '.json'
            File.open(file_name, 'w') { |f| f.write(data_hash.to_json) }
            puts "Created file: " + file_name
          end
        end
      rescue
        puts "Uh oh, something went wrong."
        next
      end
    end
  end
  
  def get_resource_urls
    list_page_string = open(TV_SHOWS_LIST_URL) { |f| f.read }
    resource_urls = list_page_string.scan(/<li><i><a href="(.*?)".+<\/li>/)
  end
  
  def get_info_box(resource_url)
    resource_page_string = open(BASE_URL + resource_url) { |f| f.read }
    resource_page_string.match(/<table class="infobox.+<\/table>/m)
  end
    
  def get_title(info_box)
    title = info_box[/<th colspan="2" class="summary.+>(.*?)<\/th>/, 1]
    if title.nil? || title.empty?
      title = info_box[/<i>(.*?)<\/i><\/th>/, 1] || info_box[/<b>(.*?)<\/b><\/th>/, 1] || info_box[/>(.*?)<\/span><\/th>/, 1]
      if title.nil? || title.empty? || title.match(/[<>]/)
        title = nil
      end
    end
    title
  end
    
  def get_genres(info_box)
    genres = info_box[/<td class="category">(.*?)<\/td>/m]
    genres_list = []
    if genres
      genres_list = genres.scan(/<a.+>(.*?)<\/a>/).map { |el| el[0]}
      if genres_list.empty?
        genres_list = genres.scan(/>\s?([a-zA-Z\s-]{2,})\s?</m).map { |el| el[0] }
      end
    end
    genres_list
  end 
  
  def get_creators(info_box)
    creators = info_box[/>Created by<\/th>(.*?)<\/tr>/m, 1] 
    creators ||= info_box[/>Developed by<\/th>(.*?)<\/tr>/m, 1] 
    if creators
      creators = creators.scan(/>\s?([a-zA-Z\.\s-]{2,})\s?</).map { |el| el[0] }
    end
    creators || []
  end
  
  def get_cast(info_box)
    cast = info_box[/>Starring<\/th>(.*?)<\/tr>/m, 1]
    cast ||= info_box[/>Voices of<\/th>(.*?)<\/tr>/m, 1]
    if cast 
      cast = cast.scan(/>\s?([a-zA-Z\.\s]{2,})\s?</).map { |el| el[0] }
    end
    cast || []
  end
  
  def get_country(info_box)
    country = info_box[/>Country of origin<\/th>(.*?)<\/tr>/m, 1]
    if country
      country = country.match(/>\s?([a-zA-Z\.\s]{2,})\s?</)
      if country
        country = country[0][1...-1]
      end
    end
    country
  end
  
  def get_seasons(info_box)
    seasons = info_box[/>No. of seasons<\/th>(.*?)<\/tr>/m, 1]
    if seasons
      seasons = seasons.match(/[\d]+/)
      if seasons
        seasons = seasons[0].to_i
      end
    end
    seasons
  end
  
  def get_episodes(info_box)
    episodes = info_box[/>No. of episodes<\/th>(.*?)<\/tr>/m, 1]
    if episodes
      episodes = episodes.match(/[\d]+/)
      if episodes
        episodes = episodes[0].to_i
      end
    end
    episodes
  end
  
  def get_run_dates(info_box)
    run_dates = info_box[/>Original run<\/th>(.*?)<\/tr>/m, 1]
    start_date, end_date = nil, nil
    if run_dates
      dates_list = run_dates.scan(/\d\d\d\d-\d\d-\d\d|\w+\s\d+,?\s\d\d\d\d|\d+\s\w+,?\s\d\d\d\d|\w+&#160;\d+,?&#160;\d\d\d\d|\d+&#160;\w+,?&#160;\d\d\d\d/)
      unless dates_list.empty?
        start_date = dates_list[0].gsub(/&#160;/, " ")
        end_date = dates_list[-1].gsub(/&#160;/, " ")      
      end
      end_date = nil if end_date == start_date || run_dates.match("present")
    end
    [start_date, end_date]
  end
  
  def parse_dates(dates)
    start_date, end_date = nil, nil
    start_date = Date.parse(dates[0]) if dates[0]
    end_date = Date.parse(dates[1]) if dates[1]
    [start_date, end_date]      
  end
end
  
crawler = TVCrawler.new
crawler.crawl

