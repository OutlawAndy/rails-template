AutoHtml.add_filter(:mentioned) do |text|
  text.gsub(/(?<=\s|\A)\@\w+\b/) do |match|
    if User.where(username: match[1..-1]).count == 1
      "<a href=\"/meet/#{match[1..-1]}\">#{match[1..-1]}</a>"
    else
      match[1..-1]
    end
  end
end

AutoHtml.add_filter(:model_reference) do |text|
  text.gsub(/(?<=\s|\A)\%\[(.+?)\]\((.+?)\)/) do
    "<em><a href=\"#{$2}\">#{$1.titleize}</a></em>"
  end
end

AutoHtml.add_filter(:icon) do |text|
  replacement_string = ""
  text.gsub(/io?con:([^:]*?)\((.*?)\)([a-z])?/i) do
    replacement_string<< " <i class='ui large #{$1} icon ss-icon "
    replacement_string<< case $3
      when 'b'
        "ss-block'>#{$2}</i> "
      when 'l'
        "ss-line'>#{$2}</i> "
      when 'i'
        "io-#{$2}'></i> "
      else
        " io-#{$2} ss-block ss-#{$2}'></i> "
    end

    replacement_string
  end
end
AutoHtml.add_filter(:xicon) do |text|
  color = ["red", "blue", "green", "orange", "teal", "purple", "black"]
  replacement_string = ""
  text.gsub(/icon:(.*?):(.*?)\((.*?)\)([a-z])?/i) do
    replacement_string<< case $1
      when "circle"
        " <i class='ui large inverted circular #{$2} icon ss-icon "
      when "big-circle"
        " <i class='ui huge inverted circular #{$2} icon ss-icon "
      when "square"
        " <i class='ui large inverted square #{$2} icon ss-icon "
      when "huge","massive"
        " <i class='ui #{$1} #{$2} icon ss-icon "
      when *color
        var = $2 == "circle" ? "inverted circular" : $2
        " <i class='ui large #{$1} #{var} icon ss-icon "
      else
        " <i class='ui large icon ss-icon #{$1} #{$2} "
    end
    replacement_string<< case $4
      when 'b'
        "ss-block'>#{$3}</i> "
      when 'l'
        "ss-line'>#{$3}</i> "
      when 'i'
        "io-#{$3}'></i> "
      else
        " ss-#{$2} io-#{$3} ss-block ss-#{$3}'></i> "
    end
    replacement_string
  end
end

AutoHtml.add_filter(:icon_link) do |text|
  text.gsub(/io?con:([^:]*?)\((.*?)\)\[([^\]]*?)\]/i) do
    " <a href='#{$3}'><i class='ui large #{$1} link icon ss-icon io-#{$2} ss-block ss-#{$2}'></i></a> "
  end
end