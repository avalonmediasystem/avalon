RSpec::Matchers.define :hash_match do |expected|
  match do |actual|
    diff = HashDiff.diff(actual,expected) do |p,a,e|
      if a.is_a?(RealFile) && e.is_a?(RealFile)
        FileUtils.cmp(a,e)
      elsif a.is_a?(File) && e.is_a?(File)
        FileUtils.cmp(a,e)
      elsif p == ""
         nil
      else
        a.eql? e
      end
    end
    diff == []
  end
end
