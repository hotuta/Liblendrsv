class TokaiLend < ApplicationRecord
  # TODO: いつかDBにデータを入れるようにしたい
  # @date = TokaiLend.new

  # TODO: いつかCapybaraで書き直したい
  # include Capybara::DSL

  def initialize
    # Heroku用
    # caps = Selenium::WebDriver::Remote::Capabilities.chrome("chromeOptions" => {"binary" => "/app/.apt/usr/bin/google-chrome"})
    # @wd = Selenium::WebDriver.for :chrome, desired_capabilities: caps

    # デバッグ用
    @wd = Selenium::WebDriver.for :chrome

    @wd.manage.timeouts.implicit_wait = 30 # seconds
  end

  def list
    begin
      @wd.get "https://opac.time.u-tokai.ac.jp/webopac/login.do?url=ufisnd.do%3Fredirect_page_id%3D13"
      @wd.find_element(:name, "userid").click
      @wd.find_element(:name, "userid").clear
      @wd.find_element(:name, "userid").send_keys ENV['TOKAI_LIB_ID']
      @wd.find_element(:name, "password").click
      @wd.find_element(:name, "password").clear
      @wd.find_element(:name, "password").send_keys Base64.decode64(ENV['TOKAI_LIB_PW'])
      @wd.find_element(:css, "input.nolinkline").click

      # FIXME:ログイン後に様々なリダイレクトが生じるため暫定処置
      sleep 10

      @wd.get "https://library.time.u-tokai.ac.jp/?page_id=13&lang=japanese"
      @wd.get "https://library.time.u-tokai.ac.jp/index.php?action=v3search_view_main_libusesso&opacurl=https%3A%2F%2Fopac.time.u-tokai.ac.jp%2Fwebopac%2Flenlst.do"

      tokailend = Icalendar::Calendar.new
      tokailend.timezone do |t|
        t.tzid = "Asia/Tokyo"
        t.standard do |s|
          s.tzoffsetfrom = "+0900"
          s.tzoffsetto = "+0900"
          s.dtstart = "19700101T000000"
        end
      end
      tokailend.append_custom_property('X-WR-CALNAME', "東海大学貸出状況")
      tokailend.append_custom_property('X-WR-CALDESC', "東海大学貸出状況カレンダー")

      takanawa = 0
      yoyogi = 0
      lend = 0
      kb = 0
      nomal = 0

      # 貸出冊数有り無し判定
      if @wd.find_elements(:xpath, "/html/body/div/div/div/div[1]/form[1]/div/div[2]/div[1]/select[2]/option[5]").size > 0
        @wd.find_element(:xpath, "/html/body/div/div/div/div[1]/form[1]/div/div[2]/div[1]/select[2]/option[5]").click
      end

      (2..101).each do |bn|
        contact = @wd.find_elements(:xpath, "/html/body/div/div/div/div[1]/form[1]/div/div[3]/table/tbody/tr[#{bn}]/td[4]")

        if contact.size == 0
          break
        else
          lend += 1
        end

        html = @wd.page_source
        doc = Nokogiri::HTML(html)

        doc.xpath("/html/body/div/div/div/div[1]/form[1]/div/div[3]/table/tbody/tr[#{bn}]/td[4]").each do |anchor|
          @location = anchor.content.delete("　").gsub(/(\s)/, "")
        end

        doc.xpath("/html/body/div/div/div/div[1]/form[1]/div/div[3]/table/tbody/tr[#{bn}]/td[9]/a").each do |anchor|
          @title = anchor.content.delete(" ").gsub(/(\s)/, "")
        end

        @loc_title = "["+@location+"]"+@title
        doc.xpath("/html/body/div/div/div/div[1]/form[1]/div/div[3]/table/tbody/tr[#{bn}]/td[5]/b").each do |anchor|
          @date = anchor.content.delete("/").gsub(/(\s)/, "")
        end

        @wd.find_element(:xpath, "/html/body/div/div/div/div[1]/form[1]/div/div[3]/table/tbody/tr[#{bn}]/td[9]/a").click

        contact = @wd.find_elements(:xpath, "/html/body/div/div/div/div[1]/form[1]/div/div[2]/div[1]/table/tbody/tr[12]/td[contains(.,'KB')]")

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

        @wd.find_element(:xpath, "/html/body/div/div/div/div[1]/form[1]/div/div[1]/div/span[2]/a").click

        tokailend.event do |ev|
          ev.dtstart = Icalendar::Values::Date.new(@date)
          ev.dtend = Icalendar::Values::Date.new(@date)
          ev.summary = @loc_title.to_s
        end
      end

      open(Rails.root.join('public/tokailend.ics'), "wb") do |ical|
        ical.puts tokailend.to_ical
      end

      puts "高輪#{takanawa}冊 代々木#{yoyogi}冊"
      puts "ノーマル#{nomal}冊 KB#{kb}冊 "
      puts "東海貸出合計冊数は#{lend}冊"

      @wd.quit
    end
  rescue => e
    p e
  end
end
