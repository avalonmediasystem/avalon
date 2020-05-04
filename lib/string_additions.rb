module StringAdditions
  def remove_zero_width_chars
    self.gsub(/[\u200B-\u200D\uFEFF]/, '')
    #self.gsub("\\u200b", '')
    #self.gsub("\u200b", '')
  end
end

String.prepend(StringAdditions)