require 'selenium-webdriver'
require 'nokogiri'
require 'pit'
require 'time'
require 'icalendar'

class Kawasaki
  def initialize()
    @wd = Selenium::WebDriver.for :chrome
  end
  def list()
    begin
      # 川崎市立図書館
      config = Pit.get('kawasakilib')

      @wd.get "https://www.library.city.kawasaki.jp/idcheck.html"
      @wd.find_element(:name, "UID").send_keys config['id']
      @wd.find_element(:name, "PASS").click
      @wd.find_element(:name, "PASS").clear
      @wd.find_element(:name, "PASS").send_keys Base64.decode64(config['password'])
      @wd.find_element(:css, "input[type=\"submit\"]").click
      @wd.find_element(:link_text, "貸出状況照会へ").click

      kawasakilend = Icalendar::Calendar.new
      kawasakilend.timezone do |t|
        t.tzid = "Asia/Tokyo"
        t.standard do |s|
          s.tzoffsetfrom = "+0900"
          s.tzoffsetto   = "+0900"
          s.dtstart      = "19700101T000000"
        end
      end
      kawasakilend.append_custom_property('X-WR-CALNAME', "川崎貸出状況")
      kawasakilend.append_custom_property('X-WR-CALDESC', "川崎貸出状況カレンダー")
      lend = 0

      (1..10).each do |bn|
        contact = @wd.find_elements(:xpath, "/html/body/div[1]/table/tbody/tr["+bn.to_s+"]/td[2]/a")
        if contact.size == 0
          lend += 1
          break
        else
          lend += 1
        end
        html = @wd.page_source
        doc = Nokogiri::HTML(html)
        doc.xpath("/html/body/div[1]/table/tbody/tr["+bn.to_s+"]/td[2]/a").each do |anchor|
          @title = anchor.content.delete(" ").gsub(/(\s)/,"")
        end
        @wd.find_element(:xpath, "/html/body/div[1]/table/tbody/tr["+bn.to_s+"]/td[2]/a").click
        contact = @wd.find_elements(:xpath, '/html/body/div[3]/form/input[1]')
        @Encho = ""
        if contact.size != 0
          @Encho = "[延長可]"
        end
        @title = @Encho+@title

        @wd.find_element(:link_text, "貸出照会").click

        doc.xpath("//div[1]/table/tbody/tr["+bn.to_s+"]/td[5]").each do |anchor|
          @date = anchor.content.delete(" ").gsub(/(\s)/,"")
        end
        @date = Time.strptime(@date, "%Y年%m月%d日")
        kawasakilend.event do |ev|
          ev.dtstart     = Icalendar::Values::Date.new(@date)
          ev.dtend       = Icalendar::Values::Date.new(@date)
          ev.summary     = @title.to_s
        end
      end

      open('./Liblendrsv/git/kawasakilend.ics', "wb") do |ical|
        ical.puts kawasakilend.to_ical
      end

      lend -= 1
      puts "川崎貸出合計冊数は"+lend.to_s+"冊"

      @wd.find_element(:link_text, "メニュー").click
      @wd.find_element(:link_text, "予約状況照会へ").click

      kawasakirsv = Icalendar::Calendar.new
      kawasakirsv.timezone do |t|
        t.tzid = "Asia/Tokyo"
        t.standard do |s|
          s.tzoffsetfrom = "+0900"
          s.tzoffsetto   = "+0900"
          s.dtstart      = "19700101T000000"
        end
      end
      kawasakirsv.append_custom_property('X-WR-CALNAME', "川崎予約状況")
      kawasakirsv.append_custom_property('X-WR-CALDESC', "川崎予約状況カレンダー")
      rsv = 0

      (1..10).each do |bn|

        contact = @wd.find_elements(:xpath, "/html/body/div[1]/table/tbody/tr["+bn.to_s+"]/td[5][contains(.,'年')]")
        if contact.size == 0
          rsv += 1
          break
        else
          rsv += 1
        end
        html = @wd.page_source
        doc = Nokogiri::HTML(html)
        doc.xpath("//div[1]/table/tbody/tr["+bn.to_s+"]/td[3]/a").each do |anchor|
          @title = anchor.content.delete(" ").gsub(/(\s)/,"")
        end
        doc.xpath("/html/body/div[1]/table/tbody/tr["+bn.to_s+"]/td[5]").each do |anchor|
          @date = anchor.content.delete(" ").gsub(/(\s)/,"")
        end
        @date = Time.strptime(@date, "%Y年%m月%d日")
        kawasakirsv.event do |ev|
          ev.dtstart     = Icalendar::Values::Date.new(@date)
          ev.dtend       = Icalendar::Values::Date.new(@date)
          ev.summary     = @title #.to_s
        end
      end

      open("./Liblendrsv/git/kawasakirsv.ics", "wb") do |ical|
        ical.puts kawasakirsv.to_ical
      end

      rsv -= 1
      puts "川崎予約合計冊数は"+rsv.to_s+"冊"

      @wd.quit

    end
  rescue => e
    p e
  ensure
    sleep 3
  end
end
