module Crawler
  class Task::Projects < Task
    def perform
      info = Octokit.repo target
      scope.update finished info

      if info['parent']
        collection.upsert info['parent']['full_name']
      end
    end
  end
end
