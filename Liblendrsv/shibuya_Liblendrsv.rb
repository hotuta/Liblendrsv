require 'selenium-webdriver'
require 'nokogiri'
require 'pit'
require 'time'
require 'icalendar'

class Shibuya
  def initialize()
    @wd = Selenium::WebDriver.for :chrome
  end
  def list()
    begin
      #渋谷区立図書館
      config = Pit.get('shibuyalib')

      @wd.get "https://www.lib.city.shibuya.tokyo.jp/asp/WwJouNinshou.aspx"
      @wd.find_element(:id, "txtRiyoshaCD").send_keys config['id']
      @wd.find_element(:id, "txtPassword").click
      @wd.find_element(:id, "txtPassword").clear
      @wd.find_element(:id, "txtPassword").send_keys Base64.decode64(config['password'])
      @wd.find_element(:id, "btnKakunin").click

      sibuyalend = Icalendar::Calendar.new
      sibuyalend.timezone do |t|
        t.tzid = "Asia/Tokyo"
        t.standard do |s|
          s.tzoffsetfrom = "+0900"
          s.tzoffsetto   = "+0900"
          s.dtstart      = "19700101T000000"
        end
      end
      sibuyalend.append_custom_property('X-WR-CALNAME', "渋谷図書館貸出状況")
      sibuyalend.append_custom_property('X-WR-CALDESC', "渋谷図書館貸出状況カレンダー")

      sibuya = 0
      tyuuou = 0
      tomigaya = 0
      lend = 0

      (2..31).each do |bn|
        contact = @wd.find_elements(:xpath, '//*[@id="dgdKas"]/tbody/tr['+bn.to_s+']/td[2]/a')
        if contact.size == 0
          break
        else
          lend += 1
        end
        html = @wd.page_source
        doc = Nokogiri::HTML(html)
        doc.xpath('//*[@id="dgdKas"]/tbody/tr['+bn.to_s+']/td[2]/a').each do |anchor|
          @title = anchor.content.delete(" ")
        end
        doc.xpath('//*[@id="dgdKas"]/tbody/tr['+bn.to_s+"]/td[6]").each do |anchor|
          @location = anchor.content.delete("　").gsub(/(\s)/,"")
        end
        if @location == "渋谷図書館"
          sibuya += 1
          @location += sibuya.to_s
        elsif @location == "中央図書館"
          tyuuou += 1
          @location += tyuuou.to_s
        elsif @location == "富ヶ谷図書館"
          tomigaya += 1
          @location += tomigaya.to_s
        end
        @title = "<"+@location+">"+@title
        @wd.find_element(:xpath, '//*[@id="dgdKas"]/tbody/tr['+bn.to_s+']/td[2]/a').click
        contact = @wd.find_elements(:xpath, '//*[@id="btnEncho"]')
        @Encho = ""
        if contact.size != 0
          @Encho = "[延長可]"
        end

        html = @wd.page_source
        doc = Nokogiri::HTML(html)
        doc.xpath('//*[@id="lblHenDate"]').each do |anchor|
          @date = anchor.content.delete("/")
        end
        doc.xpath('//table//tr//td[contains( ./text(), "4-")]').each do |anchor|
          @num = anchor.content.delete("-")
        end
        @wd.find_element(:id, "lnkJokyo").click
        sibuyalend.event do |ev|
          ev.dtstart     = Icalendar::Values::Date.new(@date)
          ev.dtend       = Icalendar::Values::Date.new(@date)
          ev.summary     = @Encho.to_s+@title.to_s
        end
      end

      puts "渋谷貸出合計冊数は"+lend.to_s+"冊"
      puts "渋谷図書館"+sibuya.to_s+"冊 "+"中央図書館"+tyuuou.to_s+"冊 "+"富ヶ谷図書館"+tomigaya.to_s+"冊 "

      open('./Liblendrsv/git/sibuyalend.ics', "wb") do |ical|
        ical.puts sibuyalend.to_ical
      end

      sibuyarsv = Icalendar::Calendar.new
      sibuyarsv.timezone do |t|
        t.tzid = "Asia/Tokyo"
        t.standard do |s|
          s.tzoffsetfrom = "+0900"
          s.tzoffsetto   = "+0900"
          s.dtstart      = "19700101T000000"
        end
      end
      sibuyarsv.append_custom_property('X-WR-CALNAME', "渋谷図書館予約状況")
      sibuyarsv.append_custom_property('X-WR-CALDESC', "渋谷図書館予約状況カレンダー")

      sibuya = 0
      tyuuou = 0
      tomigaya = 0
      sibuya2 = 0
      tyuuou2 = 0
      tomigaya2 = 0

      rsv = 0
      hold = 0

      (2..21).each do |bn|
        contact = @wd.find_elements(:xpath, '//*[@id="dgdYoy"]/tbody/tr['+bn.to_s+']/td[2]/a')
        if contact.size == 0
          break
        else
          rsv += 1
        end
        html = @wd.page_source
        doc = Nokogiri::HTML(html)
        doc.xpath("//*[@id='dgdYoy']/tbody/tr["+bn.to_s+"]/td[7]").each do |anchor|
          @location = anchor.content.delete("　").gsub(/(\s)/,"")
        end
        if @location == "富ヶ谷図書館"
          tomigaya2 += 1
        elsif @location == "渋谷図書館"
          sibuya2 += 1
        elsif @location == "中央図書館"
          tyuuou2 += 1
        end

        contact2 = @wd.find_elements(:xpath, "//*[@id='dgdYoy']/tbody/tr["+bn.to_s+"]/td[contains(.,'/')][2]")
        if contact2.size != 0
          hold += 1
          doc.xpath('//*[@id="dgdYoy"]/tbody/tr['+bn.to_s+']/td[2]/a').each do |anchor|
            @title = anchor.content.delete(" ")
          end
          @loc_title = "["+@location+"]"+@title

          if @location == "富ヶ谷図書館"
            tomigaya += 1
          elsif @location == "渋谷図書館"
            sibuya += 1
          elsif @location == "中央図書館"
            tyuuou += 1
          end

          doc.xpath("//*[@id='dgdYoy']/tbody/tr["+bn.to_s+"]/td[contains(.,'/')][2]").each do |anchor|
            @date = anchor.content.delete("/")
          end
          sibuyarsv.event do |ev|
            ev.dtstart     = Icalendar::Values::Date.new(@date)
            ev.dtend       = Icalendar::Values::Date.new(@date)
            ev.summary     = @loc_title.to_s
          end
        end
      end

      open("./Liblendrsv/git/sibuyarsv.ics", "wb") do |ical|
        ical.puts sibuyarsv.to_ical
      end

      puts "渋谷予約 取り置き"+hold.to_s+"冊/"+"合計冊数"+rsv.to_s+"冊"
      puts "合計内訳⇛渋谷図書館"+sibuya2.to_s+"冊 "+"中央図書館"+tyuuou2.to_s+"冊 "+"富ヶ谷図書館"+tomigaya2.to_s+"冊 "
      puts "取り置き⇛渋谷図書館"+sibuya.to_s+"冊 "+"中央図書館"+tyuuou.to_s+"冊 "+"富ヶ谷図書館"+tomigaya.to_s+"冊 "

      @wd.quit

    end
  rescue => e
    p e
  ensure
    sleep 3
  end
end
