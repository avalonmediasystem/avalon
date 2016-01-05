class DerivativeAddManaged < ActiveRecord::Migration

  def up
    say_with_time("Add Derivative.managed") do
      Derivative.find_each({},{batch_size:5}) do |d|
        d.managed ||= true;
        d.save_as_version('R5');
      end
    end
  end

  def down
    say_with_time("Remove Derivative.managed") do
      Derivative.find_each({},{batch_size:5}) do |d|
        d.managed = nil;
        d.save_as_version('R4');
      end
    end
  end

end
