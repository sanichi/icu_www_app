class EmailListValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    emails = value.to_s.split(" ")
    valids = emails.select { |email| Global.valid_email?(email) }
    unless emails.any? && emails.size == valids.size
      record.errors[attribute] << (options[:message] || I18n.t("errors.messages.invalid"));
    end
  end
end
