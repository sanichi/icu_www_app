class IcuController < ApplicationController
  def index
    @officers = Officer.ordered.include_players
  end
end
