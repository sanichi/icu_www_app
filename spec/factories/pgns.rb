FactoryGirl.define do
  factory :pgn do
    content_type "text/plain"
    file_name    "games.pgn"
    file_size    1234
    game_count   1
    lines        6000
    user
  end
end
