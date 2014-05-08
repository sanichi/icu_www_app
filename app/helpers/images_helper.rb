module ImagesHelper
  def image_order_menu(selected)
    orders = %w[year updated_at id].map { |ord| [t("image.order.#{ord}"), ord] }
    options_for_select(orders, selected)
  end
end
