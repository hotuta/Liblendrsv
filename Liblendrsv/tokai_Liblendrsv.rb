require 'selenium-webdriver'
require 'nokogiri'
require 'pit'
require 'time'
require 'icalendar'

class Tokai
  def initialize()
    @wd = Selenium::WebDriver.for :chrome
  end
  def list()
    begin
      #東海大学図書館
      config = Pit.get('tokailib')

      @wd.get "https://www.time.u-tokai.ac.jp/webopac/asklst.do"
      @wd.find_element(:name, "userid").click
      @wd.find_element(:name, "userid").clear
      @wd.find_element(:name, "userid").send_keys config['id']
      @wd.find_element(:name, "password").click
      @wd.find_element(:name, "password").clear
      @wd.find_element(:name, "password").send_keys Base64.decode64(config['password'])
      @wd.find_element(:css, "input.nolinkline").click
      @wd.find_element(:css, "a.lnk_ask").click

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

      takanawa = 0
      yoyogi = 0
      lend = 0
      kb = 0
      nomal = 0

      (2..101).each do |bn|
        @wd.find_element(:xpath, "//tr[@class='func_body']/td/form/table[3]/tbody/tr/td[3]/select//option[5]").click
        contact = @wd.find_elements(:xpath, "//tr[@class='func_body']/td/form/table[4]/tbody/tr["+bn.to_s+"]/td[7]/span/a")
        if contact.size == 0
          break
        else
          lend += 1
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
        @wd.find_element(:xpath, "//tr[@class='func_body']/td/form/table[4]/tbody/tr["+bn.to_s+"]/td[7]/span/a").click
        contact = @wd.find_elements(:xpath, "/html/body/table/tbody/tr[2]/td[2]/table/tbody/tr[2]/td/form[1]/table[4]/tbody/tr[11]/td/span[contains(.,'KB')]")
        @loc = @location
        if contact.size != 0 && @loc == "高輪"
          kb += 1
        elsif contact.size == 0 && @loc == "高輪"
          nomal += 1
        end
        if @location == "高輪"
          takanawa += 1
          @location += takanawa.to_s
        elsif @location == "代々木"
          yoyogi += 1
          @location += yoyogi.to_s
        end
        html = @wd.page_source
        doc = Nokogiri::HTML(html)
        doc.xpath("/html/body/table/tbody/tr[2]/td[2]/table/tbody/tr[2]/td/form[1]/table[4]/tbody/tr[11]/td/span/text()").each do |anchor|
        end
        @wd.find_element(:xpath, "/html/body/table/tbody/tr[2]/td[2]/table/tbody/tr[2]/td/form[1]/table[6]/tbody/tr/td/a/img").click

        tokailend.event do |ev|
          ev.dtstart     = Icalendar::Values::Date.new(@date)
          ev.dtend       = Icalendar::Values::Date.new(@date)
          ev.summary     = @loc_title.to_s
        end
      end

      open("./Liblendrsv/git/tokailend.ics", "wb") do |ical|
        ical.puts tokailend.to_ical
      end

      puts "高輪"+takanawa.to_s+"冊 "+"代々木"+yoyogi.to_s+"冊 "
      puts "ノーマル"+nomal.to_s+"冊 "+"KB"+kb.to_s+"冊 "
      puts "東海貸出合計冊数は"+lend.to_s+"冊"

      @wd.quit

    end
  rescue => e
    p e
  ensure
    sleep 3
  end
end
