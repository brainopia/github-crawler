module Crawler::Stats
  extend self
  LF = "\n"

  def octokit(file)
    volume = Octokit.mirrors.map {|it| [it.remaining.value, it.reserved.value] }
    remaining_total, reserved_total = volume.transpose.each {|it| it.inject(:+) }

    data = "#{Time.now}" << LF*2
    data = "Total: #{reserved_total} / #{remaining_total}" << LF*2

    volume.each.with_index do |(remaining, reserved), index|
      log_record << "Client #{index+1}: #{remaining} / #{reserved}\n"
    end

    File.open(file, 'w+') {|it| it.puts log_record }
  end
end
