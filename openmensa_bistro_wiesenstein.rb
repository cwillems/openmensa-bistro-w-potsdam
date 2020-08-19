require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'active_support/time'

get '/' do
  menu = Nokogiri::HTML(open('https://www.bistro-wiesenstein.de/'))

  date_matches = menu.at('.zh_slider_karte_title')
                     .text
                     .match(/\D*(\d+)\.\s?-\s?\d+\.(\d+)\./)#

  start_date = Date.new(Date.today.year, date_matches[2].to_i, date_matches[1].to_i)

  daily_dishes = nil
  weekday = 0
  all_dishes = menu.search('.zh_gericht').each_with_object([]) do |dish, dishes|
    if(dish.at('.zh_gericht_title'))
      unless daily_dishes.nil?
        dishes << {date: (start_date + weekday.days).to_s, dishes: daily_dishes}
        weekday = weekday + 1
      end
      daily_dishes = []
    end

    daily_dishes << {name: dish.at('.zh_gericht_text').text, price: dish.at('.zh_gericht_preis').text}
  end
  all_dishes << daily_dishes

  soups = all_dishes.pop

  content_type 'text/xml'
  render_openmensa(all_dishes, soups).to_xml
end

private

def render_openmensa(all_dishes, soups)
  Nokogiri::XML::Builder.new do |xml|
    xml.openmensa(
      version: '2.1',
      xmlns: 'http://openmensa.org/open-mensa-v2',    
      'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
      'xsi:schemaLocation': 'http://openmensa.org/open-mensa-v2 http://openmensa.org/open-mensa-v2.xsd',
    ) do
      xml.version('0.1')

      xml.canteen do
        all_dishes.each do |daily_dishes|
          xml.day(date: daily_dishes[:date]) do
            xml.category(name: 'Hauptgericht') do
              daily_dishes[:dishes].each do |dish|
                xml.meal do
                  xml.name(dish[:name])
                  xml.price(role: 'other') { xml.text price(dish[:price]) }
                end
              end
            end

            xml.category(name: 'Suppe') do
              soups.each do |dish|
                xml.meal do
                  xml.name(dish[:name])
                  xml.price(role: 'other') { xml.text price(dish[:price]) }
                end
              end
            end
          end
        end
      end
    end
  end
end


def price(p)
  p.gsub(',', '.').to_f
end
