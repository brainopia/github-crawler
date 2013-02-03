require 'delegate'

class Crawler::Task
  extend Forwardable
  def_delegators 'self.class', :collection, :indication

  DB = Crawler::Persistence

  class << self

    def next
      queues.inject(false) do |task, queue|
        task or queue.fetch
      end
    end

    def collection
      DB.collection collection_name
    end

    def indication(value, additional={})
      { '$set' => { indicator => value.to_s }.merge!(additional) }
    end

    def fetch
      task = new_tasks.modify indication(:process)
      new task if task
    end

    private

    def queues
      [Projects, Users, Contributions, Orgs, OrgRepos, Members, Stars]
    end

    def new_tasks
      collection.without indicator
    end

    def collection_name(value=nil)
      if value
        @collection_name = value
      else
        @collection_name ||= name.split('::').last.downcase
      end
    end

    def indicator(value=nil)
      if value
        @indicator = value
      else
        @indicator ||= :state
      end
    end
  end

  def initialize(doc)
    @doc = doc
  end

  def target
    @doc['_id']
  end

  def finished(info={})
    indication :ready, info
  end

  def wrap_array(object)
    object.is_a?(Array) ? object : [object]
  end

  def scope
    collection.find(_id: target)
  end

  def pause
    scope.update indication(:pause)
  end

  def extract_repos(type=:repos)
    repos = wrap_array Octokit.send type, target
    repos.each do |repo|
      DB.projects.upsert repo['full_name']
    end
  end
end
