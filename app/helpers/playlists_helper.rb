module PlaylistsHelper
  def human_friendly_visibility(visibility)
    icon = visibility == Playlist::PUBLIC ? 'unlock' : 'lock'
    safe_join([content_tag(:span, '', class:"glyphicon glyphicon-#{icon}", title: t("playlist.#{icon}AltText")),t("playlist.#{icon}Text")], ' ')
  end
end
