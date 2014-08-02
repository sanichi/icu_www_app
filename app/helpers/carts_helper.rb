module CartsHelper
  def euros(amount, precision: 2)
    number_to_currency(amount, precision: precision, unit: "€")
  end
end
