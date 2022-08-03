Time::DATE_FORMATS[:long_ordinal_12h] = lambda { |time| time.strftime("%B #{time.day.ordinalize}, %Y %l:%M %p") }
