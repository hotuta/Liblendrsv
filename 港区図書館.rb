require 'selenium-webdriver'
require 'nokogiri'
require "date"
require 'time'
require 'icalendar'

LIBIDM = ""
LIBPW = ""

class Liblist
  def initialize()
    @wd = Selenium::WebDriver.for :chrome
  end
  def list()
    begin
      @wd.get "https://www.lib.city.minato.tokyo.jp/licsxp-opac/WOpacMnuTopToPwdLibraryAction.do?gamen=usrrsv"
      @wd.find_element(:id, "login").click
      @wd.find_element(:id, "usrcardnumber").click
      @wd.find_element(:id, "usrcardnumber").clear
      @wd.find_element(:id, "usrcardnumber").send_keys LIBIDM
      @wd.find_element(:id, "password").click
      @wd.find_element(:id, "password").clear
      @wd.find_element(:id, "password").send_keys LIBPW
      @wd.find_element(:xpath, "//div[@class='ex-navi']/input[1]").click
      sleep 1
      @wd.switch_to.alert.accept
      @wd.find_element(:id, "stat-lent").click
      sleep 1

      minatolend = Icalendar::Calendar.new
      minatolend.timezone do |t|
        t.tzid = "Asia/Tokyo"
        t.standard do |s|
          s.tzoffsetfrom = "+0900"
          s.tzoffsetto   = "+0900"
          s.dtstart      = "19700101T000000"
        end
      end
      minatolend.append_custom_property('X-WR-CALNAME', "港区立図書館貸出状況")
      minatolend.append_custom_property('X-WR-CALDESC', "港区立図書館貸出状況カレンダー")

      (1..10).each do |bn|
        contact = @wd.find_elements(:xpath, "//table[@class='list']/tbody/tr["+bn.to_s+"]/td[1]/a/strong")
        if contact.size == 0
          break
        end
        html = @wd.page_source
        doc = Nokogiri::HTML(html)
        doc.xpath("//table[@class='list']/tbody/tr["+bn.to_s+"]/td[1]/a/strong").each do |anchor|
          @title = anchor.content.delete("　")
        end
        contact = @wd.find_elements(:xpath, '//*[@id="body"]/form/div/div[1]/table/tbody/tr['+bn.to_s+']/td[8]/input')
        @Encho = ""
        if contact.size != 0
          @Encho = "[延長可]"
        end
        @title = @Encho+@title
        doc.xpath("//table[@class='list']/tbody/tr["+bn.to_s+"]/td[5]").each do |anchor|
          @date = anchor.content.delete("/").gsub(/(\s)/,"")
        end
        minatolend.event do |e|
          e.dtstart     = Icalendar::Values::Date.new(@date)
          e.dtend       = Icalendar::Values::Date.new(@date)
          e.summary     = @title.to_s
        end
        sibuyalend.publish
      end

      open('git/minatolend.ics', "w") do |ical|
        ical.puts minatolend.to_ical
      end

      @wd.find_element(:id, "myUsrRsv").click

      minatorsv = Icalendar::Calendar.new
      minatorsv.timezone do |t|
        t.tzid = "Asia/Tokyo"
        t.standard do |s|
          s.tzoffsetfrom = "+0900"
          s.tzoffsetto   = "+0900"
          s.dtstart      = "19700101T000000"
        end
      end
      minatorsv.append_custom_property('X-WR-CALNAME', "港区立図書館予約状況")
      minatorsv.append_custom_property('X-WR-CALDESC', "港区立図書館予約状況カレンダー")

      (1..10).each do |bn|
        contact = @wd.find_elements(:xpath, "//div/div/div[2]/form/div/table/tbody/tr["+bn.to_s+"]/td[1]/strong/a")
        if contact.size == 0
          break
        end

        contact2 = @wd.find_elements(:xpath, "//table[@class='list']/tbody/tr["+bn.to_s+"]/td[8]/div[contains(.,'/')]/span")
        if contact2.size != 0
          html = @wd.page_source
          doc = Nokogiri::HTML(html)
          doc.xpath("//div/div/div[2]/form/div/table/tbody/tr["+bn.to_s+"]/td[1]/strong/a").each do |anchor|
            @title = anchor.content.delete("　")
          end
          d = DateTime.now
          doc.xpath("//table[@class='list']/tbody/tr["+bn.to_s+"]/td[8]/div[contains(.,'/')]/span").each do |anchor|
            @date = d.year.to_s+anchor.content.delete("/").gsub(/(\s)/,"")
          end
          minatorsv.event do |e|
            e.dtstart     = Icalendar::Values::Date.new(@date)
            e.dtend       = Icalendar::Values::Date.new(@date)
            e.summary     = @title.to_s
          end
          sibuyalend.publish
        end
      end

      open('git/minatorsv.ics', "w") do |ical|
        ical.puts minatorsv.to_ical
      end

    end
  rescue => e
    p e
  ensure
    sleep 3
  end
end

l = Liblist.new
l.list
