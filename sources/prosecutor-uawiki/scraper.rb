#!/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'pry'
require 'scraped'
require 'table_unspanner'
require 'wikidata_ids_decorator'

require 'open-uri/cached'

class WikiDate
  REMAP = {
    'по т.ч.'   => '',
    'січня'     => 'January',
    'лютого'    => 'February',
    'березня'   => 'March',
    'квітня'    => 'April',
    'травня'    => 'May',
    'червня'    => 'June',
    'липня'     => 'July',
    'серпня'    => 'August',
    'вересня'   => 'September',
    'жовтня'    => 'October',
    'листопада' => 'November',
    'грудня'    => 'December',
  }.freeze

  def initialize(date_str)
    @date_str = date_str
  end

  def to_s
    return if date_en.to_s.empty?
    return date_obj.to_s if format_ymd?
    return date_obj.to_s[0...7] if format_ym?
    return date_en if format_y?

    raise "Unknown date format: #{date_en}"
  end

  private

  attr_reader :date_str

  def date_obj
    @date_obj ||= Date.parse(date_en)
  end

  def date_en
    @date_en ||= REMAP.reduce(date_str) { |str, (ro, en)| str.sub(ro, en) }
  end

  def format_ymd?
    (date_en =~ /^\d{1,2} \w+ \d{4}$/) || (date_en =~ /^\w+ \d{1,2}, \d{4}$/)
  end

  def format_ym?
    date_en =~ /^\w+ \d{4}$/
  end

  def format_y?
    date_en =~ /^\d{4}$/
  end
end

class RemoveReferences < Scraped::Response::Decorator
  def body
    Nokogiri::HTML(super).tap do |doc|
      doc.css('sup.reference').remove
    end.to_s
  end
end

class UnspanAllTables < Scraped::Response::Decorator
  def body
    Nokogiri::HTML(super).tap do |doc|
      doc.css('table.wikitable').each do |table|
        unspanned_table = TableUnspanner::UnspannedTable.new(table)
        table.children = unspanned_table.nokogiri_node.children
      end
    end.to_s
  end
end

class MinistersList < Scraped::HTML
  decorator RemoveReferences
  decorator UnspanAllTables
  decorator WikidataIdsDecorator::Links

  field :ministers do
    member_entries.map { |ul| fragment(ul => Officeholder) }.reject(&:empty?).map(&:to_h).uniq
  end

  private

  def member_entries
    noko.xpath('//table[.//td[contains(.,"Портрет")]][last()]//tr[td]')
  end
end

class Officeholder < Scraped::HTML
  COLUMNS = %w[ordinal dates image name].freeze

  def empty?
    tds.first.text.include?('№') || (itemLabel == '—')
  end

  field :item do
    name_cell.css('a/@wikidata').map(&:text).first
  end

  field :itemLabel do
    name_link_text || name_cell.text.tidy
  end

  field :startDate do
    WikiDate.new(raw_start).to_s
  end

  field :endDate do
    WikiDate.new(raw_end).to_s
  end

  private

  def raw_start
    return combo_date.first if combo_date?

    start_cell.text.tidy
  end

  def raw_end
    return combo_date.last if combo_date?

    end_cell.text.tidy
  end

  def tds
    noko.css('td')
  end

  def name_cell
    tds[COLUMNS.index('name')]
  end

  def start_cell
    tds[COLUMNS.index('start')]
  end

  def end_cell
    tds[COLUMNS.index('end')]
  end

  def combo_date_cell
    tds[COLUMNS.index('dates')]
  end

  def combo_date?
    COLUMNS.include? 'dates'
  end

  def raw_combo_date
    combo_date_cell.text.gsub(/^з/, '').split(/[—–-]/).map(&:tidy)
  end

  def combo_date
    rcd = raw_combo_date
    # Add missing year if in format "April 8 - May 20 2019"
    return ["#{rcd.first}, #{rcd.last[-4..]}", rcd.last] unless rcd.first[/\d{4}$/]

    rcd
  end

  def name_link_text
    name_cell.css('a').map(&:text).first
  end
end

url = ARGV.first
data = MinistersList.new(response: Scraped::Request.new(url: url).response).ministers

header = data.first.keys.to_csv
rows = data.map { |row| row.values.to_csv }
abort 'No results' if rows.count.zero?

puts header + rows.join
