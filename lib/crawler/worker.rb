class Crawler::Worker
  TIMEOUT = 1

  def self.start
    new.run
  end

  def run
    loop do
      task = Crawler::Task.next
      task ? perform(task) : sleep(TIMEOUT)
    end
  end

  def perform(task)
    retryable { task.perform }
  rescue Octokit::Error, Faraday::Error::ClientError
    task.pause
  end
end
