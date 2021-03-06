require 'rubygems'
require 'set'
require 'net/http'
require 'net/https'
require 'pp'
require 'exifr'
require 'tempfile'
require 'test/unit'
require 'mocha'
require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")

begin require 'redgreen'; rescue LoadError; end

module MMS2R
  module TestHelper

    def assert_file_size(file, size)
      assert_not_nil(file, "file was nil")
      assert(File::exist?(file), "file #{file} does not exist")
      assert(File::size(file) == size, "file #{file} is #{File::size(file)} bytes, not #{size} bytes")
    end

    def mail_fixture(file)
      "#{File.dirname(__FILE__)}/fixtures/#{file}"
    end

    def mail(name)
      Mail.read(mail_fixture(name))
    end

    def smart_phone_mock(model_text = 'iPhone', jpeg = true)
      mail = mock('mail')
      mail.expects(:from).at_least_once.returns(['joe@example.com'])
      mail.expects(:return_path).at_least_once.returns('<joe@example.com>')
      mail.expects(:message_id).returns('abcd0123')
      mail.expects(:multipart?).returns(true)

      part = mock('part')
      part.expects(:part_type?).at_least_once.returns("image/#{jpeg ? 'jpeg' : 'tiff'}")
      part.expects(:body).at_least_once.returns(Mail::Body.new('abc'))
      part.expects(:multipart?).at_least_once.returns(false)
      part.expects(:filename).returns("foo.#{jpeg ? 'jpg' : 'tif'}")

      mail.expects(:parts).returns([part])
      exif = mock('exif')
      exif.expects(:model).at_least_once.returns(model_text)
      if jpeg
        EXIFR::JPEG.expects(:new).at_least_once.returns(exif)
      else
        EXIFR::TIFF.expects(:new).at_least_once.returns(exif)
      end
      mail
    end
  end
end

class Hash
  def except(*keys)
    rejected = Set.new(respond_to?(:convert_key) ? keys.map { |key| convert_key(key) } : keys)
    reject { |key,| rejected.include?(key) }
  end

  def except!(*keys)
    replace(except(*keys))
  end
end

# monkey patch Net::HTTP so un caged requests don't go over the wire
module Net #:nodoc:
  class HTTP #:nodoc:
    alias :old_net_http_request :request
    alias :old_net_http_connect :connect

    def request(req, body = nil, &block)
      prot = use_ssl ? "https" : "http"
      uri_cls = use_ssl ? URI::HTTPS : URI::HTTP
      query = req.path.split('?',2)
      opts = {:host => self.address,
             :port => self.port, :path => query[0]}
      opts[:query] = query[1] if query[1]
      uri = uri_cls.build(opts)
      raise ArgumentError.new("#{req.method} method to #{uri} not being handled in testing")
    end

    def connect
      raise ArgumentError.new("connect not being handled in testing")
    end

  end
end
