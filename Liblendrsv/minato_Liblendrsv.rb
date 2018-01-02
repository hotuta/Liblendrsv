require 'selenium-webdriver'
require 'nokogiri'
require 'pit'
require 'time'
require 'icalendar'

class Minato
  def initialize()
    @wd = Selenium::WebDriver.for :chrome
  end
  def list()
    begin
      #港区立図書館
      config = Pit.get('minatolib')

      @wd.get "https://www.lib.city.minato.tokyo.jp/licsxp-opac/WOpacMnuTopToPwdLibraryAction.do?gamen=usrrsv"
      @wd.find_element(:id, "login").click
      @wd.find_element(:id, "usrcardnumber").click
      @wd.find_element(:id, "usrcardnumber").clear
      @wd.find_element(:id, "usrcardnumber").send_keys config['id']
      @wd.find_element(:id, "password").click
      @wd.find_element(:id, "password").clear
      @wd.find_element(:id, "password").send_keys Base64.decode64(config['password'])
      @wd.find_element(:xpath, "//div[@class='ex-navi']/input[1]").click
      
      begin
        sleep 3
        @wd.switch_to.alert.accept
      rescue Selenium::WebDriver::Error::NoSuchAlertError => e
      end

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

      lend = 0

      (1..10).each do |bn|
        contact = @wd.find_elements(:xpath, "//table[@class='list']/tbody/tr["+bn.to_s+"]/td[1]/a/strong")
        if contact.size == 0
          break
        else
          lend += 1
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
        minatolend.event do |ev|
          ev.dtstart     = Icalendar::Values::Date.new(@date)
          ev.dtend       = Icalendar::Values::Date.new(@date)
          ev.summary     = @title.to_s
        end
      end

      open("./Liblendrsv/git/minatolend.ics", "wb") do |ical|
        ical.puts minatolend.to_ical
      end

      puts "港区貸出合計冊数は"+lend.to_s+"冊"

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

      rsv = 0
      hold = 0

      (1..10).each do |bn|
        contact = @wd.find_elements(:xpath, "//div/div/div[2]/form/div/table/tbody/tr["+bn.to_s+"]/td[1]/strong/a")
        if contact.size == 0
          break
        else
          rsv += 1
        end
        contact2 = @wd.find_elements(:xpath, "//table[@class='list']/tbody/tr["+bn.to_s+"]/td[8]/div[contains(.,'/')]/span")
        if contact2.size != 0
          hold += 1
          html = @wd.page_source
          doc = Nokogiri::HTML(html)
          doc.xpath("//div/div/div[2]/form/div/table/tbody/tr["+bn.to_s+"]/td[1]/strong/a").each do |anchor|
            @title = anchor.content.delete("　")
          end
          d = DateTime.now
          doc.xpath("//table[@class='list']/tbody/tr["+bn.to_s+"]/td[8]/div[contains(.,'/')]/span").each do |anchor|
            @date = d.year.to_s+anchor.content.delete("/").gsub(/(\s)/,"")
          end
          minatorsv.event do |ev|
            ev.dtstart     = Icalendar::Values::Date.new(@date)
            ev.dtend       = Icalendar::Values::Date.new(@date)
            ev.summary     = @title.to_s
          end
        end
      end

      open('./Liblendrsv/git/minatorsv.ics', "wb") do |ical|
        ical.puts minatorsv.to_ical
      end

      puts "港区予約 取り置き"+hold.to_s+"冊/"+"合計冊数"+rsv.to_s+"冊"

      @wd.quit

    end
  rescue => e
    p e
  ensure
    sleep 3
  end
end
