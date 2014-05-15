Paperclip.options[:command_path] = `which convert`.sub(/\/[^\/]+$/, "/")
Paperclip.options[:content_type_mappings] = { pgn: "text/plain" }
