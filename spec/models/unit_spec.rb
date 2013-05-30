require 'spec_helper'

describe Unit do
  let (:unit) { Unit.new }
  describe 'validations' do
    context 'name' do 
      it 'should be present' do
        unit.valid?
        unit.errors.should include(:name)
      end
      it 'should be unique' do
        Unit.create(name:'A unit')
        Unit.create(name:'A unit').errors[:name].should include('has already been taken')
      end
    end
  end
end