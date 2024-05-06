@[Link("minimp3")]
lib Minimp3::LibMinimp3
  MINIMP3_MAX_SAMPLES_PER_FRAME = (1152*2)

  # /* flags for mp3dec_ex_open_* functions */
  MP3D_SEEK_TO_BYTE   = 0 #   /* mp3dec_ex_seek seeks to byte in stream */
  MP3D_SEEK_TO_SAMPLE = 1 #   /* mp3dec_ex_seek precisely seeks to sample using index (created during duration calculation scan or when mp3dec_ex_seek called) */
  MP3D_DO_NOT_SCAN    = 2 #   /* do not scan whole stream for duration if vbrtag not found, mp3dec_ex_t::samples will be filled only if mp3dec_ex_t::vbr_tag_found == 1 */

  # #ifdef MINIMP3_ALLOW_MONO_STEREO_TRANSITION
  # MP3D_ALLOW_MONO_STEREO_TRANSITION = 4
  # MP3D_FLAGS_MASK                   = 7
  MP3D_FLAGS_MASK = 3

  # /* compile-time config */
  MINIMP3_PREDECODE_FRAMES = 2          # /* frames to pre-decode and skip after seek (to fill internal structures) */
  MINIMP3_IO_SIZE          = (128*1024) # /* io buffer size for streaming functions, must be greater than MINIto_decode_BUF_SIZE */
  MINIto_decode_BUF_SIZE   = (16*1024)  # /* buffer which can hold minimum 10 consecutive mp3 frames (~16KB) worst case */
  MINIMP3_ENABLE_RING      = 0          #    /* WIP enable hardware magic ring buffer if available, to make less input buffer memmove(s) in callback IO mode */

  # /* return error codes */
  #
  MP3D_E_PARAM   = -1
  MP3D_E_MEMORY  = -2
  MP3D_E_IOERROR = -3
  MP3D_E_USER    = -4 # /* can be used to stop processing from callbacks without indicating specific error */
  MP3D_E_DECODE  = -5 # /* decode error which can't be safely skipped, such as sample rate, layer and channels change */

  alias Mp3dSampleT = Int16 # Int16 or Float32* ?
  alias P_Mp3dSampleT = Mp3dSampleT*
  alias PP_Mp3dSampleT = P_Mp3dSampleT*

  # typedef struct
  # {
  #     float mdct_overlap[2][9*32], qmf_state[15*2*32];
  #     int reserv, free_format_bytes;
  #     unsigned char header[4], reserv_buf[511];
  # } mp3dec_t;
  #
  @[Extern]
  struct Mp3decT
    mdct_overlap : Float32[2][288]
    qmf_state : Float32[960]
    header : UInt8[4]
    reserv_buf : UInt8[511]
  end

  # typedef struct
  # {
  #     int frame_bytes, frame_offset, channels, hz, layer, bitrate_kbps;
  # } mp3dec_frame_info_t;
  #
  @[Extern]
  struct Mp3decFrameInfoT
    frame_bytes, frame_offset, channels, hz, layer, bitrate_kbps : Int32
  end

  # typedef struct
  # {
  #     mp3d_sample_t *buffer;
  #     size_t samples; /* channels included, byte size = samples*sizeof(mp3d_sample_t) */
  #     int channels, hz, layer, avg_bitrate_kbps;
  # } mp3dec_file_info_t;
  #
  @[Extern]
  struct Mp3decFileInfoT
    buffer : P_Mp3dSampleT
    samples : LibC::SizeT # channels included, byte size = samples*sizeof(mp3d_sample_t)
    channels, hz, layer, avg_bitrate_kbps : Int32
  end

  # size_t (*MP3D_READ_CB)(void *buf, size_t size, void *user_data);
  #
  alias Mp3dReadCB = Void*, LibC::SizeT, Void* -> LibC::SizeT

  # typedef int (*MP3D_SEEK_CB)(uint64_t position, void *user_data);
  #
  alias Mp3dSeekCB = UInt64, Void* -> Int32

  # typedef int (*MP3D_ITERATE_CB)(void *user_data, const uint8_t *frame, int frame_size, int free_format_bytes, size_t buf_size, uint64_t offset, mp3dec_frame_info_t *info);
  #
  alias Mp3dIterateCB = Void*, UInt8*, Int32, Int32, LibC::SizeT, UInt64, Mp3decFrameInfoT* -> Int32

  # typedef int (*MP3D_PROGRESS_CB)(void *user_data, size_t file_size, uint64_t offset, mp3dec_frame_info_t *info);
  #
  alias Mp3dProgressCB = Void*, LibC::SizeT, UInt64, Mp3decFrameInfoT* -> Int32

  # typedef struct
  # {
  #     MP3D_READ_CB read;
  #     void *read_data;
  #     MP3D_SEEK_CB seek;
  #     void *seek_data;
  # } mp3dec_io_t;
  #
  @[Extern]
  struct Mp3decIoT
    read : Mp3dReadCB
    read_data : Void*
    seek : Mp3dSeekCB
    seek_data : Void*
  end

  # void mp3dec_init(mp3dec_t *dec);
  # int mp3dec_decode_frame(mp3dec_t *dec, const uint8_t *mp3, int mp3_bytes, mp3d_sample_t *pcm, mp3dec_frame_info_t *info);
  #
  fun init = mp3dec_init(dec : Mp3decT*)
  fun decode_frame = mp3dec_decode_frame(dec : Mp3decT*, mp3 : UInt8*, mp3_bytes : Int32, pcm : Mp3dSampleT*, info : Mp3decFrameInfoT*) : Int32

  # /* detect mp3/mpa format */
  # int mp3dec_detect_buf(const uint8_t *buf, size_t buf_size);
  # int mp3dec_detect_cb(mp3dec_io_t *io, uint8_t *buf, size_t buf_size);
  #
  fun detect_buf = mp3dec_detect_buf(buf : UInt8*, buf_size : LibC::SizeT) : Int32
  fun detect_cb = mp3dec_detect_cb(io : Mp3decIoT*, buf : UInt8*, buf_size : LibC::SizeT) : Int32

  # /* decode whole buffer block */
  # int mp3dec_load_buf(mp3dec_t *dec, const uint8_t *buf, size_t buf_size, mp3dec_file_info_t *info, MP3D_PROGRESS_CB progress_cb, void *user_data);
  # int mp3dec_load_cb(mp3dec_t *dec, mp3dec_io_t *io, uint8_t *buf, size_t buf_size, mp3dec_file_info_t *info, MP3D_PROGRESS_CB progress_cb, void *user_data);
  #
  fun load_buf = mp3dec_load_buf(dec : Mp3decT*, buf : UInt8*, buf_size : LibC::SizeT, info : Mp3decFileInfoT*, progress_cb : Mp3dProgressCB, user_data : Void*) : Int32
  fun load_cb = mp3dec_load_cb(dec : Mp3decT*, io : Mp3decIoT*, buf : UInt8*, buf_size : LibC::SizeT, info : Mp3decFileInfoT*, progress_cb : Mp3dProgressCB, user_data : Void*) : Int32

  # /* iterate through frames */
  # int mp3dec_iterate_buf(const uint8_t *buf, size_t buf_size, MP3D_ITERATE_CB callback, void *user_data);
  # int mp3dec_iterate_cb(mp3dec_io_t *io, uint8_t *buf, size_t buf_size, MP3D_ITERATE_CB callback, void *user_data);
  #
  fun iterate_buf = mp3dec_iterate_buf(buf : UInt8*, buf_size : LibC::SizeT, callback : Mp3dIterateCB, user_data : Void*) : Int32
  fun iterate_cb = mp3dec_iterate_cb(io : Mp3decIoT*, buf : UInt8*, buf_size : LibC::SizeT, callback : Mp3dIterateCB, user_data : Void*) : Int32

  # typedef struct
  # {
  #     mp3dec_t mp3d;
  #     mp3dec_map_info_t file;
  #     mp3dec_io_t *io;
  #     mp3dec_index_t index;
  #     uint64_t offset, samples, detected_samples, cur_sample, start_offset, end_offset;
  #     mp3dec_frame_info_t info;
  #     mp3d_sample_t buffer[MINIMP3_MAX_SAMPLES_PER_FRAME];
  #     size_t input_consumed, input_filled;
  #     int is_file, flags, vbr_tag_found, indexes_built;
  #     int free_format_bytes;
  #     int buffer_samples, buffer_consumed, to_skip, start_delay;
  #     int last_error;
  # } mp3dec_ex_t;
  #
  @[Extern]
  struct Mp3decExT
    mp3d : Mp3decT
    file : Mp3decMapInfoT
    io : Mp3decIoT*
    index : Mp3decIndexT
    offset, samples, detected_samples, cur_sample, start_offset, end_offset : UInt64
    info : Mp3decFrameInfoT
    buffer : Mp3dSampleT[MINIMP3_MAX_SAMPLES_PER_FRAME]
    input_consumed, input_filled : LibC::SizeT
    is_file, flags, vbr_tag_found, indexes_built : Int32
    free_format_bytes : Int32
    buffer_samples, buffer_consumed, to_skip, start_delay : Int32
    last_error : Int32
  end

  # typedef struct
  # {
  #     const uint8_t *buffer;
  #     size_t size;
  # } mp3dec_map_info_t;
  #
  @[Extern]
  struct Mp3decMapInfoT
    buffer : UInt8*
    size : LibC::SizeT
  end

  # typedef struct
  # {
  #     uint64_t sample;
  #     uint64_t offset;
  # } mp3dec_frame_t;
  #
  @[Extern]
  struct Mp3decFrameT
    sample : UInt64
    offset : UInt64
  end

  # typedef struct
  # {
  #    mp3dec_frame_t *frames;
  #    size_t num_frames, capacity;
  # } mp3dec_index_t;
  #
  @[Extern]
  struct Mp3decIndexT
    frames : Mp3decFrameT
    num_frames, capacity : LibC::SizeT
  end

  # /* streaming decoder with seeking capability */
  # int mp3dec_ex_open_buf(mp3dec_ex_t *dec, const uint8_t *buf, size_t buf_size, int flags);
  # int mp3dec_ex_open_cb(mp3dec_ex_t *dec, mp3dec_io_t *io, int flags);
  # void mp3dec_ex_close(mp3dec_ex_t *dec);
  # int mp3dec_ex_seek(mp3dec_ex_t *dec, uint64_t position);
  # size_t mp3dec_ex_read_frame(mp3dec_ex_t *dec, mp3d_sample_t **buf, mp3dec_frame_info_t *frame_info, size_t max_samples);
  # size_t mp3dec_ex_read(mp3dec_ex_t *dec, mp3d_sample_t *buf, size_t samples);
  #
  fun ex_open_buf = mp3dec_ex_open_buf(dec : Mp3decExT*, buf : UInt8*, buf_size : LibC::SizeT, flags : Int32) : Int32
  fun ex_open_cb = mp3dec_ex_open_cb(dec : Mp3decExT*, io : Mp3decIoT*, flags : Int32) : Int32
  fun ex_close = mp3dec_ex_close(dec : Mp3decExT*)
  fun ex_seek = mp3dec_ex_seek(dec : Mp3decExT*, position : UInt64) : Int32
  fun ex_read_frame = mp3dec_ex_read_frame(dec : Mp3decExT*, buf : PP_Mp3dSampleT, frame_info : Mp3decFrameInfoT*, max_samples : LibC::SizeT) : LibC::SizeT
  fun ex_read = mp3dec_ex_read(dec : Mp3decExT*, buf : P_Mp3dSampleT, samples : LibC::SizeT) : LibC::SizeT

  # #ifndef MINIMP3_NO_STDIO
  # /* stdio versions of file detect, load, iterate and stream */
  # int mp3dec_detect(const char *file_name);
  # int mp3dec_load(mp3dec_t *dec, const char *file_name, mp3dec_file_info_t *info, MP3D_PROGRESS_CB progress_cb, void *user_data);
  # int mp3dec_iterate(const char *file_name, MP3D_ITERATE_CB callback, void *user_data);
  # int mp3dec_ex_open(mp3dec_ex_t *dec, const char *file_name, int flags);
  # #ifdef _WIN32
  # int mp3dec_detect_w(const wchar_t *file_name);
  # int mp3dec_load_w(mp3dec_t *dec, const wchar_t *file_name, mp3dec_file_info_t *info, MP3D_PROGRESS_CB progress_cb, void *user_data);
  # int mp3dec_iterate_w(const wchar_t *file_name, MP3D_ITERATE_CB callback, void *user_data);
  # int mp3dec_ex_open_w(mp3dec_ex_t *dec, const wchar_t *file_name, int flags);
  # #endif
  # #endif
  #
  {% if !flag?(:win32) %}
    fun detect_file = mp3dec_detect(file_name : UInt8*) : Int32
    fun load_file = mp3dec_load(dec : Mp3decT*, file_name : UInt8*, info : Mp3decFileInfoT*, progress_cb : Mp3dProgressCB, user_data : Void*) : Int32
    fun Iterable_file = mp3dec_iterate(file_name : UInt8*, callback : Mp3dIterateCB, user_data : Void*) : Int32
    fun ex_open_file = mp3dec_ex_open(dec : Mp3decExT*, file_name : UInt8*, flags : Int32) : Int32
  {% end %}

  {% if flag?(:win32) %}
    fun detect_file = mp3dec_detect_w(file_name : LibC::LPWSTR) : Int32
    fun load_file = mp3dec_load_w(dec : Mp3decT*, file_name : LibC::LPWSTR, info : Mp3decFileInfoT*, progress_cb : Mp3dProgressCB, user_data : Void*) : Int32
    fun iterate_file = mp3dec_iterate_w(file_name : LibC::LPWSTR, callback : Mp3dIterateCB, user_data : Void*) : Int32
    fun ex_open_file = mp3dec_ex_open_w(dec : Mp3decExT*, file_name : LibC::LPWSTR, flags : Int32) : Int32
  {% end %}
end

module Minimp3
  ONE_SAMPLE_BYTES = sizeof(LibMinimp3::Mp3dSampleT)

  class Error < Exception
  end

  enum ErrnoKind
    Unkown
    Param
    Memory
    IO
    User   # can be used to stop processing from callbacks without indicating specific error
    Decode #  decode error which can't be safely skipped, such as sample rate, layer and channels change
  end

  class ErrnoError < Error
    def initialize(@errno)
      @errno_kind = case @errno
                    when -1
                      ErrnoKind::Param
                    when -2
                      ErrnoKind::Memory
                    when -3
                      ErrnoKind::IO
                    when -4
                      ErrnoKind::User
                    when -5
                      ErrnoKind::Decode
                    else
                      ErrnoKind::Unkown
                    end
    end
  end
end

record Minimp3::Frame,
  data_buf : Bytes,
  frame_offset : UInt32,
  frame_bytes : UInt32,
  layer : UInt32,
  channels : UInt32,
  samples : UInt32,
  sample_rate : UInt32,
  bit_rate : UInt32 do
  # exact_samples = channels * samples
  #
  @[AlwaysInline]
  def exact_samples : UInt32
    channels * samples
  end

  # exact_samples_bytes = channels * samples * ONE_SAMPLE_BYTES
  #
  @[AlwaysInline]
  def exact_samples_bytes : UInt32
    exact_samples * ONE_SAMPLE_BYTES
  end

  @[AlwaysInline]
  def self.from_decode_result(pcm_buf, frame_info, samples)
    exact_samples_bytes = frame_info.channels * samples * ONE_SAMPLE_BYTES
    Frame.new(
      data_buf: Bytes.new(pcm_buf.to_unsafe.as(UInt8*), exact_samples_bytes),
      frame_offset: frame_info.frame_offset.to_u32,
      frame_bytes: frame_info.frame_bytes.to_u32,
      layer: frame_info.layer.to_u32,
      channels: frame_info.channels.to_u32,
      samples: samples.to_u32,
      sample_rate: frame_info.hz.to_u32,
      bit_rate: frame_info.bitrate_kbps.to_u32 * 1000
    )
  end
end

class Minimp3::Decoder
  include Iterable(Frame)

  def initialize(@reader : IO)
  end

  def each
    FrameIterator.new(@reader)
  end

  # detect file if can decode
  #
  def self.can_decode?(file : String) : Bool
    {% if flag?(:win32) %}
      LibMinimp3.detect_file(file.to_utf16) == 0
    {% else %}
      LibMinimp3.detect_file(file) == 0
    {% end %}
  end

  # detect buffer if can decode
  #
  def self.can_decode?(buf : Bytes) : Bool
    LibMinimp3.detect_buf(buf, buf.size) == 0
  end

  # read data from `IO` to decode them and call callback with `decoded data (aka. pcm data)` and `frame info`
  #
  def self.decode(io : IO, callback : Frame ->)
    dec = Pointer(LibMinimp3::Mp3decT).malloc(1)
    LibMinimp3.init(dec)

    pcm_buf = Slice(LibMinimp3::Mp3dSampleT).new(LibMinimp3::MINIMP3_MAX_SAMPLES_PER_FRAME)

    to_decode_buf = Bytes.new(16 * 1024)
    to_decode_size = 0
    last_loop_decoded_size = 0

    loop do
      to_decode_size -= last_loop_decoded_size

      # to_decode_buf compact
      #
      if last_loop_decoded_size > 0
        move_pos = last_loop_decoded_size
        move_size = to_decode_size
        to_decode_buf.to_unsafe.move_from(to_decode_buf.to_unsafe + move_pos, move_size)
      end

      # fill to_decode_buf from io
      #
      to_read_pos = to_decode_size
      to_read_size = to_decode_buf.size - to_decode_size
      to_read_buf = Bytes.new(to_decode_buf.to_unsafe + to_read_pos, to_read_size)
      to_decode_size += io.read(to_read_buf)

      # end
      #
      if to_decode_size == 0
        puts "EOF and not buffer to decode, return"
        return
      end

      # decode
      #
      frame_info = uninitialized LibMinimp3::Mp3decFrameInfoT
      samples = LibMinimp3.decode_frame(dec, to_decode_buf, to_decode_size, pcm_buf, pointerof(frame_info))

      last_loop_decoded_size = frame_bytes = frame_info.frame_bytes
      if samples == 0 && frame_bytes == 0
        # end
        #
        puts "No samples, return"
        return
      elsif samples == 0 && frame_bytes > 0
        # puts "ID3 data" + ("."*66)
        #
        next
      elsif samples > 0 && frame_bytes > 0
        # call callback
        #
        frame = Frame.from_decode_result(pcm_buf, frame_info, samples)
        callback.call(frame)
      else
        raise Error.new("Unexpeced decode result:  samples: #{samples}, frame_bytes: #{frame_bytes}")
      end
    end
  end
end

class Minimp3::FrameIterator
  include Iterator(Frame)

  def initialize(@reader : IO)
    @dec = Pointer(LibMinimp3::Mp3decT).malloc(1)
    LibMinimp3.init(@dec)

    @to_decode_buf = Bytes.new(16 * 1024)
    @to_decode_size = 0
    @last_loop_decoded_size = 0
  end

  def next
    pcm_buf = Slice(LibMinimp3::Mp3dSampleT).new(LibMinimp3::MINIMP3_MAX_SAMPLES_PER_FRAME)

    loop do
      @to_decode_size -= @last_loop_decoded_size

      # to_decode_buf compact
      #
      if @last_loop_decoded_size > 0
        move_pos = @last_loop_decoded_size
        move_size = @to_decode_size
        @to_decode_buf.to_unsafe.move_from(@to_decode_buf.to_unsafe + move_pos, move_size)
      end

      # fill to_decode_buf from io
      #
      to_read_pos = @to_decode_size
      to_read_size = @to_decode_buf.size - @to_decode_size
      to_read_buf = Bytes.new(@to_decode_buf.to_unsafe + to_read_pos, to_read_size)
      @to_decode_size += @reader.read(to_read_buf)

      # end
      #
      return stop unless @to_decode_size > 0

      # decode
      #
      frame_info = uninitialized LibMinimp3::Mp3decFrameInfoT
      samples = LibMinimp3.decode_frame(@dec, @to_decode_buf, @to_decode_size, pcm_buf, pointerof(frame_info))

      @last_loop_decoded_size = frame_bytes = frame_info.frame_bytes
      if samples == 0 && frame_bytes == 0
        return stop
      elsif samples == 0 && frame_bytes > 0
        next
      elsif samples > 0 && frame_bytes > 0
        return Frame.from_decode_result(pcm_buf, frame_info, samples)
      else
        raise Error.new("Unexpeced decode result:  samples: #{samples}, frame_bytes: #{frame_bytes}")
      end
    end
  end
end
