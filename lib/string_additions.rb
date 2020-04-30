module StringAdditions
  def remove_zero_width_chars
    self.gsub("\u200b", '')
  end
end

String.prepend(StringAdditions)
