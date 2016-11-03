namespace :avalon do
  desc "Link hls dir to public/streams"
  task :link_hls_dir do
    source = fetch(:hls_dir, nil)
    unless source.nil?
      target = release_path.join('public/streams')
      on roles(:web) do
        execute :ln, "-s", source, target
      end
    end
  end
end
after "deploy:updated", "avalon:link_hls_dir"
