module LendingPeriod

  extend ActiveSupport::Concern

  included do
    after_initialize :set_lending_period
  end

  def set_lending_period
    if self.is_a? Admin::Collection
      param_name = 'default_lending_period'
      custom_lend_period(param_name)
      self.default_lending_period = @duration
      self.default_lending_period ||= ActiveSupport::Duration.parse(Settings.controlled_digital_lending.default_lending_period).to_i
    elsif !self.collection_id.nil?
      param_name = 'lending_period'
      custom_lend_period(param_name)
      self.lending_period = @duration
      self.lending_period ||= Admin::Collection.find(self.collection_id).default_lending_period
    end
  end

  private

  def custom_lend_period(param_name)
    if (!self.send(param_name).nil? && !(self.send(param_name).is_a? Integer))
      build_lend_period(param_name)
      @duration = ActiveSupport::Duration.parse(@lend_period).to_i
    end
  end

  def build_lend_period(param_name)
    @lend_period = self.send(param_name).dup

    replacement = {
      /\s+days?/i => 'D',
      /\s+hours?/i => 'H',
      /,?\s+/ => 'T'
    }

    rules = replacement.collect{ |k, v| k }

    matcher = Regexp.union(rules)

    @lend_period = @lend_period.gsub(matcher) do |match|
      replacement.detect{ |k, v| k =~ match }[1]
    end

    @lend_period.match(/P/) ? @lend_period : build_iso8601_duration(@lend_period)
  end

  def build_iso8601_duration(lend_period)
    if @lend_period.match?(/D/)
      unless @lend_period.include? 'P'
        @lend_period.prepend('P')
      end
    else
      unless @lend_period.include? 'PT'
        @lend_period.prepend('PT')
      end
    end
  end
end
