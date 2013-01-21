module Crawler
  class Task::Orgs < Task
    def perform
      info = Octokit.org target
      members = extract_members
      scope.update finished info.merge!(members: members)
    end

    private

    def extract_members
      members = wrap_array Octokit.org_members target
      members.each do |it|
        DB.users.upsert it['login']
      end
    end
  end
end
