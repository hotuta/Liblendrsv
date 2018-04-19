class TokaiLend < ApplicationRecord
  def self.icalendar(books)
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

    books.each do |book|
      tokailend.event do |ev|
        ev.dtstart     = Icalendar::Values::Date.new(book.date)
        ev.dtend       = Icalendar::Values::Date.new(book.date)
        ev.summary     = book.title
      end
    end

    tokailend.to_ical
  end


  def self.get_lend_list
    session = Capybara::Session.new(:chrome)
    session.visit 'https://opac.time.u-tokai.ac.jp/webopac/login.do?url=ufisnd.do%3Fredirect_page_id%3D13'
    session.fill_in 'userid', with: Base64.strict_decode64(ENV['TOKAI_LIB_ID'])
    session.fill_in 'password', with: Base64.strict_decode64(ENV['TOKAI_LIB_PW'])
    session.execute_script('submitFlag=true;opacSubmit();')

    Timeout.timeout(30) do
      loop until session.has_css?('.container')
    end

    session.visit 'https://library.time.u-tokai.ac.jp/?page_id=13&lang=japanese'
    session.visit 'https://library.time.u-tokai.ac.jp/index.php?action=v3search_view_main_libusesso&opacurl=https%3A%2F%2Fopac.time.u-tokai.ac.jp%2Fwebopac%2Flenlst.do'
    session.select '100', from: 'listcnt' if session.has_xpath?('//select[@name="listcnt"]')

    if session.has_xpath?("//table[@class='opac_data_list_ex']//tr/td[4]")
      session.all('//table[@class="opac_data_list_ex"]//tr/td[9]/a')[0].click
      tokai_lends = []
      for bn in 0..99 do
        tokai_lend = TokaiLend.new
        tokai_lend.location = session.find('//th[contains(., "貸出館")]/following-sibling::td').text.gsub(/(\s)/, '')
        tokai_lend.date = Time.parse(session.find('//th[contains(., "返却期限日")]/following-sibling::td').text)
        tokai_lend.title = session.find('//th[contains(., "書誌事項")]/following-sibling::td').text
        book_id = session.find('//th[contains(., "資料ID")]/following-sibling::td').text
        session.find('//table[@class="opac_confirm_list"]//tr/td/a').click

        session.driver.browser.switch_to.window(session.driver.browser.window_handles.last)
        Timeout.timeout(30) do
          loop until session.has_css?('.container')
        end
        vol = session.find("(//td[contains(., '#{book_id}')]/preceding-sibling::td)[2]", visible: false).text
        if session.all('//*[@class="opac_syosi_list"]//th[contains(., "ISBN")]/following-sibling::td', visible: false).count >= 2
        tokai_lend.isbn = session.find("//*[@class='opac_syosi_list']//table//tr[contains(., '#{vol}')]/following-sibling::tr/td", visible: false).text
        else
          tokai_lend.isbn = session.find('//*[@class="opac_syosi_list"]//th[contains(., "ISBN")]/following-sibling::td', visible: false).text
        end
        tokai_lends << tokai_lend

        session.driver.browser.close
        session.driver.browser.switch_to.window(session.driver.browser.window_handles.last)
        if session.has_xpath?('//div[@class="page_next"]/a')
          session.find('//div[@class="page_next"]/a').click
        else
          session.driver.quit
          break
        end
      end
      TokaiLend.import tokai_lends, recursive: true, on_duplicate_key_update: {conflict_target: [:isbn], columns: [:date]}
    end
  end
end
