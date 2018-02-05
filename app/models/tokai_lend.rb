class TokaiLend < ApplicationRecord
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
      for bn in 0..99 do
        tokai_lend = TokaiLend.new
        tokai_lend.location = session.find('//th[contains(., "貸出館")]/following-sibling::td').text.gsub(/(\s)/, '')
        tokai_lend.date = Time.parse(session.find('//th[contains(., "返却期限日")]/following-sibling::td').text)
        tokai_lend.title = session.find('//th[contains(., "書誌事項")]/following-sibling::td').text
        session.find('//table[@class="opac_confirm_list"]//tr/td/a').click

        session.driver.browser.switch_to.window(session.driver.browser.window_handles.last)
        Timeout.timeout(30) do
          loop until session.has_css?('.container')
        end
        tokai_lend.isbn = session.find('//*[@class="opac_syosi_list"]//th[contains(., "ISBN")]/following-sibling::td', visible: false).text
        TokaiLend.find_or_initialize_by(isbn: tokai_lend.isbn) do |book|
          book = tokai_lend
          book.save
        end

        session.driver.browser.close
        session.driver.browser.switch_to.window(session.driver.browser.window_handles.last)
        if session.has_xpath?('//div[@class="page_next"]/a')
          session.find('//div[@class="page_next"]/a').click
        else
          session.driver.quit
          break
        end
      end
    end
  end
end
