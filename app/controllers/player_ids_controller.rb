class PlayerIdsController < ApplicationController
  def index
    @players = Player.search(params, player_ids_path, remote: true, per_page: 10)
  end
end
