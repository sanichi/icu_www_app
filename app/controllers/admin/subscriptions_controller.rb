class Admin::SubscriptionsController < ApplicationController
  def index
    authorize! :index, Subscription
    @subs = Subscription.search(params, admin_subscriptions_path)
    flash.now[:warning] = t("no_matches") if @subs.count == 0
  end
end
