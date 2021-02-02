require 'rails_helper'

describe SupplementalFile do
  it "stores no tags by default" do
    expect(subject.tags).to match_array([])
  end

  context "with valid tags" do
    let(:tags) { ["transcript", "caption"] }

    it "can store tags" do
      subject.tags = tags
      subject.save
      expect(subject.reload.tags).to match_array(tags)
    end
  end

  context "with invalid tags" do
    let(:bad_tags) { ["unallowed"] }

    it "does not store tags" do
      subject.tags = bad_tags
      expect(subject.save).to be_falsey
      expect(subject.errors.messages[:tags]).to include("unallowed is not an allowed value")
    end
  end
end
