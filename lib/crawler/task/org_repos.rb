module Crawler
  class Task::OrgRepos < Task
    collection_name :orgs
    indicator :repo_state

    def perform
      extract_repos :org_repos
      scope.update finished
    end
  end
end
