module Crawler::Indexes
  extend Crawler::Persistence

  def self.index(collection, field)
    index = { field => 1 }
    collection.indexes.create index unless collection.indexes[ index ]
  end

  index users, :state
  index users, :star_state
  index users, :member_state
  index users, 'commits.to'

  index projects, :state
  index projects, :contribute_state

  index orgs, :state
  index orgs, :repo_state
end
