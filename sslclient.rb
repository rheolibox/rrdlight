#!/usr/bin/env ruby

require 'socket'

s = TCPSocket.new 'localhost', 4443

pkt = []
pkt += [22] # Handshake
pkt += [03, 03] # TLS 1.0
pkt += [00, 0x4f] # length
pkt += [01] # Handshake Type CLIENT_HELLO
pkt += [00, 00, 0x4b] # length
pkt += [03, 01] # TLS 1.2
#pkt += [0xe4, 0x51, 0x56, 0xd6] # Random(1) Time
pkt += [0x53, 0x18, 0x98, 0x31] # Random(1) Time
pkt += [0x07, 0x5d, 0x22, 0x3b, 0x66, 0x9b, 0x22, 0x2d, 0xf6, 0xb9,
        0x0c, 0x3c, 0x0d, 0x69, 0x08, 0xfb, 0x2e, 0x8c, 0x3d, 0xa3,
        0xad, 0xb2, 0x46, 0x52, 0xaf, 0x55, 0x45, 0x85] # Random Random
pkt += [ 0 ] # Session ID Length
pkt += [0, 0x14] # Cipher Suite Length
pkt += [0,5, 0,0x3c, 0,0x35, 0,0x0a, 0,0x2f, 0,0x3d,0xc0,0x13,0xc0,0x14,
        0xc0,0x12,0,0xff ] # Cipher Suites
pkt += [1] # Compression Method length
pkt += [0] # Compression Method nul
pkt += [0, 0xe] # Extension Length
pkt += [0, 0x0a, 0, 4, 0, 2, 0, 0x17] # EC Curves
pkt += [0, 0xb, 0, 2, 1, 0] # ec_point_format

stream = ""
pkt.each do |v|
  stream += v.chr
end

s.write stream
while 1
  begin # emulate blocking recv.
    p s.recv_nonblock(10) #=> "aaa"
  rescue IO::WaitReadable
    IO.select([s])
  end
end



s.close     
