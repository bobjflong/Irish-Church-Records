
require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'dalli'
require 'sinatra/cross_origin'

cache = Dalli::Client.new(nil, {:expires_in => 60*100})
set :cache, cache

configure do
  enable :cross_origin
end

set :allow_origin, :any

$BASE = "http://churchrecords.irishgenealogy.ie/churchrecords/search.jsp?"

get "/search" do
  content_type 'text/json', :charset => 'utf-8'
  url = "#{$BASE}namefm=#{params[:fname]}&namel=#{params[:lname]}&location=#{params[:location]}&dd=#{params[:dd]}&&mm=#{params[:mm]}&&yy=#{params[:yy]}&submit=Search&pager.offset=#{params[:offset]}"
  has = settings.cache.get(url)
  return has if has
  begin
    @doc = Nokogiri::HTML(open(URI.escape(url)))
  rescue
    return { "more" => false, "queryresults" => [], "info" => "Invalid search" }.to_json
  end
  resp = ""
  results = { "more" => !@doc.css('.next').first.nil?, "queryresults" => [], "info" => @doc.css("#banner p:first-of-type").first.content.gsub(/(\n|results [0-9]+ \- )/,'').gsub(/\s+/,' ') }
  @doc.css("#results li").each do |n|
    r = {}
    details = ""
    det = n.css('.left_col').first.content.gsub(/\s+/,' ')
    det.split(/ /).each do |d|
      d.downcase!

      #eg. O'Brien
      if d.length > 2 and d[1] == '\''
        d[2] = d[2].capitalize
      end

      #eg. MacFarlane
      if d.length > 3 and d[0,3] == "mac"
        d[3] = d[3].capitalize
      end

      #eg. McGuire
      if d.length > 2 and d[0,2] == "mc"
        d[2] = d[2].capitalize
      end

      if d.length > 0
        d[0] = d[0].capitalize
      end

      details << "#{d} "
    end
    r['details'] = details
    r['date'] = n.css('.right_col .date').first.content.gsub(/\s+/,' ').gsub(/ ?\(.*\)/,'')
    r['location'] = n.css('.right_col div')[1].content.gsub(/\s+/,' ')
    r['area'] = n.css('.right_col div')[2].content.gsub(/\s+/,' ')
    results["queryresults"] << r
  end
  res = results.to_json
  settings.cache.set(url, res)
  res
end