################################################################
#
# cycleactive.pl - cycles straight to the next active window
#
# By Erik Hollensbe <erik@hollensbe.org>
#
# $Id: cycleactive.pl,v 1.4 2004/05/08 15:50:36 golgo13 Exp $
#
################################################################
#
# The neat thing about this script is that it navigates in order
# of importance. That is, windows that are directing traffic for
# your attention will get switching priority over those who are
# just sending crap or just chatting.
#
################################################################
#
# /next_active - up the window numbers to the next active.
# /prev_active - down the window numbers to the previous active.
# /list_active - window information for active windows.
#
# recommendations: bind these to keys for *fast* navigation of
# your irc session.
#
################################################################

use Irssi;
use strict;

my $VERSION = '1.00';
my %IRSSI = (
    authors	=> 'Erik Hollensbe',
    contact	=> 'erik@hollensbe.org',
    name	=> 'Cycle Active',
    description	=> 'Cycles straight to the next active window',
    license	=> 'Public Domain',
    url		=> 'https://erik.hollensbe.org/cgi-bin/viewcvs.cgi/irssi/',
    changed	=> '$Date: 2004/05/08 15:50:36 $',
);

use constant CRAP  => 1;
use constant MSG   => 2;
use constant HILIT => 3;

my $theme_map = {
                 CRAP() =>  [ 'Irssi',
                              '{line_start}{hilight Irssi:} $0',
                            ],
                 MSG()  =>  [ 'Irssi_msg',
                              '{line_start}{hilight Irssi:} $0',
                            ],
                 HILIT() => [ 'Irssi_msg_hilit',
                              '{line_start}{hilight Irssi:} {hilight $0}',
                            ],
                };

################################################################
#
# support functions
#
################################################################

# sends a friendly message to the irc window. give it a Windowitem
# to send it to the current window.

sub notify_user {

    my ($witem, $mode) = (shift, shift);

    if ($witem) {
        $witem->printformat(MSGLEVEL_CLIENTCRAP, $theme_map->{$mode}->[0], join(" ", @_));
    } else {
        Irssi::printformat(MSGLEVEL_CLIENTCRAP, $theme_map->{$mode}->[0], join(" ", @_));
    }

}

# performs the actual window switching. takes a list
# of Window objects.

sub switch_windows {

    # rotate the list until we find the active window.

    my $curwin = Irssi::active_win();

    push @_, shift @_ while($curwin->{refnum} != $_[0]->{refnum});

    foreach my $type (HILIT, MSG, CRAP) {

        my @filter = grep { $_->{data_level} == $type } @_;

        if (scalar (@filter)) {
            $filter[0]->set_active();
            return;
        }

    }

}

################################################################
#
# IRC Commands
#
################################################################

# go to the next active window

sub cmd_next_active {

    my ($data, $server, $witem) = @_;

    switch_windows(sort { $a->{refnum} <=> $b->{refnum} } Irssi::windows());

}

# go to the previous active window

sub cmd_prev_active { 

    my ($data, $server, $witem) = @_;

    switch_windows(sort { $b->{refnum} <=> $a->{refnum} } Irssi::windows());

}

# list the active windows - highlights those directed at you.

sub cmd_list_active {
    my ($data, $server, $witem) = @_;

    if (scalar(grep { $_->{data_level} } Irssi::windows())) {

        notify_user($witem, CRAP, "Active windows:");
        foreach my $window (Irssi::windows()) {

            my $channel_string = "        ".sprintf("%2d", $window->{refnum})." ".($window->{name} || $window->{active}->{visible_name});

            if ($window->{data_level} == CRAP) {
                notify_user($witem, CRAP, $channel_string);
            } elsif ($window->{data_level} == MSG) {
                notify_user($witem, MSG, $channel_string);
            } elsif ($window->{data_level} == HILIT) {
                notify_user($witem, HILIT, $channel_string);
            }
        }

    } else {
        notify_user($witem, CRAP, "No active windows");
    }
}

################################################################
#
# Instantiation.
#
################################################################

Irssi::command_bind("prev_active", "cmd_prev_active");
Irssi::command_bind("next_active", "cmd_next_active");
Irssi::command_bind("list_active", "cmd_list_active");

Irssi::theme_register([map { @$_ } values %$theme_map]);
