class Admin::TranslationsController < ApplicationController
  before_action :set_translation, only: [:show, :edit, :update, :destroy]
  authorize_resource

  def index
    @translations = Translation.search(params, admin_translations_path)
    @creates = Translation.creates_required
    @updates = Translation.updates_required
    flash.now[:warning] = t("no_matches") if @translations.count == 0
    save_last_search(@translations, :translations)
  end

  def show
    if @translation.deletable?
      flash.now.notice = "This translation is no longer in use and may be deleted or kept for reference"
    end
    @prev_next = Util::PrevNext.new(session, Translation, params[:id], admin: true)
    @entries = @translation.journal_entries if current_user.roles.present?
  end

  def update
    @translation.user = current_user.signature
    @translation.old_english = @translation.english
    if @translation.update(translation_params)
      @translation.journal(:update, current_user, request.ip)
      redirect_to [:admin, @translation], notice: "Translation #{@translation.locale_key} was updated"
    else
      logger.error(@translation.errors.inspect)
      flash.now[:alert] = @translation.errors[:value].first
      render action: "edit"
    end
  end

  def destroy
    if @translation.deletable?
      @translation.journal(:destroy, current_user, request.ip)
      @translation.destroy
      redirect_to view_context.last_search(:translations) || admin_translations_path, notice: "Translation #{@translation.locale_key} was destroyed"
    else
      redirect_to [:admin, @translation], alert: "Can't destroy active translation #{@translation.locale_key}"
    end
  end

  private

  def set_translation
    @translation = Translation.find(params[:id])
  end

  def translation_params
    params.require(:translation).permit(:value)
  end
end
