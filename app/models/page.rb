class Page
  def self.environment
    ENV.keys.sort.each_with_object({}) do |key, hash|
      val = ENV[key].dup
      val = val.split(/:/).map{ |path| path == "" ? "(blank)" : path }.join("\n") if key.match(/PATH/)
      hash[key] = val
    end
  end
end
