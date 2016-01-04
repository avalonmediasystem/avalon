class DerivativeAddUnmanaged < ActiveRecord::Migration

  def up
    say_with_time("Add Derivative.unmanaged") do
      Derivative.find_each({},{batch_size:5}) do |d|
        d.unmanaged ||= false;
        d.save_as_version('R5');
      end
    end
  end

  def down
    say_with_time("Remove Derivative.unmanaged") do
      Derivative.find_each({},{batch_size:5}) do |d|
        d.unmanaged = nil;
        d.save_as_version('R4');
      end
    end
  end

end
