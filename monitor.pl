#!/usr/bin/env perl

#
# Copyright (C) 2019  Sergio Iglesias
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

$|=1;

use strict;
use warnings;
use feature qw(say);

use Digest::file qw(digest_file);
use Email::MIME;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP::TLS;
use POSIX qw(strftime);

############################################ default settings ############################################
my $email_from     = '';
my $email_to       = '';
my $email_subject  = 'Directory Monitor';
my $smtp_host      = 'smtp.gmail.com';
my $smtp_port      = 587;
my $smtp_username  = '',
my $smtp_password  = '';
##########################################################################################################

$SIG{INT} = sub {
  die("Exit...\n");
};

my $dir = $ARGV[0] or die "No file received\nUsage: $0 <file/dir>\n";
-e $dir or die "No such file\n";
-d $dir or die "Not a dir\n";

my %db_files;

while (1) {
  sleep 0.5;
  Monitor($dir);
}

sub Monitor {
  my $path = shift;
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); $year = $year+1900; $mon = $mon+1;
  my $datetime = sprintf "%04d-%02d-%02d %02d:%02d:%02d",($year,$mon,$mday,$hour,$min,$sec);
  my %old_hash = %db_files;
  my %changes;
  %db_files = ();
  Index_dir($path);
  if (%old_hash) {
    for (keys %db_files) {
      $old_hash{$_} or do {$changes{$_} = 'Created:'; next};
      $old_hash{$_} eq $db_files{$_} or $changes{$_} = 'Modified:';
    }
    for (keys %old_hash) {
      $db_files{$_} or $changes{$_} = 'Removed:';
    }
  }
  %changes and say $datetime;
  for (keys %changes) {
    say "$changes{$_} $_";
    Send_Mail("$datetime - $changes{$_} $_");
  }
}

sub Index_dir {
  my $path = shift;
  opendir(my $dh, $path);
    my @contents = readdir $dh;
    for (@contents) {
      my $file = "$path/$_";
      /^\.{1,2}$/ and next;
      $file =~ s/\/+/\//g;
      -f $file and $db_files{$file} = digest_file($file, 'MD5');
      -d $file and Index_dir($file);
    }
  closedir $dh;
}

sub Send_Mail {
  my $body = shift;

  my $email_object = Email::MIME->create(
    header => [
      From         => $email_from,
      To           => $email_to,
      Subject      => $email_subject,
      content_type => 'multipart/mixed'
    ],
    attributes => {
      content_type => "text/html",
      charset      => "ISO-8859-1",
    },
    body => "$body\n",
  );
  
  my $transport = Email::Sender::Transport::SMTP::TLS->new(
    host     => $smtp_host,
    port     => $smtp_port,
    username => $smtp_username,
    password => $smtp_password
  );
  
  sendmail( $email_object, {transport => $transport} );
}
