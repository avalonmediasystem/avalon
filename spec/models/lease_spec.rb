# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

require 'rails_helper'

describe Lease do
  let!(:lease) {FactoryBot.create(:lease)}

  describe 'Valid Lease Term' do
    it 'should return true when the date is between the lease periods' do
      expect(lease.lease_is_active?).to be_truthy
    end
    it 'should return false when today is prior to the lease beginning' do
      allow(Date).to receive(:today).and_return(Date.parse('11 November 1984'))
      expect(lease.lease_is_active?).to be_falsey
    end
    it 'should return false when today is after the expiration of the lease' do
      allow(Date).to receive(:today).and_return(Date.parse('11 November 9999'))
      expect(lease.lease_is_active?).to be_falsey
    end
  end
  describe 'time input formats' do
    before :each do
      @lease = Lease.new
      @lease.begin_time = Date.yesterday
    end
    it 'accepts a Time object' do
      @lease.end_time = Time.now
      expect { @lease.save }.not_to raise_error
    end
    it 'accepts a Date object' do
      @lease.end_time = Date.today
      expect { @lease.save }.not_to raise_error
    end
    it 'accepts a DateTime object' do
      @lease.end_time = DateTime.now
      expect { @lease.save }.not_to raise_error
    end
    it 'accepts a String represenation of a date' do
      @lease.begin_time = '1 January 2010'
      @lease.end_time = '1 January 2011'
      expect { @lease.save }.not_to raise_error
    end
  end
  describe 'formating times' do
    it 'stores the begin and end times as DateTimes' do
      expect(lease.begin_time.class).to eq(DateTime)
      expect(lease.end_time.class).to eq(DateTime)
    end

    it 'sets begin_time to the start of the day' do
      expect(lease.begin_time).to eq(DateTime.now.utc.beginning_of_day - 1.day)
    end

    it 'sets end_time to the end of the day' do
      expect(lease.end_time).to eq(DateTime.now.utc.end_of_day + 1.day)
    end

    describe 'start of day' do
      it 'returns the start of the day when passed in a day' do
        expect(lease.start_of_day(DateTime.now)).to eq(DateTime.now.utc.beginning_of_day)
      end
      it 'returns the start of the day as a String' do
        expect(lease.start_of_day(DateTime.now).class).to eq(DateTime)
      end
    end

    describe 'end of day' do
      it 'returns the start of the day when passed in a day' do
        expect(lease.end_of_day(DateTime.now)).to eq(DateTime.now.utc.end_of_day)
      end
      it 'returns the start of the day as a String' do
        expect(lease.end_of_day(DateTime.now).class).to eq(DateTime)
      end
    end
  end
  describe 'setting the begin_time' do
    before :each do
      @lease = Lease.new
      @lease.end_time = Date.tomorrow
    end
    it 'sets the begin_time to today if it is nil' do
      @lease.apply_default_begin_time
      expect(@lease.begin_time).to eq(DateTime.parse(Date.today.to_s).utc.beginning_of_day)
    end
    it 'does not set the begin_time today is one is provided' do
      @lease.begin_time = DateTime.parse(Date.yesterday.to_s)
      @lease.apply_default_begin_time
      expect(@lease.begin_time.iso8601).to match(DateTime.parse(Date.yesterday.to_s).beginning_of_day.iso8601)
    end
  end
  describe 'end_time validation' do
    before :each do
      @lease = Lease.new
      @lease.begin_time = Date.yesterday
    end
    it 'raises an ArgumentError if end_time is not set' do
      expect { @lease.ensure_end_time_present }.to raise_error(ArgumentError)
      expect { @lease.save }.to raise_error(ArgumentError)
    end

    it 'does not raise an ArgumentError if end_time is set' do
      @lease.end_time = Date.tomorrow
      expect { @lease.ensure_end_time_present }.to_not raise_error
      expect { @lease.save }.to_not raise_error
    end
  end
  describe 'time range validation' do
    before :each do
      @lease = Lease.new
    end
    it 'raises an ArgumentError if end_time preceeds begin_time' do
      @lease.end_time = Date.yesterday
      @lease.begin_time = Date.tomorrow
      expect { @lease.validate_dates }.to raise_error(ArgumentError)
      expect { @lease.save }.to raise_error(ArgumentError)
    end
    it 'does not raise an ArgumentError if the end_time is set to the same value as begin_time' do
      now = Date.today
      @lease.end_time = now #beginning of toay
      @lease.begin_time = now #end of today
      expect { @lease.validate_dates }.to_not raise_error
    end
    it 'does not raise an ArgumentError if the end_time is after the begin_time' do
      @lease.end_time = Date.tomorrow
      @lease.begin_time = Date.yesterday
      expect { @lease.validate_dates }.not_to raise_error
      expect { @lease.save }.not_to raise_error
    end
  end
  describe 'solrizing and saving' do
    before :all do
      @begin_time_field = 'begin_time_dtsi'
      @end_time_field = 'end_time_dtsi'
      @deleted_fields = %w('begin_time_dtsim', 'end_time_dtsim')
      @lenght_of_a_iso8601_time = 20
    end
    it 'can save a lease' do
      expect { lease.save }.not_to raise_error
    end
    it 'can generate a hash of the lease' do
      expect(lease.to_solr.class).to eq(Hash)
    end
    it 'removes multi valued date fields' do
      solr_hash = lease.to_solr
      @deleted_fields.each do |field|
        expect(solr_hash.keys.include? field).to be_falsey
      end
    end
    it 'adds and populates the appriorate dti fields' do
      solr_hash = lease.to_solr
      expect(solr_hash.keys.include? @begin_time_field).to be_truthy
      expect(solr_hash[@begin_time_field].size).to eq(@lenght_of_a_iso8601_time)
      expect(solr_hash.keys.include? @end_time_field).to be_truthy
      expect(solr_hash[@begin_time_field].size).to eq(@lenght_of_a_iso8601_time)
    end
  end
  describe '#lease_type' do
    it 'identifies user lease_type' do
      expect {
        lease.inherited_read_users = [Faker::Internet.email]
        lease.save
      }.to change{Lease.user.count}.by(1)
      expect(lease.lease_type).to eq "user"
    end
    it 'identifies group lease_type' do
      expect {
        lease.inherited_read_groups = [FactoryBot.create(:group).name]
        lease.save
      }.to change{Lease.local.count}.by(1)
      expect(lease.lease_type).to eq "local"
    end
    it 'identifies external_group lease_type' do
      expect {
        lease.inherited_read_groups = ["ExternalGroup"]
        lease.save
      }.to change{Lease.external.count}.by(1)
      expect(lease.lease_type).to eq "external"
    end
    it 'identifies ip lease_type' do
      expect {
        lease.inherited_read_groups = [Faker::Internet.ip_v4_address]
        lease.save
      }.to change{Lease.ip.count}.by(1)
      expect(lease.lease_type).to eq "ip"
    end
  end
  describe '#media_objects' do
    let(:media_object) { FactoryBot.create(:media_object) }
    before do
      media_object.governing_policies += [ lease ]
      media_object.save!
    end
    it 'lists media objects the lease applies to' do
      expect(lease.media_objects).not_to be_empty
    end
  end
end
