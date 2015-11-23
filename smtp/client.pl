#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Net::SMTP;
use Data::Dumper;

my $smtp = Net::SMTP->new("127.0.0.1",
    Port  => 30025,
    Debug => 1,
);

if(!$smtp){
    die "connection error $!";
}

$smtp->mail('from@example.com');
$smtp->to('to@example.com');
$smtp->data();
$smtp->datasend("Subject: Test\n");
$smtp->datasend("X-MAILER: Test\n");
$smtp->datasend("\n");
$smtp->datasend("body\n");
$smtp->dataend();
$smtp->quit;





