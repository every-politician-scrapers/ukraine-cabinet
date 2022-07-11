#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/scraper_data'
require 'pry'

require 'open-uri/cached'

class OfficeholderList < OfficeholderListBase
  decorator RemoveReferences
  decorator UnspanAllTables
  decorator WikidataIdsDecorator::Links

  def holder_entries
    noko.xpath('//table[.//td[contains(.,"Портрет")]][last()]//tr[td]')
  end

  class Officeholder < OfficeholderBase
    def columns
      %w[ordinal dates image name].freeze
    end

    def empty?
      tds.first.text.include?('№') || (itemLabel == '—') || too_early?
    end

    def raw_combo_date
      super.gsub(/^з/, '')
    end
  end
end

url = ARGV.first
puts EveryPoliticianScraper::ScraperData.new(url, klass: OfficeholderList).csv
