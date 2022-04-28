#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/scraper_data'
require 'open-uri/cached'
require 'pry'

class MemberList
  class Member
    field :name do
      noko.css('.name').text.split(' ').reverse.join(' ').tidy
    end

    field :position do
      return raw_position unless raw_position.include? 'Deputy Prime Minister'

      raw_position.gsub(' - ', ', ').split(', ')
    end

    private

    def raw_position
      noko.css('.employment').text.tidy
    end
  end

  class Members
    def member_container
      noko.css('.team .team-item')
    end
  end
end

file = Pathname.new 'official.html'
puts EveryPoliticianScraper::FileData.new(file).csv
