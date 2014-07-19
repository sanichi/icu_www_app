module DownloadsHelper
  def download_type_menu(selected)
    types = Download::TYPES.keys.map { |type| [type.to_s.upcase, type.to_s] }
    types.unshift([t("download.any_type"), ""])
    options_for_select(types, selected)
  end
end
