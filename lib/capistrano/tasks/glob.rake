namespace :deploy do  
  namespace :symlink do
    desc "Resolve globs in linked_files"
    task :glob do
      new_linked_files = []
      on release_roles :all do
        within shared_path do
          Array(fetch(:linked_files, [])).each do |linked_file|
            if linked_file =~ /[\?\*]/
              new_linked_files += capture(:ls, linked_file, raise_on_non_zero_exit: false).split
            else
              new_linked_files << linked_file
            end
          end
        end
      end
      set :linked_files, new_linked_files
    end
  end
end
before "deploy:check", "deploy:symlink:glob"
