# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

describe SecurityService do
  subject { described_class.new }
  let(:signing_key) {
    <<-HEREDOC
-----BEGIN PRIVATE KEY-----
MIICdgIBADANBgkqhkiG9w0BAQEFAASCAmAwggJcAgEAAoGBALRiMLAh9iimur8V
A7qVvdqxevEuUkW4K+2KdMXmnQbG9Aa7k7eBjK1S+0LYmVjPKlJGNXHDGuy5Fw/d
7rjVJ0BLB+ubPK8iA/Tw3hLQgXMRRGRXXCn8ikfuQfjUS1uZSatdLB81mydBETlJ
hI6GH4twrbDJCR2Bwy/XWXgqgGRzAgMBAAECgYBYWVtleUzavkbrPjy0T5FMou8H
X9u2AC2ry8vD/l7cqedtwMPp9k7TubgNFo+NGvKsl2ynyprOZR1xjQ7WgrgVB+mm
uScOM/5HVceFuGRDhYTCObE+y1kxRloNYXnx3ei1zbeYLPCHdhxRYW7T0qcynNmw
rn05/KO2RLjgQNalsQJBANeA3Q4Nugqy4QBUCEC09SqylT2K9FrrItqL2QKc9v0Z
zO2uwllCbg0dwpVuYPYXYvikNHHg+aCWF+VXsb9rpPsCQQDWR9TT4ORdzoj+Nccn
qkMsDmzt0EfNaAOwHOmVJ2RVBspPcxt5iN4HI7HNeG6U5YsFBb+/GZbgfBT3kpNG
WPTpAkBI+gFhjfJvRw38n3g/+UeAkwMI2TJQS4n8+hid0uus3/zOjDySH3XHCUno
cn1xOJAyZODBo47E+67R4jV1/gzbAkEAklJaspRPXP877NssM5nAZMU0/O/NGCZ+
3jPgDUno6WbJn5cqm8MqWhW1xGkImgRk+fkDBquiq4gPiT898jusgQJAd5Zrr6Q8
AO/0isr/3aa6O6NLQxISLKcPDk2NOccAfS/xOtfOz4sJYM3+Bs4Io9+dZGSDCA54
Lw03eHTNQghS0A==
-----END PRIVATE KEY-----
    HEREDOC
  }

  describe '.rewrite_url' do
    let(:url) { "http://example.com/streaming/id" }
    let(:context) {{ session: {}, target: 'abcd1234', protocol: :stream_hls }}

    context 'when AWS streaming server' do
      before do
        allow(Settings).to receive(:streaming).and_return(double())
        allow(Settings.streaming).to receive(:server).and_return("aws")
        allow(Settings.streaming).to receive(:signing_key).and_return(signing_key)
        allow(Settings.streaming).to receive(:signing_key_id).and_return("signing_key_id")
        allow(Settings.streaming).to receive(:stream_token_ttl).and_return(20)
        allow(Settings.streaming).to receive(:http_base).and_return("http://localhost:3000/streams")
      end
      context 'when hls' do
        it 'changes it into an hls url' do
          expect(subject.rewrite_url(url, context)).to eq "http://localhost:3000/streaming/id"
        end
      end
      context 'when not hls' do
        let(:context) {{ session: {}, target: 'abcd1234', protocol: :stream_dash }}

        it 'returns the url' do
          expect(subject.rewrite_url(url, context)).to eq url
        end
      end
    end

    context 'when non-AWS streaming server' do
      let(:context) {{ target: 'abcd1234', protocol: :stream_hls }}
      before do
        allow(Settings.streaming).to receive(:server).and_return("wowza")
      end
      it 'adds a StreamToken param' do
        expect(subject.rewrite_url(url, context)).to start_with "http://example.com/streaming/id?token="
      end
    end
  end

  describe '.create_cookies' do
    let(:context) {{ target: 'abcd1234', request_host: 'localhost' }}

    context 'when AWS streaming server' do
      before do
        allow(Settings).to receive(:streaming).and_return(double())
        allow(Settings.streaming).to receive(:server).and_return("aws")
        allow(Settings.streaming).to receive(:signing_key).and_return(signing_key)
        allow(Settings.streaming).to receive(:signing_key_id).and_return("signing_key_id")
        allow(Settings.streaming).to receive(:stream_token_ttl).and_return(20)
        allow(Settings.streaming).to receive(:http_base).and_return("http://localhost:3000/streams")
      end

      it 'returns a hash of cookies' do
        cookies = subject.create_cookies(context)
        expect(cookies.first[0]).to eq "CloudFront-Policy"
        expect(cookies.first[1][:path]).to eq "/#{context[:target]}"
        expect(cookies.first[1][:value]).to be_present
        expect(cookies.first[1][:domain]).to be_present
        expect(cookies.first[1][:expires]).to be_present
      end
    end

    context 'when non-AMS streaming server' do
      before do
        allow(Settings.streaming).to receive(:server).and_return("wowza")
      end

      it 'does nothing' do
        expect(subject.create_cookies(context)).to eq({})
      end
    end
  end
end
