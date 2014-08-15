class Admin::ItemsController < ApplicationController
  def index
    authorize! :index, Item
    @items = Item.search(params, admin_items_path)
    flash.now[:warning] = t("no_matches") if @items.count == 0
  end
  
  def sales_ledger
    authorize! :sales_ledger, Item
    @ledger = SalesLedger.new
  end
end
