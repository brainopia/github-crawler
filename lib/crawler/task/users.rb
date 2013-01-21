module Crawler
  class Task::Users < Task
    def perform
      extract_repos
      info = Octokit.user target
      scope.update finished info
    end
  end
end
