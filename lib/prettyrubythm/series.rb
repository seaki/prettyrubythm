module PrettyRubythm
  # PrettyRhythm series (ex. Aurora dream, PriPara)
  # this is record of "config/series.yml"
  class Series < Hash
    include Hashie::Extensions::MethodAccess
    include PrettyRubythm::Concerns::Util
    include Enumerable

    @cache = {}
    @config = nil

    # @param [PrettyRubythm::Series,PrettyRubythm::Actor] other
    #
    # @return [Boolean] other is same PrettyRubythm::Series or PrettyRubythm::Series include PrettyRubythm::Actor
    def ===(other)
      case other
      when self.class
        self == other
      when PrettyRubythm::Actor
        actors.include? other
      else
        false
      end
    end

    # @return [Array<PrettyRubythm::Actor>]
    def actors
      unless @actors
        @actors = []
        if has_key?(:actors)
          fetch(:actors).each do |actor_name|
            @actors << PrettyRubythm::Actor.find(actor_name.to_sym)
          end
        end
      end

      @actors
    end

    alias_method :each_without_actors, :each

    def each(&block)
      actors.each(&block)
    end

    # @return [String] json string
    def to_json(*_args)
      original_hash = {}
      each_without_actors do |k, v|
        original_hash[k] = v
      end
      original_hash.to_json
    end

    class << self
      # @return [Array<Symbol>]
      def names
        config.keys
      end

      # @return [Array<Symbol>]
      def uniq_names
        uniq_names = []
        config.each do |name, series|
          uniq_names << name unless uniq_names.any? {|uniq_name| config[uniq_name][:title] == series[:title] }
        end
        uniq_names
      end

      # @return [Hash] content of config/series.yml
      def config
        unless @config
          config_file = "#{File.dirname(__FILE__)}/../../config/series.yml"
          @config = YAML.load_file(config_file).deep_symbolize_keys
        end
        @config
      end

      # @return [Hash] content of config/series.yml
      def reload_config!
        @cache = {}
        @config = nil
        config
      end

      # @param [Symbol] series_name
      def valid?(series_name)
        names.include?(series_name)
      end

      # @param series_name [Symbol]
      # @return [PrettyRubythm::Series]
      # @raise arg is not precure
      def find(series_name)
        raise UnknownSeriesError, "unknown series: #{series_name}" unless valid?(series_name)

        @cache ||= {}
        unless @cache[series_name]
          series_config = config[series_name] || {}
          series_config.reject! {|_k, v| v.nil? }

          @cache[series_name] = PrettyRubythm::Series[series_config]
        end

        @cache[series_name]
      end
    end
  end
end
