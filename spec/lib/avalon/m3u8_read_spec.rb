require 'avalon/m3u8_reader'

describe Avalon::M3U8Reader do
  let(:m3u_file)  { File.expand_path('../../../fixtures/The_Fox.mp4.m3u',__FILE__) }
  let(:m3u)       { Avalon::M3U8Reader.read(m3u_file) }
  let(:framespec) { m3u.at(127000) }

  it "should know how many files it has" do
    expect(m3u.files.length).to eq(23)
  end

  it "should know its duration" do
    expect(m3u.duration.round(2)).to eq(225.14)
  end

  it "should be able to locate a frame" do
    expect(framespec[:location]).to match(%r{/The_Fox.mp4-012.ts$})
    expect(framespec[:filename]).to eq('The_Fox.mp4-012.ts')
    expect(framespec[:offset].round(2)).to eq(6818.91)
  end
end
