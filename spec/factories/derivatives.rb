FactoryGirl.define do
  factory :derivative do
    duration "21575"
    location_url "rtmp://localhost/vod/mp4:6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning"
    track_id "track-6"
    hls_url "http://avalon.dev/6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning.mp4.m3u8"
    hls_track_id "track-8"
    after(:create) do |d|
      d.save
    end
  end
end
