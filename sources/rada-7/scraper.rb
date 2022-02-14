#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/scraper_data'
require 'pry'

class OfficeholderList < OfficeholderListBase
  decorator RemoveReferences
  decorator UnspanAllTables
  decorator WikidataIdsDecorator::Links

  def header_column
    'Область'
  end

  class Officeholder < OfficeholderBase
    def columns
      %w[name party region district no start end].freeze
    end

    def startDate
      start_cell.css('span').text.tidy
    end

    def endDate
      end_cell.css('span').text.tidy
    end
  end
end

url = ARGV.first
puts EveryPoliticianScraper::ScraperData.new(url, klass: OfficeholderList).csv
