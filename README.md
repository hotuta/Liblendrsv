# Liblendrsv to Google Calender

[![The GPN License](https://img.shields.io/badge/license-GPN-blue.svg)](LICENSE)

Liblendrsv(リブレ)とは、図書館の借りた本の返却期限、予約した本の取置期限をGoogleカレンダーで管理するスクリプトです。  
Issues、Pull Requestsは大歓迎です。

## 動作環境

RubyとSeleniumが動く環境

## 使い方(初回)

Rubyを入れる(Windowsの方のみ)  

```gem install 'selenium-webdriver'```  

ChromeDriverを入れる  

```gem install 'nokogiri'```  

```gem install 'pit'```  

```gem install 'icalendar'```


Liblendrsv.rbを実行

gitディレクトリからGithubにプッシュできるようにし、プッシュ

プッシュ後、icalファイルを右上のRawで開き、RawのアドレスをGoogleカレンダーの他のカレンダーに追加

## 使い方(2回目以降)

スクリプトを実行の上、コミット、プッシュなどを行えば遅くても数時間後にカレンダーに反映されるようになります。

## ライセンス

GPN
