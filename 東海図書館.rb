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
      @wd.get "https://www.time.u-tokai.ac.jp/webopac/asklst.do"
      @wd.find_element(:name, "userid").click
      @wd.find_element(:name, "userid").clear
      @wd.find_element(:name, "userid").send_keys LIBIDT
      @wd.find_element(:name, "password").click
      @wd.find_element(:name, "password").clear
      @wd.find_element(:name, "password").send_keys LIBPWT
      @wd.find_element(:css, "input.nolinkline").click
      @wd.find_element(:css, "a.lnk_ask").click
      @wd.find_element(:xpath, "//tr[@class='func_body']/td/form/table[3]/tbody/tr/td[3]/select//option[5]").click

      tokailend = Icalendar::Calendar.new
      tokailend.timezone do |t|
        t.tzid = "Asia/Tokyo"
        t.standard do |s|
          s.tzoffsetfrom = "+0900"
          s.tzoffsetto   = "+0900"
          s.dtstart      = "19700101T000000"
        end
      end

      tokailend.append_custom_property('X-WR-CALNAME', "東海大学貸出状況")
      tokailend.append_custom_property('X-WR-CALDESC', "東海大学貸出状況カレンダー")

      (2..101).each do |bn|
        contact = @wd.find_elements(:xpath, "//tr[@class='func_body']/td/form/table[4]/tbody/tr["+bn.to_s+"]/td[7]/span/a")
        if contact.size == 0
          break
        end

        html = @wd.page_source
        doc = Nokogiri::HTML(html)
        doc.xpath("//tr[@class='func_body']/td/form/table[4]/tbody/tr["+bn.to_s+"]/td[4]/span").each do |anchor|
          @location = anchor.content.delete("　").gsub(/(\s)/,"")
        end
        doc.xpath("//tr[@class='func_body']/td/form/table[4]/tbody/tr["+bn.to_s+"]/td[7]/span/a").each do |anchor|
          @title = anchor.content.delete(" ").gsub(/(\s)/,"")
        end
        @loc_title = "["+@location+"]"+@title
        doc.xpath("//table/tbody/tr[2]/td[2]/table/tbody/tr[2]/td/form/table[4]/tbody/tr["+bn.to_s+"]/td[5]/span/b").each do |anchor|
          @date = anchor.content.delete("/").gsub(/(\s)/,"")
        end
        tokailend.event do |e|
          e.dtstart     = Icalendar::Values::Date.new(@date)
          e.dtend       = Icalendar::Values::Date.new(@date)
          e.summary     = @loc_title.to_s
        end
        sibuyalend.publish
      end

      open('git/tokailend.ics', "w") do |ical|
        ical.puts tokailend.to_ical
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
