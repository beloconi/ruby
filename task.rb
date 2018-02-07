require 'watir'
require 'pry-byebug'
require 'webdrivers'
require 'nokogiri'

class Privatbank

  attr_reader :accounts

  def initialize(phone, password)
    enter(phone, password)
    get_accounts
    get_transactions
    exit
  end


  def browser
    @browser ||= Watir::Browser.new
  end

  def enter(phone, password)
    browser.goto "https://www.privat24.ua/"
    browser.text_field(name: "login").set(phone)
    sleep 6
    browser.text_field(name: "password").set(password)
    browser.button(class: "button").click
    sleep 12
  end

  def get_accounts
    accounts_table = Nokogiri::HTML.fragment(browser.divs(class:"dashboard-item-body")[0].html)
    parse_accounts(accounts_table)
  end


  def parse_accounts(accounts_table)
    array = []
    accounts_table.css("div.statements-account-line").each do |a|
      new_hash = {
        name: a.css("div.number").text.gsub(" ", ""),
        balance: a.css("div.balance").children[0].text.gsub(" ", "").gsub(" ", ""),
        currency: a.css("div.balance").children[1].text,
        nature: "card",
        transactions: []
      }
      array << new_hash
    end
    @accounts = array
  end

  def get_transactions
    browser.a(title: "Мои счета").click
    sleep 7
    @accounts.each do |acc|
      browser.a(text: acc[:name]).click
      sleep 10
      browser.iframe(id: "frame").div(id: "stmt-calendar").i(class: "glyphicon glyphicon-calendar").click
      sleep 3
      browser.iframe(id: "frame").text_field(name: "daterangepicker_start").value = "01.12.2017"
      sleep 2
      browser.iframe(id: "frame").button(class: "applyBtn btn btn-sm btn-info").click
      sleep 7
      if browser.iframe(id: "frame").text.include?("К сожалению, нет данных за данный период!") || browser.iframe(id: "frame").text.include?("На жаль, немає даних за даний період")
        next
      end
      transactions_table = Nokogiri::HTML.fragment(browser.iframe(id: "frame").div(class: "panel-group").html)
      parse_transactions(acc, transactions_table)
    end
  end


  def parse_transactions(acc, transactions_table)
    @date = ""
    transactions_table.css("div.ng-isolate-scope.panel").each do |t|
      transactions = {}
      unless t.css("div.b_txt.ng-binding").empty?
        @date = t.css("div.b_txt.ng-binding").text
        next
      end
      transactions[:date] = @date
      transactions[:amount] = t.css("div.t_amt")[0].text.split.first
      transactions[:currency_code] = t.css("div.t_amt")[0].text.split.last
      transactions[:description] = t.css(".t_descr").text

      acc[:transactions] << transactions
    end
  end


  def exit
    browser.div(title: "Выход").click
  end
end

Privatbank.new("+380********", "*******")

