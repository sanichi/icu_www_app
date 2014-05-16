module UploadsHelper
  def upload_access_menu(selected, options, default)
    accs = options.map { |acc| [t("access.#{acc}"), acc] }
    accs.unshift([t(default), ""]) if accs.size > 1
    options_for_select(accs, selected)
  end

  def upload_type_menu(selected)
    types = Upload::TYPES.keys.map { |type| [type.to_s.upcase, type.to_s] }
    types.unshift([t("upload.any_type"), ""])
    options_for_select(types, selected)
  end
end
