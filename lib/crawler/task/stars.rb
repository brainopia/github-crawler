module Crawler
  class Task::Stars < Task
    collection_name :users
    indicator :star_state

    def perform
      extract_repos :starred
      scope.update finished
    end
  end
end
