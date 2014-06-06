module UploadsHelper
  def upload_type_menu(selected)
    types = Upload::TYPES.keys.map { |type| [type.to_s.upcase, type.to_s] }
    types.unshift([t("upload.any_type"), ""])
    options_for_select(types, selected)
  end
end
