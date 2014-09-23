set :output, "log/cron.log"
set :job_template, nil

every :day, at: "3:14am" do
  rake "cleanup:empty[f]"
end

every :day, at: "3:16am" do
  rake "cleanup:unpaid[f]"
end

every :day, at: "4:29am" do
  rake "mail:stats"
end

every :day, at: "4:31am" do
  rake "mail:events"
end

every :day, at: "5:15am" do
  rake "pgn:db"
end

every :hour do
  rake "mail:control"
end
