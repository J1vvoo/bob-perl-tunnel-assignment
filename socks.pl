#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;
use IO::Select;

# SOCKS5 proxy server implementation
# Listens on 127.0.0.1:1080 and forwards traffic to internal services

my $socks_port = 1080;
my $socks_host = '127.0.0.1';

# Create SOCKS5 server socket
my $server = IO::Socket::INET->new(
    LocalHost => $socks_host,
    LocalPort => $socks_port,
    Proto     => 'tcp',
    Listen    => 5,
    Reuse     => 1
) or die "Cannot create server socket: $!";

print "SOCKS5 proxy server started on $socks_host:$socks_port\n";

# Main server loop
while (my $client = $server->accept()) {
    print "New client connected: " . $client->peerhost() . "\n";
    
    # Handle each client in a separate process
    if (fork() == 0) {
        handle_client($client);
        exit(0);
    }
    $client->close();
}

sub handle_client {
    my ($client) = @_;
    
    # SOCKS5 handshake
    my $version = $client->sysread(my $buf, 2);
    return unless $version == 2;
    
    my ($ver, $nmethods) = unpack('CC', $buf);
    return unless $ver == 5;  # SOCKS5
    
    # Read authentication methods
    $client->sysread($buf, $nmethods);
    
    # Send response: no authentication required
    $client->syswrite(pack('CC', 5, 0));
    
    # Read command request
    $client->sysread($buf, 4);
    my ($ver2, $cmd, $rsv, $atyp) = unpack('CCCC', $buf);
    return unless $ver2 == 5 && $cmd == 1;  # CONNECT command
    
    # Read destination address
    my $dst_addr;
    my $dst_port;
    
    if ($atyp == 1) {  # IPv4
        $client->sysread($buf, 4);
        $dst_addr = join('.', unpack('CCCC', $buf));
        $client->sysread($buf, 2);
        $dst_port = unpack('n', $buf);
    } elsif ($atyp == 3) {  # Domain name
        $client->sysread($buf, 1);
        my $domain_len = unpack('C', $buf);
        $client->sysread($buf, $domain_len);
        $dst_addr = $buf;
        $client->sysread($buf, 2);
        $dst_port = unpack('n', $buf);
    } else {
        # Unsupported address type
        $client->syswrite(pack('CCCC', 5, 8, 0, 1) . pack('NN', 0, 0));
        return;
    }
    
    print "Connecting to $dst_addr:$dst_port\n";
    
    # Connect to destination
    my $remote = IO::Socket::INET->new(
        PeerHost => $dst_addr,
        PeerPort => $dst_port,
        Proto    => 'tcp',
        Timeout  => 10
    );
    
    if (!$remote) {
        # Connection failed
        $client->syswrite(pack('CCCC', 5, 4, 0, 1) . pack('NN', 0, 0));
        return;
    }
    
    # Send success response
    my $client_addr = $client->sockaddr();
    my ($port, $addr) = unpack_sockaddr_in($client_addr);
    $client->syswrite(pack('CCCC', 5, 0, 0, 1) . pack('NN', $addr, $port));
    
    # Start forwarding data
    my $sel = IO::Select->new($client, $remote);
    
    while (my @ready = $sel->can_read()) {
        foreach my $fh (@ready) {
            my $other = ($fh == $client) ? $remote : $client;
            my $data;
            my $bytes = $fh->sysread($data, 4096);
            
            if ($bytes <= 0) {
                $client->close();
                $remote->close();
                return;
            }
            
            $other->syswrite($data);
        }
    }
}

# Helper function for address unpacking
sub unpack_sockaddr_in {
    my ($sockaddr) = @_;
    my ($port, $addr) = unpack_sockaddr_in($sockaddr);
    return ($port, $addr);
}




