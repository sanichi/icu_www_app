module CartsHelper
  def euros(amount)
    number_to_currency(amount, precision: 2, unit: "€")
  end
end
