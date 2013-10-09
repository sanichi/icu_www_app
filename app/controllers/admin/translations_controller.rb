class Admin::TranslationsController < ApplicationController
  authorize_resource
  before_action :set_translation, only: [:show, :edit, :update, :destroy]

  def index
    @translations = Translation.search(params, admin_translations_path)
    @creates = Translation.creates_required
    @updates = Translation.updates_required
    flash.now[:warning] = t("no_matches") if @translations.count == 0
    save_last_search(:admin, :translations)
  end

  def update
    @translation.user = current_user.email
    @translation.old_english = @translation.english
    if @translation.update(translation_params)
      redirect_to [:admin, @translation], notice: "Translation #{@translation.locale_key} was updated"
    else
      logger.error(@translation.errors.inspect)
      flash.now[:alert] = @translation.errors[:value].first
      render action: "edit"
    end
  end

  def destroy
    if @translation.deletable?
      @translation.destroy
      redirect_to view_context.last_search(:admin, :translations) || admin_translations_path, notice: "Translation #{@translation.locale_key} was destroyed"
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
