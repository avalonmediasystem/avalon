require 'rails_helper'

RSpec.describe SearchBuilder do
  subject(:builder) { described_class.new processor_chain }

  let(:processor_chain) { [] }
  let(:manager) { FactoryBot.create(:manager) }
  let(:ability) { Ability.new(manager) }

  describe "#only_published_items" do
    it "should include policy clauses when user is manager" do
      allow(subject).to receive(:current_ability).and_return(ability)
      allow(subject).to receive(:policy_clauses).and_return("test:clause")
      expect(subject.only_published_items({})).to eq ["test:clause OR workflow_published_sim:\"Published\""]
    end
  end
end