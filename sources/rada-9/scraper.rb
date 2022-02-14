#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/scraper_data'
require 'pry'

class DottedDMY < WikipediaDate
  def to_s
    date_en.to_s.split('.').reverse.join('-')
  end
end

class OfficeholderList < OfficeholderListBase
  decorator RemoveReferences
  decorator UnspanAllTables
  decorator WikidataIdsDecorator::Links

  field :members do
    current_members + ex_members
  end

  def current_members
    holder_entries.map { |ul| fragment(ul => Officeholder) }.reject(&:empty?).map(&:to_h).uniq
  end

  def ex_members
    ex_holder_entries.map { |ul| fragment(ul => ExOfficeholder) }.reject(&:empty?).map(&:to_h).uniq
  end

  def holder_entries
    noko.xpath("//table[.//th[contains(.,'Фракція')]][last()]//tr[td]")
  end

  def ex_holder_entries
    noko.xpath("//table[.//th[contains(.,'вибуття')]][last()]//tr[td]")
  end

  class OfficeholderRow < OfficeholderBase
    def raw_end
     super.gsub('†', '').tidy
    end

    def date_class
      DottedDMY
    end
  end

  class Officeholder < OfficeholderRow
    def columns
      %w[party name _ district faction start].freeze
    end

    def startDate
      super.to_s.empty? ? '2019-08-29' : super
    end

    def endDate
      nil
    end
  end

  class ExOfficeholder < OfficeholderRow
    def columns
      %w[party name _ district end].freeze
    end

    def startDate
      '2019-08-29'
    end
  end
end

url = ARGV.first
puts EveryPoliticianScraper::ScraperData.new(url, klass: OfficeholderList).csv
