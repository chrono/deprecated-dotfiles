use Irssi;
use strict;

use vars qw($VERSION %IRSSI);

$VERSION="0.2.1";
%IRSSI = (
	authors=> 'BC-bd',
	contact=> 'bd@bc-bd.org',
	name=> 'nm',
	description=> 'right aligned nicks depending on longest nick',
	license=> 'GPL v2',
	url=> 'http://bc-bd.org/software.php3#irssi',
);

#
# nm.pl
# for irssi 0.8.4 by bd@bc-bd.org
#
# right aligned nicks depending on longest nick
#
# inspired by neatmsg.pl from kodgehopper <kodgehopper@netscape.net
# formats taken from www.irssi.de
# thanks to adrianel <adrinael@nuclearzone.org> for some hints
#
#########
# USAGE
###
# 
# /neatredo to recalculate longest nick. (should not be needed)
#
#########
# OPTIONS
#########
#
# /set neat_right_mode <ON|OFF>
#		* ON  : print the mode of the nick e.g @%+ after the nick
#		* OFF : print it left of the nick 
#
# /set neat_maxlength <number>
#		* number : Maximum length of Nicks to display. Longer nicks are truncated.
#		* 0      : Do not truncate nicks.
#
###
################
###
#
# Changelog
#
# Version 0.2.1
#  - moved neat_maxlength check to reformat() (thx to Jerome De Greef <jdegreef@brutele.be>)
#
# Version 0.2.0
#  - by adrianel <adrinael@nuclearzone.org>
#     * reformat after setup reload
#     * maximum length of nicks
#
# Version 0.1.0
#  - got lost somewhere
#
# Version 0.0.2
#  - ugly typo fixed
#  
# Version 0.0.1
#  - initial release
#
###
################
###
#
# BUGS
#
# Well its a feature: due to the lacking support of extendable themes
# from irssi it is not possible to just change some formats per window.
# This means that right now all windows are aligned with the same nick
# length which can be somewhat annoying.
# If irssi supports extendable themes i will include per server indenting
# and a setting where you can specify servers you don't want to be indented
#
###
################


my ($longestNick);

sub reformat() {
	my $max = Irssi::settings_get_int('neat_maxlength');

	if ($max && $max < $longestNick) {
		$longestNick = $max;
	}

	if (Irssi::settings_get_bool('neat_right_mode') == 0) {
		Irssi::command('^format own_msg {ownmsgnick $2 {ownnick $[-'.$longestNick.']0}}$1');
		Irssi::command('^format own_msg_channel {ownmsgnick $3 {ownnick $[-'.$longestNick.']0}{msgchannel $1}}$2');
		Irssi::command('^format pubmsg_me {pubmsgmenick $2 {menick $[-'.$longestNick.']0}}$1');
		Irssi::command('^format pubmsg_me_channel {pubmsgmenick $3 {menick $[-'.$longestNick.']0}{msgchannel $1}}$2');
		Irssi::command('^format pubmsg_hilight {pubmsghinick $0 $3 $[-'.$longestNick.']1%n}$2');
		Irssi::command('^format pubmsg_hilight_channel {pubmsghinick $0 $4 $[-'.$longestNick.']1{msgchannel $2}}$3');
		Irssi::command('^format pubmsg {pubmsgnick $2 {pubnick $[-'.$longestNick.']0}}$1');
		Irssi::command('^format pubmsg_channel {pubmsgnick $3 {pubnick $[-'.$longestNick.']0}{msgchannel $1}}$2');
	} else {
		Irssi::command('^format own_msg {ownmsgnick {ownnick $[-'.$longestNick.']0$2}}$1');
		Irssi::command('^format own_msg_channel {ownmsgnick {ownnick $[-'.$longestNick.']0$3}{msgchannel $1}}$2');
		Irssi::command('^format pubmsg_me {pubmsgmenick {menick $[-'.$longestNick.']0}$2}$1');
		Irssi::command('^format pubmsg_me_channel {pubmsgmenick {menick $[-'.$longestNick.']0$3}{msgchannel $1}}$2');
		Irssi::command('^format pubmsg_hilight {pubmsghinick $0 $0 $[-'.$longestNick.']1$3%n}$2');
		Irssi::command('^format pubmsg_hilight_channel {pubmsghinick $0 $[-'.$longestNick.']1$4{msgchannel $2}}$3');
		Irssi::command('^format pubmsg {pubmsgnick {pubnick $[-'.$longestNick.']0}$2}$1');
		Irssi::command('^format pubmsg_channel {pubmsgnick {pubnick $[-'.$longestNick.']0$3}{msgchannel $1}}$2');
	}
};

sub cmd_neatRedo{
	$longestNick = 0;

	# get own nick length
	foreach (Irssi::servers()) {
		my $len = length($_->{nick});

		if ($len > $longestNick) {
			$longestNick = $len;
		}
	}

	# get the lengths of the other people
	foreach (Irssi::channels()) {
		foreach ($_->nicks()) {
			my $len = length($_->{nick});

			if ($len > $longestNick) {
				$longestNick = $len;
			}
		}
	}

	reformat();
}

sub sig_newNick
{
	my ($channel, $nick) = @_;

	my $thisLen = length($nick->{nick});

	if ($thisLen > $longestNick) {
		$longestNick = $thisLen;
		reformat();
	}
}

Irssi::settings_add_bool('misc', 'neat_right_mode', 1);
Irssi::settings_add_int('misc', 'neat_maxlength', 0);

Irssi::command_bind('neatredo', 'cmd_neatRedo');

Irssi::signal_add('nicklist new', 'sig_newNick');
Irssi::signal_add('nicklist changed', 'sig_newNick');

Irssi::signal_add('setup changed', 'cmd_neatRedo');
Irssi::signal_add_last('setup reread', 'cmd_neatRedo');

cmd_neatRedo();
