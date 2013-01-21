module Crawler
  class Task::Members < Task
    collection_name :users
    indicator :member_state

    def perform
      orgs = wrap_array Octokit.orgs target
      orgs.each do |it|
        DB.orgs.upsert it['login']
      end
      scope.update finished
    end
  end
end
