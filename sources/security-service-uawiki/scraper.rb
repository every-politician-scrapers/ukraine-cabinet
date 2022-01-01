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
    'XXX'       => 'May',
    'червня'    => 'June',
    'липня'     => 'July',
    'серпня'    => 'August',
    'вересня'   => 'September',
    'YYY'       => 'October',
    'листопада' => 'November',
    'грудня'    => 'December',
  }.freeze

  def initialize(date_str)
    @date_str = date_str
  end

  def to_s
    return if date_en.tidy.empty?
    return date_obj.to_s if (date_en =~ /\d{1,2} \w+ \d{4}/) || (date_en =~ /\w+ \d{1,2}, \d{4}/)
    return date_obj.to_s[0...7] if date_en =~ /\w+ \d{4}/

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
    noko.xpath('//table[.//th[contains(.,"Голова")]][last()]//tr[td]')
  end
end

class Officeholder < Scraped::HTML
  def empty?
    itemLabel.empty?
  end

  field :item do
    tds[1].css('a/@wikidata').map(&:text).last
  end

  field :itemLabel do
    tds[1].css('a').map(&:text).last
  end

  field :startDate do
    WikiDate.new(raw_start).to_s
  end

  field :endDate do
    WikiDate.new(raw_end).to_s
  end

  private

  def tds
    noko.css('td')
  end

  def raw_start
    date_parts.values_at(0, 1).join(' ')
  end

  def raw_end
    date_parts.values_at(2, 3).join(' ')
  end

  def date_parts
    tds[3].css('a').take(4)
  end
end

url = ARGV.first
data = MinistersList.new(response: Scraped::Request.new(url: url).response).ministers

header = data.first.keys.to_csv
rows = data.map { |row| row.values.to_csv }
abort 'No results' if rows.count.zero?

puts header + rows.join
