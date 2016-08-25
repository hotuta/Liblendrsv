# Liblendrsv to Google Calender

[![The GPN License](https://img.shields.io/badge/license-GPN-blue.svg)](LICENSE)

Liblendrsv(リブレ)とは、図書館の借りた本の返却期限、予約した本の取置期限をGoogleカレンダーで管理するスクリプトです。  
Issues、Pull Requests大歓迎です。

## 動作環境

RubyとSeleniumとChromeが動く環境が必要です。

GithubのアカウントとGoogleカレンダーの準備をしてください。

任意のリポジトリを作成してください。

Privateリポジトリであるとスクリプト実行毎にRawアドレスが変わってしまいうまく動作しません。

## 使い方(初回)

Rubyを入れる(Windowsの方のみ)  

```gem install 'selenium-webdriver'```  

ChromeDriverを入れる  

Mac
brew install ChromeDriver

Windows
https://sites.google.com/a/chromium.org/chromedriver/downloads

```gem install 'nokogiri'```  

```gem install 'pit'```  

```gem install 'icalendar'```


1. Liblendrsv.rbを実行する。
   →必要とするところ以外コメントアウトしてください

2. gitディレクトリからGithubの任意のリポジトリへプッシュできるようにする

3. プッシュ後、gitディレクトリの各icsファイルを右上のRawで開く

4. RawのアドレスをGoogleカレンダーの他のカレンダーに追加する

## 使い方(2回目以降)

スクリプトを実行の上、コミット、プッシュなどを行えば遅くとも数時間後にカレンダーに反映されるようになります。

## ライセンス

GPN
