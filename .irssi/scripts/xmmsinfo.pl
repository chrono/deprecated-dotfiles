#!/usr/bin/perl

# $Id: xmmsinfo.pl,v 1.1.1.1 2002/03/24 21:00:55 tj Exp $
#
# Copyright (0) 2002 Tuomas Jormola <tjormola@cc.hut.fi
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# The complete text of the GNU General Public License can be found
# on the World Wide Web: <URL:http://www.gnu.org/licenses/gpl.html>
#
# $Log: xmmsinfo.pl,v $
# Revision 1.1.1.1  2002/03/24 21:00:55  tj
# Initial import.
#
#
# TODO:
# * Configurable string to print (%t = title, %a = artist ...)

use strict;
use Irssi;
use XMMSInfo;
use vars qw($VERSION %IRSSI);

# global variables
$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /^.+?(\d+)\.(\d+)/);
%IRSSI = (
	authors		=> 'Tuomas Jormola',
	contact		=> 'tjormola@cc.hut.fi',
	name		=> 'XMMSInfo',
	description	=> '/xmmsinfo to tell what you\'re currently playing',
	license		=> 'GPLv2',
	url			=> 'http://shakti.tky.hut.fi/stuff.xml#irssi',
	changed		=> '2002-0324T22:42+0300',
);

if(runningUnderIrssi()) {
	Irssi::settings_add_str('misc', 'xmms_info_pipe', '/tmp/xmms-info');
	Irssi::command_bind('xmmsinfo', 'commandXmmsInfo');
	Irssi::print("$IRSSI{name} $VERSION loaded, /xmmsinfo -help");
} else {
	(my $s = $0) =~ s/.*\///;
	$ARGV[0] || die("Usage: $s <file>\n");
	commandXmmsInfo();
}

# command handler
sub commandXmmsInfo {
	my($args, $server, $target) = @_;

	if(lc($args) eq "-help") {
		Irssi::print("XMMSInfo $VERSION by $IRSSI{authors} <$IRSSI{contact}>");
		Irssi::print("");
		Irssi::print("Displays what your XMMS is playing using information");
		Irssi::print("provided by the XMMS InfoPipe plugin");
		Irssi::print("<URL:www.iki.fi/wwwwolf/code/xmms/infopipe.html");
		Irssi::print("");
		Irssi::print("Usage: /xmmsinfo [TARGET]");
		Irssi::print("If TARGET is given, the info is sent there, othwerwise to");
		Irssi::print("the current active channel/query or Irssi status window");
		Irssi::print("if you have no channel/query window active.");
		Irssi::print("Target can be nick name or channel name");
		Irssi::print("");
		Irssi::print("Configuration: /set xmms_info_pipe <file>");
		Irssi::print("Define filename of the pipe where from the InfoPipe output is read");
		Irssi::print("Default is /tmp/xmms-info");
		return;
	}

	my($p) = runningUnderIrssi() ? Irssi::settings_get_str('xmms_info_pipe') : $ARGV[0];
	my($i) = XMMSInfo->new;
	$i->getInfo(pipe => $p);

	my($o) = "XMMS: " . $i->getStatusString;

	if($i->isFatalError) {
		$o .= ": " . $i->getError;
	} elsif($i->isXmmsRunning) {
		my($t) = $i->infoTitle || "(unknown song)";
		my($a) = $i->infoArtist || "(unknown artist)";
		my($g) = lc($i->infoGenre) || "(unknown genre)";
		my($pos) = $i->infoMinutesNow . "m" . $i->infoSecondsNowLeftover."s";
		my($tot) = $i->infoMinutesTotal . "m" . $i->infoSecondsTotalLeftover."s";
		my($per) = $i->infoPercentage;
		my($b) = $i->infoBitrate . "kbps";
		my($f) = $i->infoFrequency . "kHz";
		$o .= " $g tune $t by $a." if ($i->isPlaying || $i->isPaused);
		$o .= " Played $pos of total $tot ($per%)." if $i->isPlaying;
		$o .= " [$b/$f]" if ($i->isPlaying || $i->isPaused);
	}

	if(!runningUnderIrssi()) {
		print "$o\n";
	} elsif($i->isFatalError || !$server || !$server->{connected} || (!$args && !$target)) {
		Irssi::print($o);
	} else {
		my($t) = $args || $target->{name};
		$server->command("msg $t $o");
	}

}

sub runningUnderIrssi {
	$0 eq '-e';
}

# END OF SCRIPT





# XMMSInfo.pm
# this should be in a separate file...
package XMMSInfo;

# should write docs...

use strict;
use POSIX;
use IO::File;
use MP3::Info;
use vars qw($PIPE $STATUS @ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw($STATUS);

$PIPE = '/tmp/xmms-info';
$STATUS = {
	-1	=> 'Fatal error',
	0	=> 'Not running',
	1	=> 'Stopped',
	2	=> 'Playing',
	3	=> 'Paused',
};

sub new {
	my($class) = shift;

	my($self) = {};
	bless($self, $class);

	$self->die("Try calling some methods first. \$obj->getInfo() is currently the only one available...");

	$self;
}

sub parseArgs {
	my($self) = shift;

	$#_ % 2 || return $self->die("Invalid number of arguments");
	for(my $i = 0; $i < $#_; $i += 2) {
		my($k, $v) = ($_[$i], $_[$i + 1]);
		$self->{Args}->{'.'.uc($k)} = $v;
	}

	1;
}

sub die {
	my($self) = shift;
	$self->setError(shift);
	$self->setStatus(-1);
	undef;
}

sub round {
	my($d) = shift;
	return $d unless $d =~ /^(\d+)\.(\d)/;
	$d = $1;
	$d++ if $2 >= 5;
	$d;
}

sub getInfo {
	my($self) = shift;

	$self->parseArgs(@_) || return;

	my($f) = $self->argPipe || $PIPE;
	-r $f || return $self->setStatus(0);
	my($fh) = IO::File->new($f) ||
		return $self->die("Can't open $f for reading: $!");

	while(<$fh>) {
		chomp;
		next unless /^(.+?): (.+)$/;
		if($1 eq 'Status') {
			$self->setStatus($2);
		} else {
			$self->{Info}->{'.'.uc($1)} = $2;
		}
	}
	$fh->close;

	return $self->die("Invalid input") unless $self->{Info}->{'.INFOPIPE PLUGIN VERSION'};

	my($t) = get_mp3tag($self->infoFile) || return $self->die("Can't read ID3 tag: ". $self->infoFile);
	my($i) = get_mp3info($self->infoFile) || return $self->die("Can't read MP3 info: ". $self->infoFile);

	my($k, $v);
	while(($k, $v) = (each(%$t), each(%$i))) {
		$self->{Info}->{'.'.$k} = $v;
	}

	$self->getStatus;
}

sub setStatus {
	my($self, $s) = @_;
	if($s =~ /^*\d+$/) {
		$self->{Status}->{'.STATUS'} = $s;
		$self->{Status}->{'.STATUSSTRING'} = $STATUS->{$s};
	} else {
		foreach my $k (keys %$STATUS) {
			my($v) = $STATUS->{$k};
			if($s eq $v) {
				$self->{Status}->{'.STATUS'} = $k;
				$self->{Status}->{'.STATUSSTRING'} = $s;
				return $self->getStatus;
			}
		}
		die "HELP";
	}

	$self->getStatus;
}

sub setError {
	shift->{Status}->{'.ERROR'} = pop;
}

sub getStatus {
	shift->{Status}->{'.STATUS'};
}

sub getStatusString {
	shift->{Status}->{'.STATUSSTRING'};
}

sub getError {
	shift->{Status}->{'.ERROR'};
}

sub isFatalError {
	shift->getStatus == -1;
}

sub isXmmsRunning {
	shift->getStatus > 0;
}

sub isPlaying {
	shift->getStatus == 2;
}

sub isPaused {
	shift->getStatus == 3;
}

sub isStopped {
	shift->getStatus == 1;
}

sub argPipe {
	shift->{Args}->{'.PIPE'};
}

sub infoPlayListItems {
	shift->{Info}->{'.TUNES IN PLAYLIST'};
}

sub infoCurrentItemInPlaylist {
	shift->{Info}->{'.CURRENTLY PLAYING'};
}

sub infoTimeNow {
	shift->{Info}->{'.POSITION'};
}

sub infoTimeTotal {
	shift->{Info}->{'.TIME'};
}

sub infoSecondsTotal {
	POSIX::ceil (shift->{Info}->{'.SECS'});
}

sub infoSecondsNow {
	my($self) = shift;
	my($s) = $self->infoTimeNow;
	die "HELP" unless $s =~ /^(\d+):(\d+)$/;
	$1 * 60 + $2;
}

sub infoMinutesTotal {
	shift->{Info}->{'.MM'};
}

sub infoMinutesNow {
	my($self) = shift;
	my($s) = $self->infoTimeNow;
	die "HELP" unless $s =~ /^(\d+):\d+$/;
	$1;
}

sub infoSecondsTotalLeftover {
	shift->{Info}->{'.SS'};
}

sub infoSecondsNowLeftover {
	my($self) = shift;
	$self->infoSecondsNow - ($self->infoMinutesNow * 60);
}

sub infouSecTotal {
	shift->{Info}->{'.USECTIME'};
}

sub infouSecNow {
	shift->{Info}->{'.USECPOSITION'};
}

sub infoPercentage {
	my($self) = shift;
	my($p) = ($self->infouSecNow / $self->infouSecTotal) * 100;
	round($p);
}

sub infoTitle {
	shift->{Info}->{'.TITLE'};
}

sub infoFile {
	shift->{Info}->{'.FILE'};
}

sub infoArtist {
	shift->{Info}->{'.ARTIST'};
}

sub infoAlbum {
	shift->{Info}->{'.ALBUM'};
}

sub infoYear {
	shift->{Info}->{'.YEAR'};
}

sub infoComment {
	shift->{Info}->{'.COMMENT'};
}

sub infoGenre {
	shift->{Info}->{'.GENRE'};
}

sub infoVersion {
	shift->{Info}->{'.VERSION'};
}

sub infoLayer {
	shift->{Info}->{'.LAYER'};
}

sub infoIsStereo {
	shift->{Info}->{'.STEREO'};
}

sub infoIsVbr {
	shift->{Info}->{'.VBR'};
}

sub infoBitrate {
	shift->{Info}->{'.BITRATE'};
}

sub infoFrequency {
	shift->{Info}->{'.FREQUENCY'};
}

sub infoSizeBytes {
	shift->{Info}->{'.SIZE'};
}

sub infoSize {
	shift->infoSizeBytes;
}

sub infoSizeKiloBytes {
	round(shift->infoSizeBytes / 1024);
}

sub infoSizeMegaBytes {
	round(shift->infoSizeKiloBytes / 1024);
}

sub infoIsCopyright {
	shift->{Info}->{'.COPYRIGHT'};
}

sub infoIsPadded {
	shift->{Info}->{'.PADDING'};
}

sub infoFrames {
	shift->{Info}->{'.FRAMES'};
}

sub infoFramesLength {
	shift->{Info}->{'.FRAMESLENGTH'};
}

sub infoVbrScale {
	shift->{Info}->{'.VBR_SCALE'};
}

1;

# EOF
