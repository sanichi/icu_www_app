class HelpController < ApplicationController
  def membership
    if user = User.include_player.references(:players).where("roles LIKE '%treasurer%'").where.not("players.address IS NULL").first
      @treasurer = user.player
    end
  end
end
