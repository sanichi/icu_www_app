module Util
  module Params
    def clear_whitespace_to_reveal_placeholders(params, *keys)
      keys.each do |key|
        params[key] = "" if params.has_key?(key) && params[key].blank?
      end
    end
  end
end