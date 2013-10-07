class Translation < ActiveRecord::Base
  extend Util::Pagination

  LOCALES = %w[ga]
  KEY_FORMAT = /\A\w+(\.\w+)*\z/
  VAL_FORMAT = /\A[^"]+\z/
  PAGE_SIZE = 10

  validates :locale, inclusion: { in: LOCALES }
  validates :key, uniqueness: { scope: :locale }, format: { with: /\A\w+(\.\w+)*\z/ }
  validates :english, :old_english, presence: true
  validates :user, presence: true, if: Proc.new { |t| t.value.present? }
  validates :value,
    presence:  { message: "Translations should not be blank"},
    format:    { with: VAL_FORMAT, message: "Translations should not contain double quotes" },
    allow_nil: true
  validate  :value_has_same_variables_as_english

  after_save :update_cache
  after_destroy :cleanup_cache

  def quoted_value
    %Q["#{value}"]
  end

  def deletable?
    !active
  end

  def creatable?
    active && value.blank?
  end

  def cachable?
    active && value.present?
  end

  def updatable?
    active && value.present? && english != old_english
  end

  def locale_key
    '%s.%s' % [locale, key]
  end

  def max_length
    lengths = [english.length, old_english.length]
    lengths.push(value.length) if value
    lengths.max
  end

  def self.search(params, path)
    matches = order(:key, :locale)
    [:key, :english, :value, :user].each do |param|
      matches = matches.where("translations.#{param} LIKE ?", "%#{params[param]}%") if params[param].present?
    end
    case params[:category]
    when "Action required" then matches = matches.where(active: true).where("value IS NULL OR english != old_english")
    when "In use"          then matches = matches.where(active: true)
    when "No longer used"  then matches = matches.where(active: false)
    end
    paginate(matches, params, path, PAGE_SIZE)
  end

  def self.creates_required
    where(active: true, value: nil).count
  end

  def self.updates_required
    where(active: true).where.not(value: nil).where("english != old_english").count
  end

  def self.cache
    @redis ||= Redis.new(db: cache_db)
  end

  def self.reconnect(context)
    logger.info "preparing to reconnect to redis (#{context})" if @redis
    @redis = nil
  end

  def self.cache_db
    @redis_db ||= ["production", "development", "test"].index(Rails.env) + 1
  end

  def self.check_cache(opt={})
    count = 0
    if Rails.env == "test" && !opt[:dont_skip_test_env]
      cache.flushdb
    else
      cachable = all.select{ |t| t.cachable? }.each_with_object({}) do |t, h|
        h[t.locale_key] = t.quoted_value
      end
      cached = cache.keys.each_with_object({}) do |c, h|
        h[c] = cache.get(c)
      end
      cachable.each do |k, v|
        unless cached[k] && cached[k] == v
          cache.set(k,v)
          logger.warn "#{cached[k] ? 'upd' : 'cre'}ated redis translation #{k} => #{v}"
          count += 1
        end
      end
      cached.each do |k, v|
        unless cachable[k]
          cache.del(k)
          logger.warn "deleted redis translation #{k} => #{v}"
          count += 1
        end
      end
      # In normal circumstances 'count' should be zero because the callbacks should keep Redis and MySQL in sync.
      if count == 0
        logger.info "no changes to redis translations"
      else
        logger.warn "changes to redis translations: #{count}"
      end
    end
    reconnect("check_cache") # don't reuse this connection to avoid Passenger fork problems
    count
  end

  def update_cache
    if cachable?
      Translation.cache.set(locale_key, quoted_value)
    else
      Translation.cache.del(locale_key)
    end
  end

  def cleanup_cache
    Translation.cache.del(locale_key)
  end

  def self.yaml_data
    files = yaml_files
    nested = load_yamls(files)
    flatten_yaml({}, nested)
  end

  def self.update_db
    key_english = yaml_data
    key_locale_translation = db_data
    key_english.each do |key, english|
      locale_translation = key_locale_translation[key]
      if locale_translation
        update_records(locale_translation, english)
      else
        create_records(key, english)
      end
    end
    key_locale_translation.each do |key, locale_translation|
      deactivate_records(locale_translation) unless key_english[key]
    end
  end

  private

  def value_has_same_variables_as_english
    if value.present?
      eng = english.scan(/%{[^}]*}/).sort.join
      val = value.scan(/%{[^}]*}/).sort.join
      unless eng == val
        errors.add(:value, "Translation should have same interpolated variables as English")
      end
    end
  end

  def self.yaml_files
    Dir.glob(File.join(Rails.root, "config", "locales", "**", "en.yml"))
  end

  def self.load_yamls(files)
    files.each_with_object({}) do |file, hash|
      data = load_yaml(file)
      raise "invalid data in #{file}: is #{data.class}, should be Hash" unless data.is_a?(Hash)
      raise "invalid data in #{file}: no 'en' hash" unless data["en"].is_a?(Hash)
      hash.deep_merge!(data["en"]) do |key, old_val, new_val|
        raise "duplicate key #{key} in #{file} (#{old_val} <=> #{new_val})" unless old_val.is_a?(Hash) && new_val.is_a?(Hash)
      end
    end
  end

  def self.load_yaml(file)
    begin
      YAML.load_file(file)
    rescue => e
      raise "cannot load translations from #{file}: #{e.message}"
    end
  end

  def self.flatten_yaml(flat, data, key=nil)
    if data.is_a?(Hash)
      data.each_pair do |k, v|
        flatten_yaml(flat, v, key ? "#{key}.#{k}" : k)
      end
    else
      raise "non-hash (#{data}) without a key" unless key
      raise "invalid key: #{key}" unless key.match(KEY_FORMAT)
      raise "duplicate key: #{key}" if flat[key]
      flat[key] = data
    end
    flat
  end

  def self.db_data
    Translation.all.each_with_object({}) do |translation, hash|
      hash[translation.key] = {} unless hash[translation.key]
      hash[translation.key][translation.locale] = translation
    end
  end

  def self.update_records(locale_translation, english)
    locale_translation.each do |locale, translation|
      translation.update_columns(old_english: translation.english, english: english) unless english == translation.english
      if LOCALES.include?(locale)
        translation.update_column(:active, true) unless translation.active
      else
        translation.update_column(:active, false) if translation.active
      end
    end
  end

  def self.create_records(key, english)
    LOCALES.each do |locale|
      Translation.create(locale: locale, key: key, value: nil, english: english, old_english: english, active: true)
    end
  end

  def self.deactivate_records(locale_translation)
    locale_translation.each_value do |translation|
      translation.update_column(:active, false) if translation.active
    end
  end

  private_class_method :yaml_files, :load_yamls, :load_yaml, :flatten_yaml
  private_class_method :db_data, :update_records, :create_records, :deactivate_records
end
