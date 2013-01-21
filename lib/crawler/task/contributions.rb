module Crawler
  class Task::Contributions < Task
    collection_name :projects
    indicator :contribute_state

    def perform
      return scope.update indication :wait unless @doc['state'] == 'ready'
      return scope.update indication :fork if @doc['fork']

      contributors = wrap_array Octokit.contributors target
      contributors.each do |it|
        next unless it['login']
        next if DB.users.find(_id: it['login'], 'commits.to' => target).one
        commits = { commits: { to: target, count: it['contributions'] }}
        DB.users.upsert it['login'], '$push' => commits
      end
      scope.update finished
    end
  end
end
