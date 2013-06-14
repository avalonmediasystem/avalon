module Select2
  module Autocomplete
    def self.as_json(id, text, opts = {})
      {
        id: id,
        text: text,
      }.merge( opts )
    end

    def self.param_to_array(param)
      return [] if param.empty? || param == '[]' || param == 'multiple'
      return [param] unless param.include?(',')
      param.split(',') - ['multiple']
    end

  end

end