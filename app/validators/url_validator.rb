class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless Global.valid_url?(value)
      record.errors[attribute] << (options[:message] || I18n.t("errors.messages.invalid"));
    end
  end
end
