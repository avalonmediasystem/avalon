# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

describe LanguageTerm, type: :model do
  describe "::Iso6391" do
    describe ".convert_to_6392" do
      it "takes an alpha2 code and returns the matching alpha3 code" do
        expect(LanguageTerm::Iso6391.convert_to_6392('en')).to eq 'eng'
        # 'es' returns 'Spanish | Castilian', matches on 'Spanish'
        expect(LanguageTerm::Iso6391.convert_to_6392('es')).to eq 'spa'
        # 'gd' returns 'Gaelic | Scottish Gaelic', matches on 'Scottish Gaelic'
        expect(LanguageTerm::Iso6391.convert_to_6392('gd')).to eq 'gla'
      end

      it "returns a lookup error if there is not a match" do
        expect { LanguageTerm::Iso6391.convert_to_6392("ac") }.to raise_error(LanguageTerm::LookupError)
      end

      it "returns a lookup error if input does not equal 2 alphabetic characters" do
        expect { LanguageTerm::Iso6391.convert_to_6392("a") }.to raise_error(LanguageTerm::LookupError)
        expect { LanguageTerm::Iso6391.convert_to_6392("zebra") }.to raise_error(LanguageTerm::LookupError)
        expect { LanguageTerm::Iso6391.convert_to_6392("35") }.to raise_error(LanguageTerm::LookupError)
        expect { LanguageTerm::Iso6391.convert_to_6392("a.") }.to raise_error(LanguageTerm::LookupError)
      end
    end
  end

  context ".find" do
    it "returns correct entry for plain text search" do
      expect(described_class.find("Scottish Gaelic").instance_variable_get(:@term)).to eq({ :code=>"gla", :text=>"Scottish Gaelic", :uri=>"http://id.loc.gov/vocabulary/languages/gla" })
    end

    it "returns correct entry for code search" do
      expect(described_class.find("spa").instance_variable_get(:@term)).to eq( {:code=>"spa", :text=>"Spanish", :uri=>"http://id.loc.gov/vocabulary/languages/spa"} )
    end

    it "raises LookupError for terms not in the vocabulary" do
      expect { described_class.find("zebra") }.to raise_error(LanguageTerm::LookupError)
    end
  end
end