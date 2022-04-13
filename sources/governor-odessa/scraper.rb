#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/scraper_data'
require 'pry'

class OfficeholderNonTable < OfficeholderListBase::OfficeholderBase
  def empty?
    false
  end

  def combo_date?
    true
  end

  def raw_combo_date
    raise 'need to define a raw_combo_date'
  end

  def name_node
    raise 'need to define a name_node'
  end
end

class OfficeholderList < OfficeholderListBase
  decorator RemoveReferences
  decorator UnspanAllTables
  decorator WikidataIdsDecorator::Links

  def holder_entries
    noko.xpath("//h3[.//span[contains(.,'Голови')]][last()]//following::ol[1]//li[a]")
  end

  class Officeholder < OfficeholderNonTable
    def name_node
      noko.css('a')
    end

    # TODO: cope with this sort of date formatting
    def raw_combo_date
      noko.text.tidy
          .gsub('березень — липень 1992', 'березень 1992 — липень 1992')
          .gsub('травень — серпень 2006', 'травень 2006 — серпень 2006')
          .gsub('березень — травень 2014', 'березень 2014 — травень 2014')
          .gsub(/— з (.*)/, '— \1 — Incumbent').split('—').reverse.take(2).reverse.join(' - ')
    end
  end
end

url = ARGV.first
puts EveryPoliticianScraper::ScraperData.new(url, klass: OfficeholderList).csv
