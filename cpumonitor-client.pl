#!/usr/bin/perl -w
use strict;
use Socket;

my $host_or_IP = shift @ARGV || "localhost";
my $port = shift @ARGV || "12321";
my $message = shift @ARGV || "hello hello hello\n";

socket (my $remote, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or die "socket: $!\n";

my $mini_addr = inet_aton ($host_or_IP) or die "inet_aton: $!\n";
my $packed_addr = sockaddr_in ($port, $mini_addr) or die "sockaddr_in $!\n";

connect ($remote, $packed_addr) or die "connect: $!\n";

select((select($remote), $|=1)[0]);

# The client's only responsobility is to send the first line of it's /proc/stat to the server
# (Every second)
while (1) {
    open (my $fh, "<", "/proc/stat") or die "open: $!\n";
    while (<$fh>) {print $remote $_; last;}
    sleep 1;
}
