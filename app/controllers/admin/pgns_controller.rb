class Admin::PgnsController < ApplicationController
  before_action :set_pgn, only: [:show, :edit, :update, :destroy]
  authorize_resource

  def index
    @pgns = Pgn.search(params, admin_pgns_path)
    flash.now[:warning] = t("no_matches") if @pgns.count == 0
    save_last_search(@pgns, :pgns)
  end

  def show
    @pgn = Pgn.find(params[:id])
    @prev_next = Util::PrevNext.new(session, Pgn, params[:id], admin: true)
    @entries = @pgn.journal_entries if current_user.roles.present?
  end

  def new
    @pgn = Pgn.new
  end

  def create
    @pgn = Pgn.new(pgn_params(true))
    @pgn.user = current_user

    if file = @pgn.file
      @pgn.file_name = file.original_filename
      @pgn.file_size = file.size
      @pgn.content_type = `file -b --mime-type #{file.path}`.strip
    end

    if @pgn.save
      @pgn.parse(file.tempfile)
      @pgn.save
      @pgn.journal(:create, current_user, request.ip)
      flash_feedback
      redirect_to [:admin, @pgn]
    else
      logger.info @pgn.errors.inspect
      flash_first_error(@pgn, now: true)
      render action: "new"
    end
  end

  def update
    if @pgn.update(pgn_params)
      @pgn.journal(:update, current_user, request.ip)
      redirect_to [:admin, @pgn], notice: "PGN data was successfully updated"
    else
      flash.now.alert = @pgn.errors[:base].first if @pgn.errors[:base].any?
      render action: "edit"
    end
  end

  def destroy
    @pgn.journal(:destroy, current_user, request.ip)
    @pgn.destroy
    redirect_to admin_pgns_path, notice: "PGN data (and any associated games) successfully deleted"
  end

  private

  def set_pgn
    @pgn = Pgn.find(params[:id])
  end

  def pgn_params(new_record=false)
    atrs = [:comment]
    atrs += [:file, :import] if new_record
    params[:pgn].permit(atrs.compact)
  end

  def flash_feedback
    if @pgn.problem.present?
      flash[:alert] = "PGN data #{@pgn.game_count > 0 ? 'was only partially parsed' : 'could not be parsed'}"
    elsif @pgn.imports > 0
      flash[:notice] = "PGN data was successfully parsed and games imported"
    elsif @pgn.game_count > 0
      flash[:warning] = "PGN data was parsed successfully but no games were imported"
    else
      flash[:alert] = "PGN file appears to contain no games"
    end
  end
end
