#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/scraper_data'
require 'pry'

class OfficeholderList < OfficeholderListBase
  decorator RemoveReferences
  decorator UnspanAllTables
  decorator WikidataIdsDecorator::Links

  def header_column
    'Голови'
  end

  # TODO: make this easier to override
  def holder_entries
    noko.xpath("//h3[.//span[contains(.,'#{header_column}')]][1]//following-sibling::ol[1]//li[a]")
  end

  class Officeholder < OfficeholderBase
    def raw_combo_dates
      clean_dates.split(';').map(&:tidy).reject(&:empty?).last.split('—').map(&:tidy)
    end

    def clean_dates
      noko.text.split('—', 2).last.gsub(' по ', '—').gsub(' з ', '').gsub(' року', '').gsub(/\(.*?\)/, '')
    end

    def combo_date?
      true
    end

    def name_cell
      noko
    end

    def empty?
      noko.text.include?('представник') || too_early?
    end
  end
end

url = ARGV.first
puts EveryPoliticianScraper::ScraperData.new(url, klass: OfficeholderList).csv
