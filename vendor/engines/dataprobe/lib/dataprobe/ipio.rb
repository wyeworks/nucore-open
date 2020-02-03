# frozen_string_literal: true

module Dataprobe

  class Ipio

    CONNECT_TIMEOUT = 5
    READ_TIMEOUT = 5
    WRITE_TIMEOUT = 5

    attr_reader :ip, :port
    attr_accessor :username, :password

    def initialize(host, options = {})
      @ip = host
      @port = 9100
      @username = (options[:username].presence || "user").ljust(21, "\x00")
      @password = (options[:password].presence || "user").ljust(21, "\x00")
    end

    def toggle(outlet, status)
      with_connection do |socket, message_number|
        mode = status ? 1 : 0
        write(socket, "#{authentication_prefix}\x01\x00#{message_number}#{hex_s outlet}#{hex_s mode}")
        raise Dataprobe::Error.new("Error while toggling outlet #{outlet}") unless read(socket, 1) == "\x00"
        status
      end
    end

    def status(outlet)
      with_connection do |socket, message_number|
        write(socket, "#{authentication_prefix}\x04\x00#{message_number}")
        statuses = read(socket, 100).unpack("C*")
        statuses[outlet - 1] == 1
      end
    end

    private

    def with_connection(&block)
      socket = Socket.tcp(ip, port, connect_timeout: CONNECT_TIMEOUT)
      write(socket, "hello-000\x00")
      sequence_number = read(socket, 2).unpack("s<")
      sequence_number[0] += 1
      block.call(socket, sequence_number.pack("s<"))
    ensure
      socket.close
    end

    def write(socket, string)
      socket.write_nonblock(string)
    rescue IO::WaitWritable
      IO.select(nil, [socket], nil, WRITE_TIMEOUT)
      retry
    end

    def read(socket, bytes)
      socket.read_nonblock(bytes)
    rescue IO::WaitReadable
      IO.select([socket], nil, nil, READ_TIMEOUT)
      retry
    end

    def authentication_prefix
      "\x03#{username}#{password}"
    end

    def hex_s(int)
      [int].pack "C"
    end

  end

end
