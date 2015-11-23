#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Data::Dumper;
use Log::Minimal;

$Log::Minimal::COLOR = 1;

#my $listen_port = 10025;
my $listen_port = 30025;
infof "listen: %s", $listen_port;

my $handle;
AnyEvent::Socket::tcp_server undef, $listen_port, sub {
    my($fh,$client_host, $client_port) = @_;
    if(!$fh){
        die $!;
    }
    infof "new connection. from [%s:%s]", $client_host, $client_port;

    $handle = AnyEvent::Handle->new(
        fh => $fh,
        on_error => sub {warnf "on error";},
        on_eof   => sub {warnf "on eof";},
    );

    #$handle->push_write("Hello \r\n");
    $handle->push_write("220 Hello \r\n");

    read_response($handle);
};

AE::cv->recv;

exit;

sub disconnect {
    my $handle = shift;
    $handle->destroy;
}

sub read_response {
    my $handle = shift;

    my $server_command = command_smtp_server();

    $handle->push_read(line => sub {
            my($handle,$line) = @_;
            my $response = $line;
            infof "recv %s", $response;

            my $res = $server_command->($handle, $response);
            warnf "call read_response";
            read_response($handle);
        });
}

sub read_response2 {
    my $handle = shift;
    $handle->unshift_read(regex => qr/^[.]\r?\n|\n[.]\r?\n/, sub {
            my($handlex,$line) = @_;
            my $response = $line;
            warnf "DATA recv[%s]", $response;
            return;
        });
}

sub command_smtp_server() {
    return sub(){
        my($handle, $response) = @_;
        critf "command[%s]", $response;

        if($response =~ /^EHLO/i){
            $handle->push_write("250 OK\r\n");
        }
        elsif($response =~ /^Mail From:/i){
            $handle->push_write("250 OK\r\n");
        }
        elsif($response =~ /^RCPT TO:/i){
            $handle->push_write("250 OK\r\n");
        }
        elsif($response =~ /^QUIT/i){
            $handle->push_write("250 OK QUIT\r\n");
            disconnect($handle);
        }
        elsif($response =~ /^DATA/i){
            $handle->push_write("354 OK\r\n");
            read_response2($handle);
            $handle->push_write("250 OK DATEEND\r\n");
        }
        else {
            $handle->push_write("550 command:$response\r\n");
        }

        return;
    };
}


