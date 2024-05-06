require "../lib/libao/src/libao"
include Libao

require "../src/minimp3"

def decode_and_play(file : String)
  ao = Ao.new
  first = true

  begin
    File.open(file) do |io|
      Minimp3::Decoder.new(io).each.each do |frame|
        if first
          first = false
          ao.set_format(Minimp3::ONE_SAMPLE_BYTES * 8, frame.sample_rate, frame.channels, LibAO::Byte_Format::AO_FMT_BIG, matrix = nil)
          ao.open_live
        end
        if ao.play(frame.data_buf, frame.data_buf.size) == 0
          raise "Failed to play"
        end
      end
    end
  ensure
    ao.close
  end
end

file = "#{__DIR__}/../test.mp3"
decode_and_play file
