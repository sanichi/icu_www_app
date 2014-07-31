class IcuController < ApplicationController
  def officers
    @officers = Officer.ordered.include_players
  end

  def subscribers
    params[:season].present? or params[:season] = Season.new.to_s
    @subscribers = Player.search_subscribers(params, icu_subscribers_path)
  end

  def life_members
    @members = Player.life_members
  end
end
