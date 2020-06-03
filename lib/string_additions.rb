module StringAdditions
  def remove_zero_width_chars
    self.gsub(/^[\u200B-\u200D\uFEFF\u2060]/, '').gsub(/[\u200B-\u200D\uFEFF\u2060]$/, '') #Begins with and Ends with zero-width character
  end
end
String.prepend(StringAdditions)