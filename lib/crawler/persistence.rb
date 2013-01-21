module Crawler::Persistence
  extend self

  def projects
    collection :projects
  end

  def users
    collection :users
  end

  def orgs
    collection :orgs
  end

  def collection(name)
    mongodb.use name
    mongodb[name]
  end

  private

  def mongodb
    Thread.current[:mongodb] ||= Moped::Session.new [ '127.0.0.1:27017' ]
  end
end
