#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/scraper_data'
require 'pry'

require 'open-uri/cached'

class OfficeholderList < OfficeholderListBase
  decorator RemoveReferences
  decorator UnspanAllTables
  decorator WikidataIdsDecorator::Links

  def header_column
    'Голова'
  end

  class Officeholder < OfficeholderBase
    def columns
      %w[ordinal name photo dates presidency notes].freeze
    end

    def item
      tds[1].css('a/@wikidata').map(&:text).last
    end

    def itemLabel
      tds[1].css('a').map(&:text).last
    end

    def raw_start
      date_parts.values_at(0, 1).join(' ').tidy
    end

    def raw_end
      date_parts.values_at(2, 3).join(' ').tidy
    end

    def date_parts
      tds[3].css('a').take(4)
    end
  end
end

url = ARGV.first
puts EveryPoliticianScraper::ScraperData.new(url, klass: OfficeholderList).csv
