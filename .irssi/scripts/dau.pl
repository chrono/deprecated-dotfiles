################################################################################
#
# dau.pl - write like an idiot
#
################################################################################
# Author
################################################################################
#
# Clemens Heidinger
#
# email: spoooky@dau.pl
#
# IRC:   IRCNet/EFnet:
#        spoooky*!*spoooky@*.geekmind.org
#
################################################################################
# Changelog
################################################################################
#
# dau.pl has a builtin changelog (--changelog switch)
#
################################################################################
# Credits
################################################################################
#
# - Robert 'rob' Hennig: For the original dau.pl-shell-script. Out of this
#   script, merged with some other small Perl- and shellscripts and aliases
#   arised the first version of dau.pl for irssi.
#
# - the various people reporting bugs (mostly of #quizparanoia.org/IRCNet) and
#   making suggestions. Too many to remember and to mention them all here.
#
################################################################################
# Documentation
################################################################################
#
# dau.pl has a builtin help (--help switch)
#
################################################################################
# License
################################################################################
#
# Licensed under the BSD license
#
################################################################################
# Website
################################################################################
#
# http://dau.pl/
#
# For additional information, downloads, the dauomat and the dauproxy
#
################################################################################

use 5.6.0;
use File::Basename;
use File::Path;
use IPC::Open3;
use Irssi 20021107.0841;
use Irssi::TextUI;
use locale;
use re 'eval';
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = '1.7.3';
%IRSSI = (
          authors     => 'Clemens Heidinger',
          changed     => 'Mon Apr 05 10:55:09 CEST 2004',
          commands    => 'dau',
          contact     => 'spoooky@dau.pl',
          description => 'write like an idiot',
          license     => 'BSD',
          modules     => 'File::Basename File::Path IPC::Open3',
          name        => 'DAU',
          sbitems     => 'daumode',
          url         => 'http://dau.pl/',
         );

################################################################################
# Register commands
################################################################################

Irssi::command_bind('dau', \&command_dau);

################################################################################
# Register settings
################################################################################

# boolean
Irssi::settings_add_bool('misc', 'dau_cowsay_print_cow', 0);
Irssi::settings_add_bool('misc', 'dau_figlet_print_font', 0);
Irssi::settings_add_bool('misc', 'dau_statusbar_daumode_hide_when_off', 0);
Irssi::settings_add_bool('misc', 'dau_tab_completion', 1);

# Integer
Irssi::settings_add_int('misc', 'dau_remote_babble_interval', 3600);
Irssi::settings_add_int('misc', 'dau_remote_babble_interval_accuracy', 90);

# String
Irssi::settings_add_str('misc', 'dau_cowsay_cowlist', '');
Irssi::settings_add_str('misc', 'dau_cowsay_cowpath', &def_dau_cowsay_cowpath);
Irssi::settings_add_str('misc', 'dau_cowsay_cowpolicy', 'allow');
Irssi::settings_add_str('misc', 'dau_cowsay_path', &def_dau_cowsay_path);
Irssi::settings_add_str('misc', 'dau_delimiter_string', ' ');
Irssi::settings_add_str('misc', 'dau_figlet_fontlist', 'mnemonic,term,ivrit');
Irssi::settings_add_str('misc', 'dau_figlet_fontpath', &def_dau_figlet_fontpath);
Irssi::settings_add_str('misc', 'dau_figlet_fontpolicy', 'allow');
Irssi::settings_add_str('misc', 'dau_figlet_path', &def_dau_figlet_path);
Irssi::settings_add_str('misc', 'dau_files_moron_own_substitutions', 'moron_own_substitutions.pl');
Irssi::settings_add_str('misc', 'dau_files_remote_babble_messages', 'remote_babble_messages');
Irssi::settings_add_str('misc', 'dau_files_root_directory', "$ENV{HOME}/.dau");
Irssi::settings_add_str('misc', 'dau_moron_eol_style', 'new');
Irssi::settings_add_str('misc', 'dau_moron_substitutions_permissions', '000');
Irssi::settings_add_str('misc', 'dau_random_options',
                                                      '--boxes --uppercase,' .
                                                      '--color --uppercase,' .
                                                      '--delimiter,' .
                                                      '--dots --moron,' .
                                                      '--leet,' .
                                                      '--mix,' .
                                                      '--mixedcase --bracket,' .
                                                      '--moron --stutter --uppercase,' .
                                                      '--moron -omega yes,' .
                                                      '--moron,' .
                                                      '--uppercase --underline,' .
                                                      '--words --mixedcase'
);
Irssi::settings_add_str('misc', 'dau_remote_babble_channellist', '');
Irssi::settings_add_str('misc', 'dau_remote_babble_channelpolicy', 'deny');
Irssi::settings_add_str('misc', 'dau_remote_babble_messages', 'hi @ all');
Irssi::settings_add_str('misc', 'dau_remote_babble_standard_options', '--random');
Irssi::settings_add_str('misc', 'dau_remote_channellist', '');
Irssi::settings_add_str('misc', 'dau_remote_channelpolicy', 'deny');
Irssi::settings_add_str('misc', 'dau_remote_deop_reply', 'you are on my shitlist now @ $nick');
Irssi::settings_add_str('misc', 'dau_remote_devoice_reply', 'you are on my shitlist now @ $nick');
Irssi::settings_add_str('misc', 'dau_remote_op_reply', 'thx 4 op @ $nick');
Irssi::settings_add_str('misc', 'dau_remote_permissions', '000000');
Irssi::settings_add_str('misc', 'dau_remote_question_reply', 'alles klar @ $nick');
Irssi::settings_add_str('misc', 'dau_remote_voice_reply', 'thx 4 voice @ $nick');
Irssi::settings_add_str('misc', 'dau_standard_messages', 'hi @ all');
Irssi::settings_add_str('misc', 'dau_standard_options', '--random');
Irssi::settings_add_str('misc', 'dau_words_range', '1-4');

################################################################################
# Register signals
# (Note that most signals are set dynamical in the subroutine signal_handling)
################################################################################

Irssi::signal_add_last('setup changed', \&signal_setup_changed);
Irssi::signal_add_last('window changed' => sub { Irssi::statusbar_items_redraw('daumode') });
Irssi::signal_add_last('window item changed' => sub { Irssi::statusbar_items_redraw('daumode') });

################################################################################
# Register statusbar items
################################################################################

Irssi::statusbar_item_register('daumode', '', 'statusbar_daumode');

################################################################################
# Global variables
################################################################################

# Containing irssi's 'cmdchars'

our $k = Irssi::parse_special('$k');

# Miscellaneous things

our %misc = (
    random_last => '',
    remote_babble_timer_last_interval => 0,
    signals     => {
                    'complete word'     => 0,
                    'event privmsg'     => 0,
                    'nick mode changed' => 0,
                    'send text'         => 0,
                    'signals idaumode'  => 0,
                   },
);

# All the options

our %option;

# All switches that may be given at commandline

our %switches = (

    # These switches may be combined

    combo  => {
                boxes     => { 'sub' => \&switch_boxes },
                bracket   => { 'sub' => \&switch_bracket },
                chars     => { 'sub' => \&switch_chars },
                color     => {
                              'sub'   => \&switch_color,
                              'split' => {
                                          chars     => 1,
                                          lines     => 1,
                                          paragraph => 1,
                                          rchars    => 1,
                                          words     => 1,
                                         },
                             },
                command   => {
                              'sub' => \&switch_command,
                               in   => { '*' => 1 },
                               out  => { '*' => 1 },
                               },
                cowsay    => { 'sub' => \&switch_cowsay },
                delimiter => {
                              'sub'    => \&switch_delimiter,
                               string  => { '*' => 1 },
                             },
                dots      => { 'sub' => \&switch_dots },
                figlet    => { 'sub' => \&switch_figlet },
                greet     => {
                              'sub'  => \&switch_greet,
                               whom  => {
                                         all   => 1,
                                         rnick => 1,
                                        },
                             },
                me        => { 'sub' => \&switch_me },
                mix       => { 'sub' => \&switch_mix },
                moron     => {
                              'sub'      => \&switch_moron,
                               eol       => {
                                             classic => 1,
                                             'new'   => 1,
                                             nothing => 1,
                                            },
                               omega     => {
                                             no  => 1,
                                             yes => 1,
                                            },
                               perm      => {
                                             '000' => 1,
                                             '001' => 1,
                                             '010' => 1,
                                             '011' => 1,
                                             '100' => 1,
                                             '101' => 1,
                                             '110' => 1,
                                             '111' => 1,
                                            },
                               uppercase => {
                                              no  => 1,
                                              yes => 1,
                                             },
                             },
                leet      => { 'sub' => \&switch_leet },
                mixedcase => { 'sub' => \&switch_mixedcase },
                nothing   => { 'sub' => \&switch_nothing },
                'reverse' => { 'sub' => \&switch_reverse },
                stutter   => { 'sub' => \&switch_stutter },
                underline => {
                              'sub'    => \&switch_underline,
                              'spaces' => {
                                           'no'  => 1,
                                           'yes' => 1,
                                          }
                             },
                uppercase => { 'sub' => \&switch_uppercase },
                words     => { 'sub' => \&switch_words },
               },

    # The following switches must not be combined

    nocombo => {
                changelog    => { 'sub' => \&switch_changelog },
                create_files => { 'sub' => \&switch_create_files },
                daumode      => {
                                 'sub'   => \&switch_daumode,
                                  imodes => { '*' => 1 },
                                  omodes => { '*' => 1 },
                                  perm   => {
                                             '00' => 1,
                                             '01' => 1,
                                             '10' => 1,
                                             '11' => 1,
                                            },
                                },
                help         => {
                                 'sub'     => \&switch_help,

                                 # setting changed/added => change/add it here

                                 setting => {
                                             # boolean
                                             dau_cowsay_print_cow                => 1,
                                             dau_figlet_print_font               => 1,
                                             dau_statusbar_daumode_hide_when_off => 1,
                                             dau_tab_completion                  => 1,

                                             # Integer
                                             dau_remote_babble_interval          => 1,
                                             dau_remote_babble_interval_accuracy => 1,

                                             # String
                                             dau_cowsay_cowlist                  => 1,
                                             dau_cowsay_cowpath                  => 1,
                                             dau_cowsay_cowpolicy                => 1,
                                             dau_cowsay_path                     => 1,
                                             dau_delimiter_string                => 1,
                                             dau_figlet_fontlist                 => 1,
                                             dau_figlet_fontpath                 => 1,
                                             dau_figlet_fontpolicy               => 1,
                                             dau_figlet_path                     => 1,
                                             dau_files_moron_own_substitutions   => 1,
                                             dau_files_remote_babble_messages    => 1,
                                             dau_files_root_directory            => 1,
                                             dau_moron_eol_style                 => 1,
                                             dau_moron_substitutions_permissions => 1,
                                             dau_random_options                  => 1,
                                             dau_remote_babble_channellist       => 1,
                                             dau_remote_babble_channelpolicy     => 1,
                                             dau_remote_babble_messages          => 1,
                                             dau_remote_babble_standard_options  => 1,
                                             dau_remote_channellist              => 1,
                                             dau_remote_channelpolicy            => 1,
                                             dau_remote_deop_reply               => 1,
                                             dau_remote_devoice_reply            => 1,
                                             dau_remote_op_reply                 => 1,
                                             dau_remote_permissions              => 1,
                                             dau_remote_question_reply           => 1,
                                             dau_remote_voice_reply              => 1,
                                             dau_standard_messages               => 1,
                                             dau_standard_options                => 1,
                                             dau_words_range                     => 1,
                                            },
                                },
                random => { 'sub' => \&switch_random },
               },
);

################################################################################
# Code run once at start
################################################################################

set_settings();
cowsay_cowlist($option{dau_cowsay_cowpath});
figlet_fontlist($option{dau_figlet_fontpath});
timer_babble_reset();
signal_handling();

print CLIENTCRAP "dau.pl $VERSION loaded. For help type %9${k}dau --help%9";

################################################################################
# Subroutines (commands)
################################################################################

sub command_dau {
	my ($data, $server, $witem) = @_;
	my $output;

	$output = parse_text($data, $witem);

	unless (defined($server) && $server && $server->{connected}) {
		$misc{'print'} = 1;
	}
	unless ((defined($witem) && $witem &&
	       ($witem->{type} eq 'CHANNEL' || $witem->{type} eq 'QUERY')))
	{
		$misc{'print'} = 1;
	}

	if ($misc{daumode}) {

		if (defined($witem) && $witem &&
		   ($witem->{type} eq 'CHANNEL' || $witem->{type} eq 'QUERY'))
		{
			my $modes_set = 0;

			# daumode set with parameters (imodes)

			if ($misc{queue}{0}{daumode}{imodes}) {
				$misc{daumode_ichannels}{$server->{tag}}{$witem->{name}} = 1;
				$misc{daumode_ichannels_modes}{$server->{tag}}{$witem->{name}} =
				$misc{queue}{0}{daumode}{imodes};
				$modes_set = 1;
			}

			# daumode set with parameters (omodes)

			if ($misc{queue}{0}{daumode}{omodes}) {
				$misc{daumode_ochannels}{$server->{tag}}{$witem->{name}} = 1;
				$misc{daumode_ochannels_modes}{$server->{tag}}{$witem->{name}} =
				$misc{queue}{0}{daumode}{omodes};
				$modes_set = 1;
			}

			# daumode set without parameters

			if (!$misc{daumode_ichannels}{$server->{tag}}{$witem->{name}} &&
			    !$misc{daumode_ochannels}{$server->{tag}}{$witem->{name}} &&
			    !$modes_set)
			{
				$misc{daumode_ichannels}{$server->{tag}}{$witem->{name}} = 1;
				$misc{daumode_ochannels}{$server->{tag}}{$witem->{name}} = 1;
				$misc{daumode_ichannels_modes}{$server->{tag}}{$witem->{name}} = '';
				$misc{daumode_ochannels_modes}{$server->{tag}}{$witem->{name}} = '';
			}

			# daumode unset

			elsif (($misc{daumode_ichannels}{$server->{tag}}{$witem->{name}}  ||
			        $misc{daumode_ochannels}{$server->{tag}}{$witem->{name}}) &&
			        !$modes_set)
			{
				$misc{daumode_ichannels}{$server->{tag}}{$witem->{name}} = 0;
				$misc{daumode_ochannels}{$server->{tag}}{$witem->{name}} = 0;
				$misc{daumode_ichannels_modes}{$server->{tag}}{$witem->{name}} = '';
				$misc{daumode_ochannels_modes}{$server->{tag}}{$witem->{name}} = '';
			}


			# the perm-option overrides everything

			# perm: 00

			if ($misc{queue}{0}{daumode}{perm} eq '00') {
				$misc{daumode_ichannels}{$server->{tag}}{$witem->{name}} = 0;
				$misc{daumode_ochannels}{$server->{tag}}{$witem->{name}} = 0;
				$misc{daumode_ichannels_modes}{$server->{tag}}{$witem->{name}} = '';
				$misc{daumode_ochannels_modes}{$server->{tag}}{$witem->{name}} = '';
			}

			# perm: 01

			if ($misc{queue}{0}{daumode}{perm} eq '01') {
				$misc{daumode_ichannels}{$server->{tag}}{$witem->{name}} = 0;
				$misc{daumode_ochannels}{$server->{tag}}{$witem->{name}} = 1;
				$misc{daumode_ichannels_modes}{$server->{tag}}{$witem->{name}} = '';
			}

			# perm: 10

			if ($misc{queue}{0}{daumode}{perm} eq '10') {
				$misc{daumode_ichannels}{$server->{tag}}{$witem->{name}} = 1;
				$misc{daumode_ochannels}{$server->{tag}}{$witem->{name}} = 0;
				$misc{daumode_ochannels_modes}{$server->{tag}}{$witem->{name}} = '';
			}

			# perm: 11

			if ($misc{queue}{0}{daumode}{perm} eq '11') {
				$misc{daumode_ichannels}{$server->{tag}}{$witem->{name}} = 1;
				$misc{daumode_ochannels}{$server->{tag}}{$witem->{name}} = 1;
			}

			Irssi::statusbar_items_redraw('daumode');
		}

		# Signal handling (for daumode and signal 'send text')

		signal_handling();

		return;
	}

	# MSG (or CTCP ACTION) $output to active channel/query-window

	{
		no strict 'refs';

		$output = $output || '';
		output_text($witem, $witem->{name}, $output);
	}
}

################################################################################
# Subroutines (switches, must not be combined)
################################################################################

sub switch_changelog {
	my $output;
	$misc{'print'} = 1;

	$output = &fix(<<"	END");
	CHANGELOG

	2002-05-05    release 0.1.0
	              initial release

	2002-05-06    release 0.1.1
	              bugfixes, minor changes

	2002-05-11    release 0.2.0
	              - new function: Put a single space after each character
	              - %9--moron%9: minor changes

	2002-05-12    release 0.3.0
	              new function: %9--mixedcase%9

	2002-05-17    release 0.4.0
	              function putting a single space after each character
	              changed name to %9--delimiter%9 and will accept any
	              delimiter string now

	2002-05-20    release 0.4.1
	              some nice new substitutions for %9--moron%9

	2002-05-24    release 0.5.0
	              new settings controlling the behaviour of %9--figlet%9

	2002-06-15    release 0.6.0
	              - new settings for %9--figlet%9
	              - %9--figlet%9 will omit lines only containing whitespace

	2002-06-16    release 0.6.1
	              bugfixes

	2002-06-16    release 0.6.2
	              bugfixes

	2002-06-17    release 0.7.0
	              - new settings for %9--moron%9
	              - new substitutions for %9--moron%9

	2002-06-19    release 0.8.0
	              new function: %9--dots%9
	              %9--moron%9: minor changes

	2002-06-23    release 0.9.0
	              - new: remote feature
	              - new substitutions for %9--moron%9
	              - %9--figlet%9: bugfixes

	2002-06-23    release 0.9.1
	              - %9--moron%9: minor changes
	              - remote feature: minor changes

	2002-06-29    release 0.9.2
	              new settings for the remote feature

	2002-07-23    release 0.9.3
	              new setting for %9--words%9

	2002-07-28    release 1.0.0
	              - Syntax changed
	              - Tabcompletion for the options
	              - Integrated help (%9--help%9)
	              - Integrated changelog (%9--changelog%9)
	              - Some of the options and settings have a different name
	                now
	              - %9--moron%9 no longer tears smilies apart
	              - new function: %9--leet%9
	              - new function: %9--reverse%9

	2002-07-28    release 1.0.1
	              bugfixes

	2002-09-01    release 1.0.2
	              - the script will now work properly even if the alias for
	                SAY does not exist
	              - new substitutions for %9--moron%9

	2002-09-03    release 1.0.3
	              - bugfixes
	              - new option for %9--figlet%9: %9-font%9

	2002-09-03    release 1.0.4
	              bugfixes

	2002-09-03    release 1.0.5
	              bugfixes

	2002-09-09    release 1.1.0
	              - You can combine commands now!
	              - new substitutions for %9--moron%9
	              - bugfixes

	2002-11-22    release 1.2.0
	              - _A lot_ of rewriting
	              - Syntax for %9${k}dau%9's options changed. See %9${k}dau --help%9
	              - Some settings have changed their name and/or expect other
	                values.
	                Checkout %9${k}dau --help%9, %9${k}set dau_%9 and
	                %9${k}dau --help <setting>%9
	              - new option for %9--delimiter%9: %9-string%9
	              - new option for %9--moron%9: %9-eol%9
	              - new option for %9--moron%9: %9-perm%9
	              - new setting: %9dau_moron_eol_style%9
	              - new setting: %9dau_random_options%9
	              - new setting: %9dau_standard_messages%9
	              - new setting: %9dau_standard_options%9
	              - new remote features:
	                - new setting: %9dau_remote_question_reply%9
	                - new setting: %9dau_remote_voice_reply%9
	                - new setting: %9dau_remote_devoice_reply%9
	                - new setting: %9dau_remote_op_reply%9
	                - new setting: %9dau_remote_deop_reply%9
	              - new function: %9--color%9
	              - new function: %9--daumode%9
	              - new function: %9--random%9
	              - new function: %9--stutter%9
	              - new function: %9--uppercase%9
	              - new statusbar item: %9daumode%9

	2002-11-27    release 1.2.1
	              minor changes and one crash-fix

	2002-12-15    release 1.2.2
	              - Changing settings of 'hallo wie geht'-remote-feature
	                didn't become effective immediately
	              - new substitutions for %9--moron%9

	2003-01-12    release 1.3.0
	              - %9--moron%9: randomly transpose letters with letters
	                next to them at the keyboard
	              - %9--moron%9: new 'substitution-level'. Checkout
	                %9${k}dau --help -setting dau_moron_substitutions_permissions%9
	                and set a new value for this setting
	              - new substitutions for %9--moron%9
	              - new option for %9--moron -eol%9 resp. setting
	                %9dau_moron_eol_style%9: %9nothing%9
	              - new option for %9--moron%9: %9-uppercase%9
	              - new setting: %9dau_files_moron_own_substitutions%9
	              - new setting: %9dau_files_root_directory%9
	              - new function: %9--create_files%9

	2003-01-17    release 1.4.0
	              - %9--color%9 revised
	              - You'll have to specify the ircnet in dau_remote_channellist
	                now. Checkout %9${k}dau --help -setting dau_remote_channellist%9
	              - You'll have to set a new value for dau_remote_permissions
	                too. Checkout %9${k}dau --help -setting dau_remote_permissions%9
	              - new remote features:
	                - new setting: %9dau_remote_babble_interval%9
	                - new setting: %9dau_remote_babble_messages%9
	              - new function: %9--greet%9

	2003-01-18    release 1.4.1
	              crash-fix

	2003-01-20    release 1.4.2
	              - new setting: %9dau_statusbar_daumode_hide_when_off%9
	              - some other (minor) changes

	2003-02-01    release 1.4.3
	              a few minor changes

	2003-02-09    release 1.4.4
	              - commandline-parsing fixes
	              - some other (minor) changes

	2003-02-16    release 1.4.5
	              - commandline-parsing fixes
	              - many settings use now a comma spearated list of strings instead
	                of one single string. So you can specify more replies for the
	                remote features f.e.

	2003-03-16    release 1.4.6
	              a few minor changes

	2003-05-01    release 1.5.0
	              - almost all signal handlers are now added/removed
	                dynamically. The timer-subroutine for the babble-feature
	                will be entered less often too. So dau.pl will take less
	                CPU-time.
	              - new setting: %9dau_tab_completion%9
	              - new function: %9--bracket%9

	2003-06-13    release 1.5.1
	              - fixed a few bugs. dau.pl should work now pretty good under
	                the warnings pragma.
	              - new function: %9--underline%9

	2003-07-16    release 1.5.2
	              - new function: %9--boxes%9
	              - some other (minor) changes

	2003-08-16    release 1.5.3
	              changes in %IRSSI

	2003-09-14    release 1.5.4
	              - Give figlet the input to play with over STDIN to avoid
	                a figlet bug with strings starting with a dash.
	              - some other (minor) changes

	2003-11-16    release 1.6.0
	              - dau_remote:
	                - reply to a 'hallo wie geht @ yournick'
	                - reply to a colored 'hallo wie geht'
	              - Incoming messages can be dauified now!
	                Checkout %9${k}dau --help%9 (daumode)
	              - Statusbaritem changed. Remove old stuff from your theme-file
	                and look in the documentation of the daumode
	              - some other (minor) changes

	2004-03-25    release 1.7.0
	              - new substitutions for %9--moron%9
	              - new setting: %9dau_cowsay_cowlist%9
	              - new setting: %9dau_cowsay_cowpath%9
	              - new setting: %9dau_cowsay_cowpolicy%9
	              - new setting: %9dau_cowsay_path%9
	              - new setting: %9dau_files_remote_babble_messages%9
	              - new setting: %9dau_remote_babble_standard_options%9
	              - new function: %9--cowsay%9
	              - new function: %9--mix%9 (by Martin Kihlgren <zond\@troja.ath.cx>)
	              - new option for %9--color%9: %9-split paragraph%9
	              - new option for %9--command%9: %9-in%9
	              - renamed %9--command -cmd%9 to %9--command -out%9, adjust your
	                aliases etc.
	              - new option for %9--moron%9: %9-omega%9

	2004-04-01    release 1.7.1
	              - new substitutions for %9--moron%9
	              - new setting: %9dau_remote_babble_channellist%9
	              - new setting: %9dau_remote_babble_channelpolicy%9
	              - new setting: %9dau_remote_babble_interval_accuracy%9
	              - new special variables for the babble messages.
	                Checkout %9${k}dau --help -setting dau_files_remote_babble_messages%9
	              - %9--command -in%9: bugfix (do not send the original message
	                before the dauified message)

	2004-04-02    release 1.7.2
	              - performance tweaks
	              - babble remote feature:
	                - bugfix: do not block irssi while writing
	                - better method calculating the writing breaks in
	                  multiline messages. The longer the next line is the
	                  longer the break will be

	2004-04-05    release 1.7.3
	              remote babble feature: bugfix
	END

	return $output;
}

sub switch_create_files {

	# create directory dau_files_root_directory if not found

	if (-f $option{dau_files_root_directory}) {
		print_err("$option{dau_files_root_directory} is a _file_ => aborting");
		return;
	}
	if (-d $option{dau_files_root_directory}) {
		print_out('directory dau_files_root_directory already exists - no need to create it');
	} else {
		if (mkpath([$option{dau_files_root_directory}])) {
			print_out("creating directory $option{dau_files_root_directory}/");
		} else {
			print_err("failed creating directory $option{dau_files_root_directory}/");
		}
	}

	# create file dau_files_moron_own_substitutions if not found

	my $file1 = "$option{dau_files_root_directory}/$option{dau_files_moron_own_substitutions}";

	if (-e $file1) {

		print_out("file $file1 already exists - no need to create it");

	} else {

		if (open(FH1, "> $file1")) {

			print FH1 &fix(<<'			END');
			# dau.pl - http://dau.pl/
			#
			# This is the file --moron will use for your own substitutions.
			# You can use any perlcode in here.
			# $_ contains the text you can work with.
			# $_ has to contain the data to be returned to dau.pl at the end.
			END

			print_out("$file1 created. you should edit it now!");

		} else {

			print_err("cannot write $file1: $!");

		}

		if (!close(FH1)) {
			print_err("cannot close $file1: $!");
		}
	}

	# create file dau_files_remote_babble_messages if not found

	my $file2 = "$option{dau_files_root_directory}/$option{dau_files_remote_babble_messages}";

	if (-e $file2) {

		print_out("file $file2 already exists - no need to create it");

	} else {

		if (open(FH1, "> $file2")) {

			print FH1 &fix(<<'			END');
			END

			print_out("$file2 created. you should edit it now!");

		} else {

			print_err("cannot write $file2: $!");

		}

		if (!close(FH1)) {
			print_err("cannot close $file2: $!");
		}
	}

	return;
}

sub switch_daumode {
	$misc{daumode} = 1;
}

sub switch_help {
	my $output;
	my $option_setting = $misc{queue}{'0'}{help}{setting};
	$misc{'print'} = 1;

	if ($option_setting eq '') {
		$output = &fix(<<"		END");
		%9SYNOPSIS%9

		%9${k}dau [%Uoptions%U] [%Utext%U%9]

		%9DESCRIPTION%9

		Just write in the annoying way many lusers do. In contrast to
		many scripts of this kind, this wont do _anything_
		automatically unless you turn the feature on via an irssi
		setting or a command.

		%9OPTIONS%9

		%9--boxes%9
		     Put words in boxes

		%9--bracket%9
		     Bracket the text

		%9--changelog%9
		     Print the scripts changelog

		%9--chars%9
		     Only one character each line

		%9--color%9
		     Write in colors

		     %9-split%9:
		         %Uchars%U:      Every character another color
		         %Ulines%U:      Every line another color
		         %Uparagraph%U:  The whole paragraph in one color
		         %Urchars%U:     Some characters one color
		         %Uwords%U:      Every word another color

		%9--command%9
		     %9-in%9 %Ucommand%U:
		         Feed dau.pl with the output (the public message)
		         that %Ucommand%U produces

		     %9-out%9 %Ucommand%U:
		         %Utopic%U for example will set a dauified topic

		%9--cowsay%9
		     Use cowsay to write

		     %9-cow%9 %Ucow%U:
		         The cow to use

		%9--create_files%9
		    Create files and directories of all dau_files_*-settings

		%9--daumode%9
		     Toggle daumode.
		     Works on a per channel basis!

		     %9-imodes%9 %Umodes%U:
		         All incoming messages will be dauified and the
		         specified modes are used by dau.pl. If you omit these
		         option, dau.pl will use the standard options.

		     %9-omodes%9 %Umodes%U:
		         All outgoing messages will be dauified and the
		         specified modes are used by dau.pl. If you omit these
		         option, dau.pl will use the standard options.

		     %9-perm%9 %U[01][01]%U:
		         Dauify incoming/outgoing messages?

		     There is a statusbar item available displaying the current
		     status of the daumode. Add it with
		     %9/statusbar window add [-alignment <left|right>] daumode%9
		     You may customize the look of the statusbar item in the
		     theme file. f.e.:

		     sb_daumode = "{sb daumode I: \$0 (\$1) O: \$2 (\$3)}";

		     # \$0: will incoming messages be dauified?
		     # \$1: modes for incoming messages
		     # \$2: will outgoing messages be dauified?
		     # \$3: modes for outgoing messages

		%9--delimiter%9
		     Insert a delimiter-string after each character

		     %9-string%9 %Ustring%U:
		         Override setting dau_delimiter_string. If this string
		         contains whitespace, you should quote the string with
		         single quotes.

		%9--dots%9
		     Put some dots... after some words...

		%9--figlet%9
		     Use figlet to write

		     %9-font%9 %Ufont%U:
		         The font to use

		%9--greet%9
		     Greet people in channel

		     %9-whom%9 %Uall|rnick%U:
		         %Uall%U  : every nick
		         %Urnick%U: one nick randomly selected

		%9--help%9
		     Show these lines

		     %9-setting%9 %Usetting%U:
		         More information about a specific setting

		%9--leet%9
		     Write in leet speech

		%9--me%9
		     Send a CTCP ACTION instead of a PRIVMSG

		%9--mix%9
		     Mix all the characters in a word except for the first and
		     last

		%9--mixedcase%9
		     Write in mixed case

		%9--moron%9
		     Write in uppercase, mix in some typos, perform some
		     substitutions on the text, ... Just write like a
		     moron

		     %9-eol%9 %Uclassic|new|nothing%U:
		         Override setting dau_moron_eol_style

		     %9-omega%9 %Uyes|no%U:
		         The fantastic omega mode

		     %9-perm%9 %U[01][01][01]%U:
		         Override setting dau_moron_substitutions_permissions

		     %9-uppercase%9 %Uyes|no%U:
		         Uppercase text

		%9--nothing%9
		     Do nothing

		%9--random%9
		     Let dau.pl choose randomly options. Get these options from
		     the comma separated list of setting dau_random_options

		%9--reverse%9
		     Reverse the input string

		%9--stutter%9
		     Stutter a bit

		%9--underline%9
		     Underline text

		     %9-spaces%9 %Uyes|no%U:
		         One additional space at start of string and end of string?

		%9--uppercase%9
		     Write in upper case

		%9--words%9
		     Only a few words each line

		%9EXAMPLES%9

		%9${k}dau --uppercase --mixedcase %Ufoo bar baz%9
		     Will write %Ufoo bar baz%U in mixed case.
		     %Ufoo bar baz%U is sent _first_ to the uppercase
		     subroutine _then_ to mixedcase subroutine. The order you
		     specify the options on the commandline is important. You
		     can see what output a command produces without sending it
		     to the active channel/query-window by typing the command
		     out of a non-channel/query-window. There are thousands of
		     possiblilities combining the options, so some combinations
		     may produce a strange output. Try changing the order of
		     the options, that might help.

		%9${k}dau --color --figlet %Ufoo bar baz%9
		     %9--color%9 will insert colorcodes after some characters.
		     So the string will look like %U\\00302f\\00303o[...]%U when
		     leaving the color subroutine. %9--figlet%9 uses then that
		     string as its input. So you'll have finally an output like
		     %U02f03o[...]%U in the figlet latters.
		     So its better to use _first_ %9--figlet%9 _then_ %9--color%9.
		END
	}

	# setting changed/added => change/add them below

	# boolean

	elsif ($option_setting eq 'dau_cowsay_print_cow') {
		$output = &fix(<<"		END");
		%9dau_cowsay_print_cow%9 %Ubool

		Print a message which cow will be used.
		END
	}
	elsif ($option_setting eq 'dau_figlet_print_font') {
		$output = &fix(<<"		END");
		%9dau_figlet_print_font%9 %Ubool

		Print a message which font will be used.
		END
	}
	elsif ($option_setting eq 'dau_statusbar_daumode_hide_when_off') {
		$output = &fix(<<"		END");
		%9dau_statusbar_daumode_hide_when_off%9 %Ubool

		Hide statusbar item when daumode is turned off.
		END
	}
	elsif ($option_setting eq 'dau_tab_completion') {
		$output = &fix(<<"		END");
		%9dau_tab_completion%9 %Ubool

		Perhaps someone wants to disable TAB-Completion for the
		${k}dau-command because he/she doesn't like it or wants
		to give the CPU a break (don't know whether it has much
		influence)
		END
	}

	# Integer

	elsif ($option_setting eq 'dau_remote_babble_interval') {
		$output = &fix(<<"		END");
		%9dau_remote_babble_interval%9 %Uinteger

		Interval (in seconds) dau.pl will babble text.
		END
	}
	elsif ($option_setting eq 'dau_remote_babble_interval_accuracy') {
		$output = &fix(<<"		END");
		%9dau_remote_babble_interval_accuracy%9 %Uinteger

		Value expressed as a percentage how accurate the timer of
		the babble feature should be.

		Legal values: 1-100

		%U100%U would result in a very accurate timer.
		END
	}

	# String

	elsif ($option_setting eq 'dau_cowsay_cowlist') {
		$output = &fix(<<"		END");
		%9dau_cowsay_cowlist%9 %Ustring

		Comma separated list of cows. Checkout
		%9${k}dau --help -setting dau_cowsay_cowpolicy%9
		to see what this setting is good for.
		END
	}
	elsif ($option_setting eq 'dau_cowsay_cowpath') {
		$output = &fix(<<"		END");
		%9dau_cowsay_cowpath%9 %Ustring

		Path to the cowsay-cows (*.cow).
		END
	}
	elsif ($option_setting eq 'dau_cowsay_cowpolicy') {
		$output = &fix(<<"		END");
		%9dau_cowsay_cowpolicy%9 %Ustring

		Specifies the policy used to handle the cows in
		dau_cowsay_cowpath. If set to %Uallow%U, all cows available
		will be used by the command. You can exclude some cows by
		setting dau_cowsay_cowlist. If set to %Udeny%U, no cows but
		the ones listed in dau_cowsay_cowlist will be used by the
		command. Useful if you have many annoying cows in your
		cowpath and you want to permit only a few of them.
		END
	}
	elsif ($option_setting eq 'dau_cowsay_path') {
		$output = &fix(<<"		END");
		%9dau_cowsay_path%9 %Ustring

		Should point to the cowsay executable.
		END
	}
	elsif ($option_setting eq 'dau_delimiter_string') {
		$output = &fix(<<"		END");
		%9dau_delimiter_string%9 %Ustring

		Tell %9--delimiter%9 which delimiter to use.
		END
	}
	elsif ($option_setting eq 'dau_figlet_fontlist') {
		$output = &fix(<<"		END");
		%9dau_figlet_fontlist%9 %Ustring

		Comma separated list of fonts. Checkout
		%9${k}dau --help -setting dau_figlet_fontpolicy%9
		to see what this setting is good for. Use the program
		`showfigfonts` shipped with figlet to find these fonts.
		END
	}
	elsif ($option_setting eq 'dau_figlet_fontpath') {
		$output = &fix(<<"		END");
		%9dau_figlet_fontpath%9 %Ustring

		Path to the figlet-fonts (*.flf).
		END
	}
	elsif ($option_setting eq 'dau_figlet_fontpolicy') {
		$output = &fix(<<"		END");
		%9dau_figlet_fontpolicy%9 %Ustring

		Specifies the policy used to handle the fonts in
		dau_figlet_fontpath. If set to %Uallow%U, all fonts available
		will be used by the command. You can exclude some fonts by
		setting dau_figlet_fontlist. If set to %Udeny%U, no fonts but
		the ones listed in dau_figlet_fontlist will be used by the
		command. Useful if you have many annoying fonts in your
		fontpath and you want to permit only a few of them.
		END
	}
	elsif ($option_setting eq 'dau_figlet_path') {
		$output = &fix(<<"		END");
		%9dau_figlet_path%9 %Ustring

		Should point to the figlet executable.
		END
	}
	elsif ($option_setting eq 'dau_files_moron_own_substitutions') {
		$output = &fix(<<"		END");
		%9dau_files_moron_own_substitutions%9 %Ustring

		Your own substitutions-file (third bit setting
		dau_moron_substitutions_permissions). _Must_ be in
		dau_files_root_directory.
		%9${k}dau --create_files%9 will create it.
		END
	}
	elsif ($option_setting eq 'dau_files_remote_babble_messages') {
		$output = &fix(<<"		END");
		%9dau_files_remote_babble_messages%9 %Ustring

		Format of the file:
		    Newline separated plain text.

		    Special Metasequences:

		    - \\n:     real newline
		    - \$rnick: random nick
		    - irssis special variables like \$C for the current
		      channel and \$N for your current nick

		    Quoting:

		    - \\\$: literal \$
		    - \\\\: literal \\

		Your own file for the messages of the remote babble feature.
		_Must_ be in dau_files_root_directory.
		%9${k}dau --create_files%9 will create it.
		END
	}
	elsif ($option_setting eq 'dau_files_root_directory') {
		$output = &fix(<<"		END");
		%9dau_files_root_directory%9 %Ustring

		Directory in which all files for dau.pl will be stored.
		%9${k}dau --create_files%9 will create it.
		END
	}
	elsif ($option_setting eq 'dau_moron_eol_style') {
		$output = &fix(<<"		END");
		%9dau_moron_eol_style%9 %Ustring

		What to do at End Of Line?

		%Uclassic%U: !!!??!!!!!????!??????????!!!1 (or similar)
		%Unew%U    : !!!??!!!!!????!??????????!!!1 (or similar) or
		         = and in a new line ?                      or
		         ?¿?
		%Unothing%U: nothing at EOL
		END
	}
	elsif ($option_setting eq 'dau_moron_substitutions_permissions') {
		$output = &fix(<<"		END");
		%9dau_moron_substitutions_permissions%9 %U[01][01][01]

		Controls whether %9--moron%9 should perform some
		substitutions on the text or not. These substitutions make
		only sense performed on german text.

		First Bit:
		    You should turn it on if you write german text with dau.pl

		Second Bit:
		    Perform substitutions which may cause that a third person
		    does not understand what you wanted to say.
		    Anyway, most user i know have turned it on

		Third Bit:
		    Your own substitutions. Checkout the help for the
		    dau_files_*-settings and %9--create_files%9
		END
	}
	elsif ($option_setting eq 'dau_random_options') {
		$output = &fix(<<"		END");
		%9dau_random_options%9 %Ustring

		Comma separated list of options %9--random%9 will use. It will
		take randomly one item of the list. If you set it f.e. to
		%U--uppercase --color,--mixedcase%U,
		the probability of printing a colored, uppercased string hello
		will be 50% as well as the probabilty of printing a mixedcased
		string hello when typing %9${k}dau --random hello%9.
		END
	}
	elsif ($option_setting eq 'dau_remote_babble_channellist') {
		$output = &fix(<<"		END");
		%9dau_remote_babble_channellist%9 %Ustring

		Comma separated list of channels. You'll have to specify the
		ircnet too.
		Format: #channel1/IRCNet,#channel2/EFnet
		END
	}
	elsif ($option_setting eq 'dau_remote_babble_channelpolicy') {
		$output = &fix(<<"		END");
		%9dau_remote_babble_channelpolicy%9 %Ustring

		Using the default policy %Udeny%U the script won't do anything
		except in the channels listed in dau_remote_babble_channellist.
		Using the policy %Uallow%U the script will babble in all
		channels but the ones listed in dau_remote_babble_channellist.
		END
	}
	elsif ($option_setting eq 'dau_remote_babble_messages') {
		$output = &fix(<<"		END");
		%9dau_remote_babble_messages%9 %Ustring

		Comma separated list of messages dau.pl will babble.

		Special Metasequences:

		- \\n:     real newline
		- \$rnick: random nick
		- irssis special variables like \$C for the current
		  channel and \$N for your current nick

		Quoting:

		- \\\$: literal \$
		- \\\\: literal \\
		END
	}
	elsif ($option_setting eq 'dau_remote_babble_standard_options') {
		$output = &fix(<<"		END");
		%9dau_remote_babble_standard_options%9 %Ustring

		Options the remote babble feature will use if the user omits
		them.
		END
	}
	elsif ($option_setting eq 'dau_remote_channellist') {
		$output = &fix(<<"		END");
		%9dau_remote_channellist%9 %Ustring

		Comma separated list of channels. You'll have to specify the
		ircnet too.
		Format: #channel1/IRCNet,#channel2/EFnet
		END
	}
	elsif ($option_setting eq 'dau_remote_channelpolicy') {
		$output = &fix(<<"		END");
		%9dau_remote_channelpolicy%9 %Ustring

		Using the default policy %Udeny%U the script won't do anything
		except in the channels listed in dau_remote_channellist. Using
		the policy %Uallow%U the script will reply to all channels but
		the ones listed in dau_remote_channellist.
		END
	}
	elsif ($option_setting eq 'dau_remote_deop_reply') {
		$output = &fix(<<"		END");
		%9dau_remote_deop_reply%9 %Ustring

		Comma separated list of messages (it will take randomly one
		item of the list) sent to channel if someone deops you (mode
		change -o).
		The string given will be processed by the same subroutine
		parsing the %9${k}dau%9 command.

		Special Variables:

		\$nick: contains the nick of the one who changed the mode
		END
	}
	elsif ($option_setting eq 'dau_remote_devoice_reply') {
		$output = &fix(<<"		END");
		%9dau_remote_devoice_reply%9 %Ustring

		Comma separated list of messages (it will take randomly one
		item of the list) sent to channel if someone devoices you (mode
		change -v).
		The string given will be processed by the same subroutine
		parsing the %9${k}dau%9 command.

		Special Variables:

		\$nick: contains the nick of the one who changed the mode
		END
	}
	elsif ($option_setting eq 'dau_remote_op_reply') {
		$output = &fix(<<"		END");
		%9dau_remote_op_reply%9 %Ustring

		Comma separated list of messages (it will take randomly one
		item of the list) sent to channel if someone ops you (mode
		change +o).
		The string given will be processed by the same subroutine
		parsing the %9${k}dau%9 command.

		Special Variables:

		\$nick: contains the nick of the one who changed the mode
		END
	}
	elsif ($option_setting eq 'dau_remote_permissions') {
		$output = &fix(<<"		END");
		%9dau_remote_permissions%9 %U[01][01][01][01][01][01]

		Permit or forbid the remote features.

		First Bit:
		    Very, very useful feature. Will reply to the profound question
		    'hallo wie geht?' the appropriate answer.
		    Again, only useful for german users. ;-)

		Second Bit:
		    If someone gives you voice in a channel, thank him!

		Third Bit:
		    If someone gives you op in a channel, thank him!

		Fourth Bit:
		    If devoiced, print message

		Fifth Bit:
		    If deopped, print message

		Sixth Bit:
		    Babble text in certain intervals
		END
	}
	elsif ($option_setting eq 'dau_remote_question_reply') {
		$output = &fix(<<"		END");
		%9dau_remote_question_reply%9 %Ustring

		Comma separated list of reply strings for the question 'hallo
		wie geht?' (it will randomly choose one item of the list).
		The string given will be processed by the same subroutine
		parsing the %9${k}dau%9 command.

		Special Variables:

		\$nick: contains the nick of the one who sent the message to which
		       dau.pl reacts
		END
	}
	elsif ($option_setting eq 'dau_remote_voice_reply') {
		$output = &fix(<<"		END");
		%9dau_remote_voice_reply%9 %Ustring

		Comma separated list of messages (it will take randomly one
		item of the list) sent to channel if someone voices you (mode
		change +v).
		The string given will be processed by the same subroutine
		parsing the %9${k}dau%9 command.

		Special Variables:

		\$nick: contains the nick of the one who changed the mode
		END
	}
	elsif ($option_setting eq 'dau_standard_messages') {
		$output = &fix(<<"		END");
		%9dau_standard_messages%9 %Ustring

		Comma separated list of strings %9${k}dau%9 will use if the user
		omits the text on the commandline.
		END
	}
	elsif ($option_setting eq 'dau_standard_options') {
		$output = &fix(<<"		END");
		%9dau_standard_options%9 %Ustring

		Options %9${k}dau%9 will use if the user omits them on the commandline.
		END
	}
	elsif ($option_setting eq 'dau_words_range') {
		$output = &fix(<<"		END");
		%9dau_words_range%9 %Ui-j

		Setup the range howmany words the command should write per line.
		1 <= i <= j <= 9; i, j element { 1, ... , 9 }. If i == j the command
		will write i words to the active window.  Else it takes a random
		number k (element { i, ... , j }) and writes k words per
		line.
		END
	}

	return $output;
}

sub switch_random {
	my ($data, $channel_rec) = @_;
	my $output;
	my (@options, $text);

	# Push each item of dau_random_options in the @options array.

	while ($option{dau_random_options} =~ /\s*([^,]+)\s*,?/g) {
		my $item = $1;
		push @options, $item;
	}

	# More than one item in @options. Choose one randomly but exclude
	# the last item chosen.

	if (@options > 1) {
		@options = grep { $_ ne $misc{random_last} } @options;
		my $opt = @options[rand(@options)];
		$misc{random_last} = $opt;
		$text .= $opt . ' ' . $data;
		$output = parse_text($text, $channel_rec);
	}

	# Exact one item in @options - take that

	elsif (@options == 1) {
		my $opt = $options[0];
		$misc{random_last} = $opt;
		$text .= $opt . ' ' . $data;
		$output = parse_text($text, $channel_rec);
	}

	# No item in @options - call switch_moron()

	else {
		$output = &{ $switches{combo}{moron}{'sub'} }($output, $channel_rec);
	}

	return $output;
}

################################################################################
# Subroutines (switches, may be combined)
################################################################################

sub switch_boxes {
	my $data = shift;

	# handling punctuation marks:
	# they will be put in their own box later

	$data =~ s%(\w+)([,.?!;:]+)%
	           $1 . ' ' . join(' ', split(//, $2))
	          %egx;

	# separate words (by whitespace) and put them in a box

	$data =~ s/(\s*)(\S+)(\s*)/$1\[$2\]$3/g;

	return $data;
}

sub switch_bracket {
	my $data = shift;
	my $output;

	my %brackets = (
                        '(('   => '))',
                        '-=('  => ')=-',
                        '-=['  => ']=-',
                        '-={'  => '}=-',
                        '-=|(' => ')|=-',
                        '-=|[' => ']|=-',
                        '-=|{' => '}|=-',
                        '.:>'  => '<:.',
                       );

	foreach (keys %brackets) {
		for my $times (2 .. 3) {
			my $pre  = $_;
			my $post = $brackets{$_};
			$pre  =~ s/(.)/$1 x $times/eg;
			$post =~ s/(.)/$1 x $times/eg;

			$brackets{$pre} = $post;
		}
	}

	$brackets{'!---?['} = ']?---!';
	$brackets{'(qp=>'}  = '<=qp)';
	$brackets{'----->'} = '<-----';

	my $pre = (keys(%brackets))[int(rand(keys(%brackets)))];
	my $post = $brackets{$pre};

	$output = "$pre $data $post";

	return $output;
}

sub switch_chars {
	my $data = shift;
	my $output;

	foreach my $char (split //, $data) {
		$output .= "$char\n";
	}
	return $output;
}

sub switch_command {
	my ($data, $channel_rec) = @_;

	# -out <command>

	$misc{command_out} = $misc{queue}{$misc{counter}}{command}{out};
	$misc{switch_command_out} = 1;

	# -in <command>

	$misc{command_in} = '';
	my $option_command_in = $misc{queue}{$misc{counter}}{command}{in};

	if ($option_command_in) {
		Irssi::signal_add_first('command msg', 'signal_command_msg');
		$channel_rec->command("$option_command_in $data");
		Irssi::signal_remove('command msg', 'signal_command_msg');
		return $misc{command_in};
	}

	return $data;
}

sub switch_color {
	my $data = shift;
	my (@colors, $option_color_split, $output, $split);
	my @all_colors = qw(2 3 5 6 8 10);

	@all_colors = map { $_ = sprintf('%02d', $_) } @all_colors;

	if ($misc{queue}{$misc{counter}}{color}{'split'}) {
		$option_color_split = $misc{queue}{$misc{counter}}{color}{'split'};
	} else {
		$option_color_split = 'words';
	}

	if ($option_color_split eq 'chars') {
		$split = '';
	} elsif ($option_color_split eq 'lines') {
		$split = "\n";
	} elsif ($option_color_split eq 'words') {
		$split = '\s+';
	} elsif ($option_color_split eq 'rchars') {
		$split = '.' x rand(10);
	} elsif ($option_color_split eq 'paragraph') {
		$split = "\n";
	} else {
		$split = '\s+';
	}

	@colors = @all_colors;

	for (split /($split)/, $data) {
		my $color = $colors[rand(@colors)];

		if ($_ eq ',') {
			$output .= "\003" . $color . ',,';
			if ($option_color_split ne 'paragraph') {
				@colors = grep { $_ ne $color } @all_colors;
			} else {
				@colors = ($color);
			}
		} elsif (/^\s*$/) {
			$output .= $_;
		} else {
			$output .= "\003" . $color . $_;
			if ($option_color_split ne 'paragraph') {
				@colors = grep { $_ ne $color } @all_colors;
			} else {
				@colors = ($color);
			}
		}
	}

	return $output;
}

sub switch_cowsay {
	my $data = shift;
	my $skip = 1;
	my ($output, @cows, %cow, $cow, @cache1, @cache2);

	unless (-e $option{dau_cowsay_path}) {
		print_err('cowsay not found. More information: ' .
		          "%9${k}dau --help -setting dau_cowsay_path%9");
		return;
	}

	if ($misc{queue}{$misc{counter}}{cowsay}{cow}) {
		$cow = $misc{queue}{$misc{counter}}{cowsay}{cow};
	} else {
		while ($option{dau_cowsay_cowlist} =~ /\s*([^,\s]+)\s*,?/g) {
			$cow{$1} = 1;
		}
		foreach my $cow (keys %{ $switches{combo}{cowsay}{cow} }) {
			if (lc($option{dau_cowsay_cowpolicy}) eq 'allow') {
				push(@cows, $cow)
					unless ($cow{$cow});
			} elsif (lc($option{dau_cowsay_cowpolicy}) eq 'deny') {
				push(@cows, $cow)
					if ($cow{$cow});
			} else {
				print_err('Invalid value for setting dau_cowsay_cowpolicy. ' .
				          'More information: ' .
				          "%9${k}dau --help -setting dau_cowsay_cowpolicy%9");
				return;
			}
		}
		if (@cows == 0) {
			print_err('Cannot find cowsay-cows. Please check your cowsay installation ' .
			          "or dau.pl's settings for %9--cowsay%9 (%9${k}set dau_cowsay%9)");
			return;
		}
		$cow = $cows[rand(@cows)];
	}

	# Run cowsay

	local(*HIS_IN, *HIS_OUT, *HIS_ERR);

	my $childpid = open3(*HIS_IN, *HIS_OUT, *HIS_ERR, $option{dau_cowsay_path}, '-f', $cow);

	print HIS_IN $data or return;
	close(HIS_IN) or return;

	my @errlines = <HIS_ERR>;
	my @outlines = <HIS_OUT>;
	close(HIS_ERR) or return;
	close(HIS_OUT) or return;

	waitpid($childpid, 0);
	if ($?) {
		print_err("That child exited with wait status of $?");
	}

	# Error during execution? Print errors and return

	unless (@errlines == 0) {
		print_err('Error during execution of cowsay');
		foreach my $line (@errlines) {
			print_err($line);
		}
		return;
	}

	if ($option{dau_cowsay_print_cow}) {
		print_out("using cowsay-cow $cow");
	}

	foreach (@outlines) {
		chomp;
		if (/^\s*$/ && $skip) {
			next;
		} else {
			$skip = 0;
		}
		push(@cache1, $_);
	}
	$skip = 1;
	foreach (reverse @cache1) {
		chomp;
		if (/^\s*$/ && $skip) {
			next;
		} else {
			$skip = 0;
		}
		push(@cache2, $_);
	}
	foreach (reverse @cache2) {
		$output .= "$_\n";
	}

	return $output;
}

sub switch_delimiter {
	my $data = shift;
	my $output;
	my $option_delimiter_string;

	if ($misc{queue}{$misc{counter}}{delimiter}{string}) {
		$option_delimiter_string = $misc{queue}{$misc{counter}}{delimiter}{string};
	} else {
		$option_delimiter_string = $option{dau_delimiter_string};
	}

	foreach my $char (split //, $data) {
		$output .= $char . $option_delimiter_string;
	}
	return $output;
}

sub switch_dots {
	my $data = shift;

	$data =~ s/[,;.:?!]*\s+/
	           if (rand(10) < 3) {
	               (rand(10) >= 5 ? ' ' : '')
	               .
	               ('...' . '.' x rand(5))
	               .
	               (rand(10) >= 5 ? ' ' : '')
	           } else { ' ' }
	          /egox;
	rand(10) >= 5 ? $data .= ' ' : 0;
	$data .= ('...' . '.' x rand(10));

	return $data;
}

sub switch_figlet {
	my $data = shift;
	my $skip = 1;
	my ($output, @fonts, %font, $font, @cache1, @cache2);

	unless (-e $option{dau_figlet_path}) {
		print_err('figlet not found. More information: ' .
		          "%9${k}dau --help -setting dau_figlet_path%9");
		return;
	}

	if ($misc{queue}{$misc{counter}}{figlet}{font}) {
		$font = $misc{queue}{$misc{counter}}{figlet}{font};
	} else {
		while ($option{dau_figlet_fontlist} =~ /\s*([^,\s]+)\s*,?/g) {
			$font{$1} = 1;
		}
		foreach my $font (keys %{ $switches{combo}{figlet}{font} }) {
			if (lc($option{dau_figlet_fontpolicy}) eq 'allow') {
				push(@fonts, $font)
					unless ($font{$font});
			} elsif (lc($option{dau_figlet_fontpolicy}) eq 'deny') {
				push(@fonts, $font)
					if ($font{$font});
			} else {
				print_err('Invalid value for setting dau_figlet_fontpolicy. ' .
				          'More information: ' .
				          "%9${k}dau --help -setting dau_figlet_fontpolicy%9");
				return;
			}
		}
		if (@fonts == 0) {
			print_err('Cannot find figlet-fonts. Please check your figlet installation ' .
			          "or dau.pl's settings for %9--figlet%9 (%9${k}set dau_figlet%9)");
			return;
		}
		$font = $fonts[rand(@fonts)];
	}

	# Run figlet

	local(*HIS_IN, *HIS_OUT, *HIS_ERR);

	my $childpid = open3(*HIS_IN, *HIS_OUT, *HIS_ERR, $option{dau_figlet_path}, '-f', $font);

	print HIS_IN $data or return;
	close(HIS_IN) or return;

	my @errlines = <HIS_ERR>;
	my @outlines = <HIS_OUT>;
	close(HIS_ERR) or return;
	close(HIS_OUT) or return;

	waitpid($childpid, 0);
	if ($?) {
		print_err("That child exited with wait status of $?");
	}

	# Error during execution? Print errors and return

	unless (@errlines == 0) {
		print_err('Error during execution of figlet');
		foreach my $line (@errlines) {
			print_err($line);
		}
		return;
	}

	if ($option{dau_figlet_print_font}) {
		print_out("using figlet-font $font");
	}

	foreach (@outlines) {
		chomp;
		if (/^\s*$/ && $skip) {
			next;
		} else {
			$skip = 0;
		}
		push(@cache1, $_);
	}
	$skip = 1;
	foreach (reverse @cache1) {
		chomp;
		if (/^\s*$/ && $skip) {
			next;
		} else {
			$skip = 0;
		}
		push(@cache2, $_);
	}
	foreach (reverse @cache2) {
		$output .= "$_\n";
	}

	return $output;
}

sub switch_greet {
	my $channel = $_[1];
	my (@nicks, $output);

	if (defined($channel) && $channel && $channel->{type} eq 'CHANNEL') {
		foreach my $nick ($channel->nicks()) {
			if ($channel->{server}->{nick} ne $nick->{nick}) {
				push(@nicks, $nick->{nick});
			}
		}
	}

	if (@nicks == 0) {
		return '';
	}

	if ($misc{queue}{$misc{counter}}{greet}{whom} eq 'rnick') {
		$output = 'hi @ ' . $nicks[rand(@nicks)];
	} else {
		$output = 'hi @ ';
		@nicks = sort { lc($a) cmp lc($b) } @nicks;
		for my $nick (@nicks) {
			$output .= "$nick, ";
		}
		$output =~ s/, $//;
	}

	return $output;
}

sub switch_leet {
	my $data = shift;

	$_ = $data;
	s'fucker'f@#$er'gi;
	s/hacker/h4x0r/gi;
	s/sucker/sux0r/gi;
	s/fear/ph34r/gi;
	s/dude/d00d/gi;
	s/rude/r00d/gi;
	s/\bthe\b/d4/gi;
	s/\byou\b/j00/gi;
	s/\bdo\b/d00/gi;
	s/\b(\w{3,})er\b/${1}0r/gi;
	tr/lLzZeEaAsSgGtTbBqQoOiIcC/11223344556677889900||((/;
	s/(\w)/rand(100) < 50 ? "\u$1" : "\l$1"/ge;

	return $_;
}

sub switch_me {
	my $data = shift;

	$misc{command_out} = 'ACTION';

	return $data;
}

# &switch_mix by Martin Kihlgren <zond@troja.ath.cx>
# slightly modified by myself

sub switch_mix {
	my $data = shift;
	my $output;

	while ($data =~ s/(\s*)([^\w]*)([\w]+)([^\w]*)(\s+[^\w]*\w+[^\w]*\s*)*/$5/) {
		my $prespace = $1;
		my $prechars = $2;
		my $w = $3;
		my $postchars = $4;
		$output = $output . $prespace . $prechars . substr($w,0,1);
		my $middle = substr($w,1,length($w) - 2);
		while ($middle =~ s/(.)(.*)/$2/) {
			if (rand() > 0.1) {
				$middle = $middle . $1;
			} else {
				$output = $output . $1;
			}
		}
		if (length($w) > 1) {
			$output = $output . substr($w, length($w) - 1, 1);
		}
		$output = $output . $postchars;
	}

	return $output;
}

sub switch_mixedcase {
	my $data = shift;

	$data =~ s/([[:alpha:]])/rand(100) < 50 ? uc($1) : lc($1)/ge;

	return $data;
}

sub switch_moron {
	my ($data, $channel_rec) = @_;
	my $output;
	my $option_eol_style;
	my $option_substitutions_permissions;

	# Get values of settings/switchs

	if ($misc{queue}{$misc{counter}}{moron}{eol}) {
		$option_eol_style = $misc{queue}{$misc{counter}}{moron}{eol};
	} else {
		$option_eol_style = $option{dau_moron_eol_style};
	}

	if ($misc{queue}{$misc{counter}}{moron}{perm}) {
		$option_substitutions_permissions = $misc{queue}{$misc{counter}}{moron}{perm};
	} else {
		$option_substitutions_permissions = $option{dau_moron_substitutions_permissions};
	}

	# -omega yes

	my $omega;

	if ($misc{queue}{$misc{counter}}{moron}{omega} eq 'yes') {
		my @words = qw(omfg lol wtf);

		foreach (split / (?=\w+\b)/, $data) {
			if (rand(100) < 20) {
				$omega .= ' ' . $words[rand(@words)] . " $_";
			} else {
				$omega .= ' ' . $_;
			}
		}

		$omega =~ s/\s*,\s+\@/ @/g;
		$omega =~ s/^\s+//;
	}

	$_ = $omega || $data;

	# Generate list of nicks in current channel for later use

	my @nicks;

	if (defined($channel_rec) && $channel_rec && $channel_rec->{type} eq 'CHANNEL') {
		foreach my $nick ($channel_rec->nicks()) {
			if ($channel_rec->{server}->{nick} ne $nick->{nick}) {
				push(@nicks, quotemeta($nick->{nick}));
			}
		}
	}

	# Remove puntuation marks at EOL and ensure there is a single space at EOL.
	# This is necessary because the EOL-styles 'new' and 'classic' put them at
	# EOL. If EOL-style is set to 'nothing' don't do this.

	s/\s*([,;.:?!])*\s*$// unless ($option_eol_style eq 'nothing');
	my $lastchar = $1;

	# Only whitespace? Remove it.

	s/^\s+$//;

	# Some substitutions which cannot be turned off

	tr/'/`/;

	# english

	s/\bthe\b/teh/go;

	{
		local $" = '|';
		eval { # Catch strange error
			s/^(@nicks): (.+)/$2 @ $1/;
		};
	}

	{
		# possible asterisks

		my @a = ('*', 'Ü');

		# choose one

		my $a = $a[int(rand(@a))];

		# replacement

		s/\*g\*/$a . 'ggg' . ('g' x rand(10)) . $a/egio;
	}

	{
		# Use of uninitialized value in concatenation (.) or string at...
		# (the optional dash ($1) in the regular expressions)

		no warnings;

		if (int(rand(2))) {
			s/:(-)?\)/^^/go;
		} else {
			s/:(-)?\)/':' . $1 . ')))' . (')' x rand(10)) . ('9' x rand(4))/ego;
		}

		s/;(-)?\)/';' . $1 . ')))' . (')' x rand(10)) . ('9' x rand(4))/ego;
		s/:(-)?\(/':' . $1 . '(((' . ('(' x rand(10)) . ('8' x rand(4))/ego;
		s#(^|\s):(-)?/(\s|$)#$1 . ':' . $2 . '///' . ('/' x rand(10)) . ('7' x rand(4)) . $3#ego;
	}

	# Your own substitutions from file

	if ($option_substitutions_permissions =~ /^[01][01]1$/) {
		my $file = "$option{dau_files_root_directory}/$option{dau_files_moron_own_substitutions}";

		unless (-e $file && -r $file) {
			print_err("cannot access $file properly");
			return;
		}
		unless (my $return = do $file) {
			if ($@) {
				print_err("parsing $file failed: $@");
			}
			unless (defined($return)) {
				print_err("'do $file' failed");
			}
		}
	}

	# Substitutions making sense performed on german text.
	# The user can turn them off/on

	if ($option_substitutions_permissions =~ /^1[01][01]$/) {

		# verbs

		s/\b(f)reuen\b/$1roien/gio;
		s/\b(f)reue\b/$1roie/gio;
		s/\b(f)reust\b/$1roist/gio;
		s/\b(f)reut\b/$1roit/gio;

		s/\b(f)unktionieren\b/$1unzen/gio;
		s/\b(f)unktioniere\b/$1unze/gio;
		s/\b(f)unktionierst\b/$1unzt/gio;
		s/\b(f)unktioniert\b/$1unzt/gio;

		s/\b(h)olen\b/$1ohlen/gio;
		s/\b(h)ole\b/$1ohle/gio;
		s/\b(h)olst\b/$1ohlst/gio;
		s/\b(h)olt\b/$1ohlt/gio;

		s/\b(k)onfigurieren\b/$1 eq 'k' ? 'confen' : 'Confen'/egio;
		s/\b(k)onfiguriere\b/$1 eq 'k' ? 'confe' : 'Confe'/egio;
		s/\b(k)onfigurierst\b/$1 eq 'k' ? 'confst' : 'Confst'/egio;
		s/\b(k)onfiguriert\b/$1 eq 'k' ? 'conft' : 'Conft'/egio;

		s/\b(l)achen\b/$1ölen/gio;
		s/\b(l)ache\b/$1öle/gio;
		s/\b(l)achst\b/$1ölst/gio;
		s/\b(l)acht\b/$1ölt/gio;

		s/\b(m)achen\b/$1 eq 'm' ? 'tun' : 'Tun'/egio;
		s/\b(m)ache\b/$1 eq 'm' ? 'tu' : 'Tu'/egio;
		s/\b(m)achst\b/$1 eq 'm' ? 'tust' : 'Tust'/egio;

		s/\b(n)erven\b/$1erfen/gio;
		s/\b(n)erve\b/$1erfe/gio;
		s/\b(n)ervst\b/$1erfst/gio;
		s/\b(n)ervt\b/$1erft/gio;

		s/\b(p)rojizieren\b/$1rojezieren/gio;
		s/\b(p)rojiziere\b/$1rojeziere/gio;
		s/\b(p)rojizierst\b/$1rojezierst/gio;
		s/\b(p)rojiziert\b/$1rojeziert/gio;

		s/\b(r)egistrieren\b/$1egestrieren/gio;
		s/\b(r)egistriere\b/$1egestriere/gio;
		s/\b(r)egistrierst\b/$1egestrierst/gio;
		s/\b(r)egistriert\b/$1egestriert/gio;

		s/\b(s)pazieren\b/$1patzieren/gio;
		s/\b(s)paziere\b/$1patziere/gio;
		s/\b(s)pazierst\b/$1patzierst/gio;
		s/\b(s)paziert\b/$1patziert/gio;

		# other

		s/\bdanke\b/
		  if (int(rand(2)) == 0) {
		      'thx'
		  } else {
		      'danks'
		  }
		 /ego;
		s/\bDanke\b/
		  if (int(rand(2)) == 0) {
		      'Thx'
		  } else {
		      'Danks'
		  }
		 /ego;

		s/\blol\b/
		  if (int(rand(2)) == 0) {
		      'löl'
		  } else {
		      'löllens'
		  }
		 /ego;
		s/\bLOL\b/
		  if (int(rand(2)) == 0) {
		      'LÖL'
		  } else {
		      'LÖLLENS'
		  }
		 /ego;

		s/\br(?:ü|ue)ckgrat\b/
		  if (int(rand(3)) == 0) {
		      'rückgrad'
		  } elsif (int(rand(3)) == 1) {
		      'rückrad'
		  } else {
		      'rückrat'
		  }
		 /ego;
		s/\bR(?:ü|ue)ckgrat\b/
		  if (int(rand(3)) == 0) {
		      'Rückgrad'
		  } elsif (int(rand(3)) == 1) {
		      'Rückrad'
		  } else {
		      'Rückrat'
		  }
		 /ego;

		s/\b(i)st er\b/$1ssa/gio;
		s/\bist\b/int(rand(2)) ? 'is' : 'iss'/ego;
		s/\bIst\b/int(rand(2)) ? 'Is' : 'Iss'/ego;

		s/\b(d)a(?:ss|ß) du\b/$1asu/gio;
		s/\b(d)a(?:ss|ß)\b/$1as/gio;

		s/\b(s)ag mal\b/$1amma/gio;
		s/\b(n)ochmal\b/$1omma/gio;
		s/(m)al\b/$1a/gio;

		s/\b(u)nd nun\b/$1nnu/gio;
		s/\b(n)un\b/$1u/gio;
		s/\b(u)nd\b/$1nt/gio;

		s/\b(s)oll denn\b/$1olln/gio;
		s/\b(d)enn\b/$1en/gio;

		s/\b(s)o eine\b/$1onne/gio;
		s/\b(e)ine\b/$1 eq 'e' ? 'ne' : 'Ne'/egio;

		s/\bkein problem\b/NP/gio;
		s/\b(p)roblem\b/$1rob/gio;
		s/\b(p)robleme\b/$1robs/gio;

		s/\b([[:alpha:]]{2,})st du\b/${1}su/gio;
		s/\b(a)ber\b/$1bba/gio;
		s/\b(a)chso\b/$1xo/gio;
		s/\b(a)dresse\b/$1ddresse/gio;
		s/\b(a)ggressiv\b/$1gressiv/gio;
		s/\b(a)nf(?:ä|ae)nger\b/$1 eq 'a' ? 'n00b' : 'N00b'/egio;
		s/\b(a)sozial\b/$1ssozial/gio;
		s/\b(a)u(?:ss|ß)er\b/$1user/gio;
		s/\b(a)utor/$1uthor/gio;
		s/\b(b)(?:ox|(?:ü|ue)chse)\b/$1yxe/gio;
		s/\b(b)asta\b/$1 eq 'b' ? 'pasta' : 'Pasta'/egio;
		s/\b(b)i(?:ss|ß)chen\b/$1ischen/gio;
		s/\b(b)illard\b/$1illiard/gio;
		s/\b(b)ist\b/$1is/gio;
		s/\b(b)itte\b/$1 eq 'b' ? 'plz' : 'Plz'/egio;
		s/\b(b)lo(?:ss|ß)\b/$1los/gio;
		s/\b(b)rillant\b/$1rilliant/gio;
		s/\b(c)hannel\b/$1 eq 'c' ? 'kanal' : 'Kanal'/egio;
		s/\b(c)hat\b/$1hatt/gio;
		s/\b(c)ool\b/$1 eq 'c' ? 'kewl' : 'Kewl'/egio;
		s/\b(d)(?:ä|ae)mlich\b/$1ähmlich/gio;
		s/\b(d)etailliert\b/$1etailiert/gio;
		s/\b(d)ilettantisch\b/$1illetantisch/gio;
		s/\b(d)irekt\b/$1ireckt/gio;
		s/\b(d)iskussion\b/$1isskusion/gio;
		s/\b(d)istribution/$1ystrubution/gio;
		s/\b(e)igentlich\b/$1igendlich/gio;
		s/\b(e)inzige\b/$1inzigste/gio;
		s/\b(e)nd/$1nt/gio;
		s/\b(e)ntschuldigung\b/$1 eq 'e' ? 'sry' : 'Sry'/egio;
		s/\b(f)ilm\b/$1 eq 'f' ? 'movie' : 'Movie'/egio;
		s/\b(f)lachbettscanner\b/$1lachbrettscanner/gio;
		s/\b(f)reu\b/$1roi/gio;
		s/\b(g)ay\b/$1hey/gio;
		s/\b(g)alerie\b/$1allerie/gio;
		s/\b(g)ebaren\b/$1ebahren/gio;
		s/\b(g)elatine\b/$1elantine/gio;
		s/\b(g)eratewohl\b/$1eradewohl/gio;
		s/\b(g)ibt es\b/$1ibbet/gio;
		s/\b(h)(?:ä|ae)ltst\b/$1älst/gio;
		s/\b(h)(?:ä|ae)sslich/$1äslich/gio;
		s/\b(h)aneb(?:ü|ue)chen\b/$1ahnebüchen/gio;
		s/\b(h)at\b/$1att/gio;
		s/\b(i)mmobilie/$1mobilie/gio;
		s/\b(i)nteressant\b/$1nterressant/gio;
		s/\b(i)ntolerant\b/$1ntollerant/gio;
		s/\b(i)rgend/$1rgent/gio;
		s/\b(j)a\b/$1oh/gio;
		s/\b(j)etzt\b/$1ez/gio;
		s/\b(k)affee\b/$1affe/gio;
		s/\b(k)aputt\b/$1aput/gio;
		s/\b(k)arussell\b/$1arussel/gio;
		s/\b(k)iste\b/$1 eq 'k' ? 'byxe' : 'Byxe'/egio;
		s/\b(k)lempner\b/$1lemptner/gio;
		s/\b(k)r(?:ä|ae)nker\b/$1ranker/gio;
		s/\b(k)rise\b/$1riese/gio;
		s/\b(l)etal\b/$1ethal/gio;
		s/\b(l)eute\b/$1 eq 'l' ? 'ppl' : 'Ppl'/egio;
		s/\b(l)ibyen\b/$1ybien/gio;
		s/\b(l)izenz\b/$1izens/gio;
		s/\b(l)oser\b/$1ooser/gio;
		s/\b(l)ustig/$1ölig/gio;
		s/\b(m)aschine\b/$1aschiene/gio;
		s/\b(m)illennium\b/$1illenium/gio;
		s/\b(m)iserabel\b/$1ieserabel/gio;
		s/\b(m)it dem\b/$1im/gio;
		s/\b(m)orgendlich\b/$1orgentlich/gio;
		s/\b(n)(?:ä|ae)mlich\b/$1ähmlich/gio;
		s/\b(n)ein\b/$1eh/gio;
		s/\b(n)ewbie\b/$100b/gio;
		s/\b(n)iveau/$1iwo/gio;
		s/\b(n)ur\b/$1uhr/gio;
		s/\b(o)riginal\b/$1rginal/gio;
		s/\b(p)aket\b/$1acket/gio;
		s/\b(p)l(?:ö|oe)tzlich\b/$1lözlich/gio;
		s/\b(p)ogrom\b/$1rogrom/gio;
		s/\b(p)rogramm\b/$1roggie/gio;
		s/\b(p)rogramme\b/$1roggies/gio;
		s/\b(p)sychiater\b/$1sychater/gio;
		s/\b(p)ubert(?:ä|ae)t\b/$1upertät/gio;
		s/\b(q)uarz\b/$1uartz/gio;
		s/\b(q)uery\b/$1uerry/gio;
		s/\b(r)(o)(t?fl)(o)(l)\b/$1 . ($2 eq 'o' ? 'ö' : 'Ö') . $3 . ($4 eq 'o' ? 'ö' : 'Ö') . $5/egio;
		s/\b(r)(o)(t?fl)\b/$1 . ($2 eq 'o' ? 'ö' : 'Ö') . $3/egio;
		s/\b(r)eparatur\b/$1eperatur/gio;
		s/\b(r)eply\b/$1eplay/gio;
		s/\b(r)essource\b/$1esource/gio;
		s/\b(s)atellit\b/$1attelit/gio;
		s/\b(s)cherz\b/$1chertz/gio;
		s/\b(s)elig\b/$1eelig/gio;
		s/\b(s)eparat\b/$1eperat/gio;
		s/\b(s)eriosit(?:ä|ae)t\b/$1erösität/gio;
		s/\b(s)orry\b/$1ry/gio;
		s/\b(s)pelunke\b/$1ilunke/gio;
		s/\b(s)piel\b/$1 eq 's' ? 'game' : 'Game'/egio;
		s/\b(s)tabil\b/$1tabiel/gio;
		s/\b(s)tandard\b/$1tandart/gio;
		s/\b(s)tegreif\b/$1tehgreif/gio;
		s/\b(s)ympathisch\b/$1ymphatisch/gio;
		s/\b(s)yntax\b/$1ynthax/gio;
		s/\b(t)era/$1erra/gio;
		s/\b(t)oler/$1oller/gio;
		s/\b(u)ngef(?:ä|ae)hr\b/$1ngefär/gio;
		s/\b(v)ielleicht\b/$1ileicht/gio;
		s/\b(v)oraus/$1orraus/gio;
		s/\b(w)(?:ä|ae)re\b/$1ähre/gio;
		s/\b(w)as du\b/$1asu/gio;
		s/\b(w)eil du\b/$1eilu/gio;
		s/\b(w)enn du\b/$1ennu/gio;
		s/\b(w)ider/$1ieder/gio;
		s/\b(w)ieso\b/$1iso/gio;
		s/\b(z)iemlich\b/$1iehmlich/gio;
		s/\b(z)umindest\b/$1umindestens/gio;
		s/\bGra([dt])/$1 eq 'd' ? 'Grat' : 'Grad'/ego;
		s/\bNicht\b/int(rand(2)) ? 'Net' : 'Ned'/ego;
		s/\bSei([dt])\b/$1 eq 'd' ? 'Seit' : 'Seid'/ego;
		s/\bTo([td])/$1 eq 't' ? 'Tod' : 'Tot'/ego;
		s/\bWa(h)?r/$1 eq 'h' ? 'War' : 'Wahr'/ego;
		s/\bWeis(s)?/$1 eq 's' ? 'Weis' : 'Weiss'/ego;
		s/\bgra([dt])/$1 eq 'd' ? 'grat' : 'grad'/ego;
		s/\bnicht\b/int(rand(2)) ? 'net' : 'ned'/ego;
		s/\bok(?:ay)?\b/K/gio;
		s/\bsei([dt])\b/$1 eq 'd' ? 'seit' : 'seid'/ego;
		s/\bto([td])/$1 eq 't' ? 'tod' : 'tot'/ego;
		s/\bviel gl(?:ü|ue)ck\b/GL/gio;
		s/\bwa(h)?r/$1 eq 'h' ? 'war' : 'wahr'/ego;
		s/\bweis(s)?/$1 eq 's' ? 'weis' : 'weiss'/ego;
	}

	if ($option_substitutions_permissions =~ /^[01]1[01]$/) {
		s/\b([[:alpha:]]+[b-np-tv-z])er\b/${1}a/go;
		s/\b([[:alpha:]]+)ck/${1}q/go;
		s/ü|ue/y/go;
		s/Ü|Ue/Y/go;
		s/\b([fv])(?=[[:alpha:]]{2,})/
		  if (rand(10) <= 4) {
		      if ($1 eq 'f') {
		          'v'
		      }
		      else {
		          'f'
		      }
		  } else {
		      $1
		  }
		 /egox;
		s/\b([FV])(?=[[:alpha:]]{2,})/
		  if (rand(10) <= 4) {
		      if ($1 eq 'F') {
		          'V'
		      }
		      else {
		          'F'
		      }
		  } else {
		      $1
		  }
		  /egox;
		s/\b([[:alpha:]]{2,})([td])\b/
		  if (rand(10) <= 4) {
		      if ($2 eq 't') {
		          "$1d"
		      }
		      else {
		          "$1t"
		      }
		  } else {
		      "$1$2"
		  }
		 /egox;
		s/\b([[:alpha:]]{2,})ie/
		  if (rand(10) <= 4) {
		      "$1i"
		  } else {
		      "$1ie"
		  }
		 /egox;
	}

	$data = $_;

	# Swap characters with characters near at the keyboard

	my %mark;
	my %chars = (
	             'a' => [ 's' ],
	             'b' => [ 'v', 'n' ],
	             'c' => [ 'x', 'v' ],
	             'd' => [ 's', 'f' ],
	             'e' => [ 'w', 'r' ],
	             'f' => [ 'd', 'g' ],
	             'g' => [ 'f', 'h' ],
	             'h' => [ 'g', 'j' ],
	             'i' => [ 'u', 'o' ],
	             'j' => [ 'h', 'k' ],
	             'k' => [ 'j', 'l' ],
	             'l' => [ 'k', 'ö' ],
	             'm' => [ 'n' ],
	             'n' => [ 'b', 'm' ],
	             'o' => [ 'i', 'p' ],
	             'p' => [ 'o', 'ü' ],
	             'q' => [ 'w' ],
	             'r' => [ 'e', 't' ],
	             's' => [ 'a', 'd' ],
	             't' => [ 'r', 'z' ],
	             'u' => [ 'z', 'i' ],
	             'v' => [ 'c', 'b' ],
	             'w' => [ 'q', 'e' ],
	             'x' => [ 'y', 'c' ],
	             'y' => [ 'x' ],
	             'z' => [ 't', 'u' ],
	             'A' => [ 'S' ],
	             'B' => [ 'V', 'N' ],
	             'C' => [ 'X', 'V' ],
	             'D' => [ 'S', 'F' ],
	             'E' => [ 'W', 'R' ],
	             'F' => [ 'D', 'G' ],
	             'G' => [ 'F', 'H' ],
	             'H' => [ 'G', 'J' ],
	             'I' => [ 'U', 'O' ],
	             'J' => [ 'H', 'K' ],
	             'K' => [ 'J', 'L' ],
	             'L' => [ 'K', 'Ö' ],
	             'M' => [ 'N' ],
	             'N' => [ 'B', 'M' ],
	             'O' => [ 'I', 'P' ],
	             'P' => [ 'O', 'Ü' ],
	             'Q' => [ 'W' ],
	             'R' => [ 'E', 'T' ],
	             'S' => [ 'A', 'D' ],
	             'T' => [ 'R', 'Z' ],
	             'U' => [ 'Z', 'I' ],
	             'V' => [ 'C', 'B' ],
	             'W' => [ 'Q', 'E' ],
	             'X' => [ 'Y', 'C' ],
	             'Y' => [ 'X' ],
	             'Z' => [ 'T', 'U' ],
	            );

	# Do not replace one character twice
	# Therefore every replace-position will be marked

	for (0 .. length($data)) {
		$mark{$_} = 0;
	}

	for (0 .. rand(length($data))/20) {
		my $pos = int(rand(length($data)));
		pos $data = $pos;
		unless ($mark{$pos} == 1)  {
			no locale;
			if ($data =~ /\G([A-Za-z])/g) {
				my $replacement = $chars{$1}[int(rand(@{ $chars{$1} }))];
				substr($data, $pos, 1, $replacement);
				$mark{$pos} = 1;
			}
		}
	}

	# plenk

	$data =~ s/(\w+)([,;.:?!]+)(\s+|$)/
	           if (rand(10) <= 8 || $3 eq '') {
	               "$1 $2$3"
	           } else {
	               "$1$2"
	           }
	          /egox;

	# Mix in some typos

	foreach my $word (split /([\s\n])/, $data) {
		if ((rand(100) <= 20) && length($word) > 1) {
			my $random = rand(length($word));
			$random = 2
				if ($random == 1);
			(substr($word, $random, 1), substr($word, $random-1, 1)) =
			(substr($word, $random-1, 1), substr($word, $random, 1));
		}
		$output .= $word;
	}

	# default behaviour: uppercase text

	$output = uc($output) unless ($misc{queue}{$misc{counter}}{moron}{uppercase} eq 'no');

	# do something at EOL

	# 'classic' style

	if ($option_eol_style eq 'classic' ||
	   ($option_eol_style ne 'nothing' && $lastchar eq '!'))
	{
		$output .= ' ';

		my @punct = qw(? !);
		$output .= $punct[rand(@punct)] x int(rand(5))
			for (1..15);

		if ($lastchar eq '?') {
			$output .= '?' x (int(rand(4))+1);
		} elsif ($lastchar eq '!') {
			$output .= '!' x (int(rand(4))+1);
		}

		if ($output =~ /\?$/) {
			$output .= "ß" x int(rand(10));
		} elsif ($output =~ /!$/) {
			$output .= "1" x int(rand(10));
		}
	}

	# 'new' style

	elsif ($option_eol_style eq 'new') {
		my $random = rand(100);

		# many punctuation marks at EOL

		$output .= ' ';

		if ($random <= 70) {
			my @punct = qw(? !);
			$output .= $punct[rand(@punct)] x int(rand(5))
				for (1..15);

			if ($lastchar eq '?') {
				$output .= '?' x (int(rand(4))+1);
			} elsif ($lastchar eq '!') {
				$output .= '!' x (int(rand(4))+1);
			}

			if ($output =~ /\?$/) {
				$output .= "ß" x int(rand(10));
			} elsif ($output =~ /!$/) {
				$output .= "1" x int(rand(10));
			}
		}

		# or '?¿?' at EOL

		elsif ($random <= 85) {
			$output .= '?¿?';
		}

		# or "=\n?" at EOL

		else {
			$output .= "=\n?";
		}
	}

	return $output;
}

sub switch_nothing {
	my $data = shift;

	return $data;
}

sub switch_reverse {
	my $data = shift;

	$data = reverse($data);

	return $data;
}

sub switch_stutter {
	my $data = shift;
	my $output;
	my @words = qw(eeeh oeeeh aeeeh);

	foreach (split / (?=\w+\b)/, $data) {
		if (rand(100) < 20) {
			$output .= ' ' . $words[rand(@words)] . ", $_";
		} else {
			$output .= ' ' . $_;
		}
	}

	$output =~ s/\s*,\s+\@/ @/g;

	for (1 .. rand(length($output)/5)) {
		pos $output = rand(length($output));
		$output =~ s/\G ([[:alpha:]]+)\b/ $1, $1/;
	}
	for (1 .. rand(length($output)/10)) {
		pos $output = rand(length($output));
		$output =~ s/\G([[:alpha:]])/$1 . ($1 x rand(3))/e;
	}

	$output =~ s/^\s+//;

	return $output;
}

sub switch_underline {
	my $data = shift;

	if ($misc{queue}{$misc{counter}}{underline}{spaces} eq 'no') {
		$data = "\037$data\037";
	} else {
		$data = "\037 $data \037";
	}

	return $data;
}

sub switch_uppercase {
	my $data = shift;

	$data = uc($data);

	return $data;
}

sub switch_words {
	my $data = shift;
	my $output;
	my @numbers;

	if ($option{dau_words_range} =~ /^([1-9])-([1-9])$/) {
		my $x = $1;
		my $y = $2;
		unless ($x <= $y) {
			print_err('Invalid value for setting dau_words_range. ' .
			          "More information: %9${k}dau --help -setting dau_words_range%9");
			return;
		}
		if ($x == $y) {
			push(@numbers, $x);
		} elsif ($x < $y) {
			for (my $i = $x; $i <= $y; $i++) {
				push(@numbers, $i);
			}
		}
	} else {
		print_err('Invalid value for setting dau_words_range. ' .
		          "More information: %9${k}dau --help -setting dau_words_range%9");
		return;
	}
	my $random = $numbers[rand(@numbers)];
	while ($data =~ /((?:.*?(?:\s+|$)){1,$random})/g) {
		$output .= "$1\n"
			unless (length($1) == 0);
		$random = $numbers[rand(@numbers)];
	}

	$output =~ s/\s*$//;

	return $output;
}

################################################################################
# Subroutines (signals)
################################################################################

sub signal_command_msg {
	my ($args, $server, $witem) = @_;

	$args =~ /^(?:-\S+\s)?(?:\S*)\s(.*)/;
	my $data = $1;

	$misc{command_in} .= "$data\n";

	Irssi::signal_stop();
}

sub signal_complete_word {
	my ($list, $window, $word, $linestart, $want_space) = @_;

	# Parsing the commandline for dau.pl is relatively complicated.
	# TAB-Completion depends on commandline parsing in dau.pl.
	# Script autors looking for a simple example for irssi's
	# TAB-Completion are wrong here.

	my $server  = Irssi::active_server();
	my $channel = $window->{active};
	my @switches_combo   = map { $_ = "--$_" } keys %{ $switches{combo} };
	my @switches_nocombo = map { $_ = "--$_" } keys %{ $switches{nocombo} };
	my @nicks;

	# Only complete when the commandline starts with '${k}dau'.
	# If not, let irssi do the work

	return unless ($linestart =~ /^\Q${k}\Edau/i);

	# Remove everything syntactically correct thing of $linestart.
	# If there is anything else but whitespace at the end of
	# commandline parsing, we have an syntax error.
	# If we have a syntax error, complete only nicks.

	$linestart =~ s/^\Q${k}\Edau ?//i;

	# Generate list of nicks in current channel for later use

	if (defined($channel->{type}) && $channel->{type} eq 'CHANNEL') {
		foreach my $nick ($channel->nicks()) {
			if ($nick->{nick} =~ /^\Q$word\E/i &&
			    $window->{active_server}->{nick} ne $nick->{nick})
			{
				push(@nicks, quotemeta($nick->{nick}));
			}
		}
	}

	# Variables

	my $combo = 0;                # Boolean: True if last switch was one of keys %{ $switches{combo} }
	my $syntax_error = 0;         # Boolean: True if syntax error found
	my $counter = 0;              # Integer: Counts First-Level-Options
	my $first_level_option = '';  # String:  Last First-Level-Option
	my $second_level_option = ''; # String:  Last Second-Level-Option
	my $third_level_option = 0;   # Boolean: True if found a Third-Level-Option

	# Parsing commandline now. Set variables accordingly.

	OUTER: while ($linestart =~ /^--(\w+) ?/g) {

		$second_level_option = '';
		$third_level_option  = 0;

		# Found a First-Level-Option (combo)

		if (ref($switches{combo}{$1}{'sub'})) {
			$first_level_option = $1;
			$combo = 1;
		}

		# Found a First-Level-Option (nocombo)

		elsif (ref($switches{nocombo}{$1}{'sub'}) && $counter == 0) {
			$first_level_option = $1;
			$combo = 0;
		}

		# Not a First-Level-Option => Syntax error

		else {
			$syntax_error = 1;
			last OUTER;
		}

		# Syntactically correct => remove it

		$linestart =~ s/^--\w+ ?//;

		# Checkout if there are Second- or Third-Level-Options

		INNER: while ($linestart =~ /^-(\w+)(?: ('[^']+'|\S+))? ?/g) {

			my $second_level = $1;
			my $third_level  = $2 || '';

			$third_level =~ s/^'([^']+)'$/$1/;

			# Do the same for combo and nocombo-options. They have to be
			# handled separately anyway.

			# combo...

			if ($combo) {

				# Found a Second-Level-Option

				if ($switches{combo}{$first_level_option}{$second_level}) {
					$second_level_option = $second_level;
				}

				# Not a Second-Level-Option => Syntax error

				else {
					$syntax_error = 1;
					last OUTER;
				}

				# Syntactically correct => remove it

				$linestart =~ s/^-\w+//;

				# Found something in the regexp of the INNER-while-loop-condition,
				# which is perhaps a Third-Level-Option

				if ($third_level) {

					# Found a Third-Level-Option

					if ($switches{combo}{$first_level_option}{$second_level_option}{$third_level} ||
                                            $switches{combo}{$first_level_option}{$second_level_option}{'*'})
					{
						$third_level_option = 1;

						# Syntactically correct => remove it

						$linestart =~ s/^(?: ('[^']+'|\S+))? ?//;
					}

					# Not a Third-Level-Option => Syntax error

					else {
						$syntax_error = 1;
						last OUTER;
					}

				# Nothing found which comes into question for a Third-Level-Option.
				# The commandline has to be empty now (remember: everything
				# syntactically correct has been removed) or we have a syntax error.

				} else {

					# Empty! Later we will complete to Third-Level-Options

					if ($linestart =~ /^\s*$/) {
						$third_level_option = 0;
					}

					# Not empty => Syntax error

					else {
						$syntax_error = 1;
						last OUTER;
					}
				}

			# nocombo...

			} else {

				# Found a Second-Level-Option

				if ($switches{nocombo}{$first_level_option}{$second_level}) {
					$second_level_option = $second_level;
				}

				# Not a Second-Level-Option => Syntax error

				else {
					$syntax_error = 1;
					last OUTER;
				}

				# Syntactically correct => remove it

				$linestart =~ s/^-\w+//;

				# Found something in the regexp of the INNER-while-loop-condition,
				# which is perhaps a Third-Level-Option

				if ($third_level) {

					# Found a Third-Level-Option

					if ($switches{nocombo}{$first_level_option}{$second_level_option}{$third_level} ||
                                            $switches{nocombo}{$first_level_option}{$second_level_option}{'*'})
					{
						$third_level_option = 1;

						# Syntactically correct => remove it

						$linestart =~ s/^(?: ('[^']+'|\S+))? ?//;
					}

					# Not a Third-Level-Option => Syntax error

					else {
						$syntax_error = 1;
						last OUTER;
					}

				# Nothing found which comes into question for a Third-Level-Option.
				# The commandline has to be empty now (remember: everything
				# syntactically correct has been removed) or we have a syntax error.

				} else {

					# Empty! Later we will complete to Third-Level-Options

					if ($linestart =~ /^\s*$/) {
						$third_level_option = 0;
					}

					# Not empty => Syntax error

					else {
						$syntax_error = 1;
						last OUTER;
					}
				}
			}
		}
	} continue {
		$counter++;
	}

	# End of commandline-parsing.
	# Everything syntactically correct removed.
	# If commandline is not empty now, we have a syntax error.

	if ($linestart !~ /^\s*$/) {
		$syntax_error = 1;
	}

	# Do the TAB-Completion

	if ($syntax_error) {

		foreach my $x (sort @nicks) {
			if($x =~ /^$word/i) {
				push(@$list, $x);
			}
		}
	}

	elsif ($counter == 0) {

		foreach my $x (sort (@switches_combo, @switches_nocombo, @nicks)) {
			if($x =~ /^$word/i) {
				push(@$list, $x);
			}
		}
	}

	elsif (($combo && $first_level_option && $second_level_option && $third_level_option) ||
	       ($combo && $first_level_option && !$second_level_option && !$third_level_option))
	{

		my @switches_second_level = grep !/^-sub$/, map { $_ = "-$_" }
					    keys %{ $switches{combo}{$first_level_option} };

		foreach my $x (sort (@switches_second_level, @switches_combo, @nicks)) {
			if($x =~ /^$word/i) {
				push(@$list, $x);
			}
		}
	}

	elsif ((!$combo && $counter == 1 && $first_level_option && $second_level_option && $third_level_option) ||
	       (!$combo && $counter == 1 && $first_level_option && !$second_level_option && !$third_level_option))
	{
		my @switches_second_level = grep !/^-sub$/, map { $_ = "-$_" }
					    keys %{ $switches{nocombo}{$first_level_option} };

		foreach my $x (sort (@switches_second_level)) {
			if($x =~ /^$word/i) {
				push(@$list, $x);
			}
		}
	}

	elsif ($combo && $first_level_option && $second_level_option && !$third_level_option) {
		my @switches_third_level = grep !/^\*$/,
					   keys %{ $switches{combo}{$first_level_option}{$second_level_option} };

		foreach my $x (sort (@switches_third_level)) {
			if($x =~ /^$word/i) {
				push(@$list, $x);
			}
		}
	}

	elsif (!$combo && $counter == 1 && $first_level_option && $second_level_option && !$third_level_option) {
		my @switches_third_level = grep !/^\*$/,
					   keys %{ $switches{nocombo}{$first_level_option}{$second_level_option} };

		foreach my $x (sort (@switches_third_level)) {
			if($x =~ /^$word/i) {
				push(@$list, $x);
			}
		}
	}

	Irssi::signal_stop();
}

sub signal_event_privmsg {
	my ($server, $data, $nick, $hostmask) = @_;
	my ($channel_name, $text) = split / :/, $data, 2;
	my $channel_rec = $server->channel_find($channel_name);
	$channel_name   = lc($channel_name);
	my $server_name = lc($server->{tag});
	my $own_nick = $server->{nick};
	my %lookup;

	while ($option{dau_remote_channellist} =~ /\s*([^\/]+)\/([^,]+)\s*,?/g) {
		my $channel = $1;
		$channel    = lc($channel);
		my $ircnet  = $2;
		$ircnet     = lc($ircnet);
		$lookup{$ircnet}{$channel} = 1;
	}
	if (lc($option{dau_remote_channelpolicy}) eq 'allow') {
		return if ($lookup{$server_name}{$channel_name});
	} elsif (lc($option{dau_remote_channelpolicy}) eq 'deny') {
		return unless ($lookup{$server_name}{$channel_name});
	} else {
		return;
	}

	# Remove formatting so dau.pl can reply to a colored, underlined, ...
	# 'hallo wie geht'

	$text =~ s/\003\d?\d?(?:,\d?\d?)?|\002|\006|\007|\016|\01f|\037//g;

	if ($text =~ /^ ?hallo wie geht(?:\s*@\s*$own_nick)?[\s?ß!1]*$/i) {
		my $reply = parse_setting_list('dau_remote_question_reply');
		$reply =~ s/(?<![\\])\$nick/$nick/g;
		$reply = parse_text($reply, $channel_rec);

		output_text($server, $channel_name, $reply);
	}
}

sub signal_nick_mode_changed {
	my ($channel, $nick, $setby, $mode, $type) = @_;
	my ($reply, %lookup);
	my $channel_name = lc($channel->{name});
	my $server_name  = lc($channel->{server}->{tag});

	return unless ($channel->{server}->{nick} eq $nick->{nick});
	return if ($nick->{nick} eq $setby);
	return if ($setby eq 'irc.psychoid.net');

	while ($option{dau_remote_channellist} =~ /\s*([^\/]+)\/([^,]+)\s*,?/g) {
		my $channel = $1;
		$channel    = lc($channel);
		my $ircnet  = $2;
		$ircnet     = lc($ircnet);
		$lookup{$ircnet}{$channel} = 1;
	}
	if (lc($option{dau_remote_channelpolicy}) eq 'allow') {
		return if ($lookup{$server_name}{$channel_name});
	} elsif (lc($option{dau_remote_channelpolicy}) eq 'deny') {
		return unless ($lookup{$server_name}{$channel_name});
	} else {
		return;
	}

	if ($option{dau_remote_permissions} =~ /^[01]1[01][01][01][01]$/) {
		if ($mode eq '+' && $type eq '+') {
			$reply = parse_setting_list('dau_remote_voice_reply');
			$reply =~ s/(?<![\\])\$nick/$setby/g;
			$reply = parse_text($reply, $channel);
		}
	}
	if ($option{dau_remote_permissions} =~ /^[01][01]1[01][01][01]$/) {
		if ($mode eq '@' && $type eq '+') {
			$reply = parse_setting_list('dau_remote_op_reply');
			$reply =~ s/(?<![\\])\$nick/$setby/g;
			$reply = parse_text($reply, $channel);
		}
	}
	if ($option{dau_remote_permissions} =~ /^[01][01][01]1[01][01]$/) {
		if ($mode eq '+' && $type eq '-') {
			$reply = parse_setting_list('dau_remote_devoice_reply');
			$reply =~ s/(?<![\\])\$nick/$setby/g;
			$reply = parse_text($reply, $channel);
		}
	}
	if ($option{dau_remote_permissions} =~ /^[01][01][01][01]1[01]$/) {
		if ($mode eq '@' && $type eq '-') {
			$reply = parse_setting_list('dau_remote_deop_reply');
			$reply =~ s/(?<![\\])\$nick/$setby/g;
			$reply = parse_text($reply, $channel);
		}
	}

	output_text($channel, $channel->{name}, $reply);
}

sub signal_send_text {
	my ($data, $server, $witem) = @_;
	my $output;

	return unless (defined($server) && $server && $server->{connected});
	return unless (defined($witem) && $witem &&
	              ($witem->{type} eq 'CHANNEL' || $witem->{type} eq 'QUERY'));

	if ($misc{daumode_ochannels}{$server->{tag}}{$witem->{name}} == 1) {
		if ($misc{daumode_ochannels_modes}{$server->{tag}}{$witem->{name}} eq '') {
			$output = parse_text($misc{daumode_ochannels_modes}{$server->{tag}}{$witem->{name}} . $data, $witem);
		} else {
			$output = parse_text($misc{daumode_ochannels_modes}{$server->{tag}}{$witem->{name}} . ' ' . $data, $witem);
		}

		output_text($witem, $witem->{name}, $output);

		Irssi::signal_stop();
	}
}

sub signal_setup_changed {
	set_settings();

	# setting changed/added => change/add it here

	# setting cmdchars

	$k = Irssi::parse_special('$k');

	# setting dau_cowsay_cowpath

	cowsay_cowlist($option{dau_cowsay_cowpath});

	# setting dau_figlet_fontpath

	figlet_fontlist($option{dau_figlet_fontpath});

	# setting dau_remote_babble_interval

	if ($option{dau_remote_babble_interval} != $misc{remote_babble_timer_last_interval}) {
		timer_babble_reset();
	}

	# setting dau_statusbar_daumode_hide_when_off

	Irssi::statusbar_items_redraw('daumode');

	# timer for the babble-feature

	timer_babble_reset();

	# signal handling

	signal_handling();
}

sub signals_idaumode {
	my ($server, $data, $nick, $hostmask, $target) = @_;
	my $channel_rec = $server->channel_find($target);
	my $i_channel = $misc{daumode_ichannels}{$server->{tag}}{$target};
	my $i_modes   = $misc{daumode_ichannels_modes}{$server->{tag}}{$target};
	my $modified_msg;

	return unless (defined($server) && $server && $server->{connected});

	# Not one of the channels where daumode for incoming messages is turned on.
	# In those channels print out the message as it is and leave the subroutine

	if (!$i_channel) {
		return;
	}

	# Evil Hack...
	# I had to dauify every incoming messages. Using &signal_continue was
	# not possible because --words f.e. generates multilineoutput. So i had
	# to create multiple messages using &signal_emit. Those just created
	# messages shouldn't be dauified again when entering this subroutine. I
	# couldn't prevent irssi from entering this subroutine again after
	# dauifying the text so the messages had to be 'marked'. Marked messages
	# will not be dauified again. I think \x02 at the beginning of the
	# message is ok for that... I know this whole crap here can be done
	# MUCH MORE elegant. I do not have more time for that. Send me a patch
	# if you want a change here.

	if ($data =~ s/^\x02//) {
		Irssi::signal_continue($server, $data, $nick, $hostmask, $target);
	} else {
		if ($i_modes ne '') {
			$modified_msg = parse_text($i_modes . ' ' . $data, $channel_rec);
		} else {
			$modified_msg = parse_text($data, $channel_rec);
		}

		if ($modified_msg =~ /\n/) {
			for my $line (split /\n/, $modified_msg) {
				Irssi::signal_emit(Irssi::signal_get_emitted(), $server, "\x02$line", $nick, $hostmask, $target);
				Irssi::signal_stop();
			}
		} else {
			Irssi::signal_emit(Irssi::signal_get_emitted(), $server, "\x02$modified_msg", $nick, $hostmask, $target);
			Irssi::signal_stop();
		}
	}
}

################################################################################
# Subroutines (statusbar)
################################################################################

sub statusbar_daumode {
	my ($item, $get_size_only) = @_;
	my ($i_status, $o_status, $i_modes, $o_modes);
	my $server = Irssi::active_server();
	my $witem  = Irssi::active_win()->{active};
	my $theme  = Irssi::current_theme();
	my $format = $theme->format_expand('{sb_daumode}');

	if (defined($witem)  && $witem  &&
	    defined($server) && $server &&
	   ($witem->{type} eq 'CHANNEL' || $witem->{type} eq 'QUERY'))
	{
		if (defined($misc{daumode_ichannels}{$server->{tag}}{$witem->{name}}) &&
		    $misc{daumode_ichannels}{$server->{tag}}{$witem->{name}} == 1)
		{
			$i_status = 'ON';
		} else {
			$i_status = 'OFF';
		}

		if (defined($misc{daumode_ochannels}{$server->{tag}}{$witem->{name}}) &&
		    $misc{daumode_ochannels}{$server->{tag}}{$witem->{name}} == 1)
		{
			$o_status = 'ON';
		} else {
			$o_status = 'OFF';
		}

		# Hide statusbaritem if setting dau_statusbar_daumode_hide_when_off
		# is turned on and daumode is turned off

		if ($i_status eq 'OFF' && $o_status eq 'OFF' && $option{dau_statusbar_daumode_hide_when_off}) {
			$item->{min_size} = $item->{max_size} = 0;
			return;
		}

		if ($i_status eq 'ON') {
			$i_modes = $misc{daumode_ichannels_modes}{$server->{tag}}{$witem->{name}} || $option{dau_standard_options};
		} else {
			$i_modes = '';
		}
		if ($o_status eq 'ON') {
			$o_modes = $misc{daumode_ochannels_modes}{$server->{tag}}{$witem->{name}} || $option{dau_standard_options};
		} else {
			$o_modes = '';
		}

		if ($format) {
			$format = $theme->format_expand("{sb_daumode $o_status $o_modes $i_status $i_modes}");
		} else {
			if ($i_status eq 'OFF' && $o_status eq 'OFF') {
				$format = $theme->format_expand("{sb daumode: <- $i_status | -> $o_status}");
			}
			elsif ($i_status eq 'OFF' && $o_status eq 'ON') {
				$format = $theme->format_expand("{sb daumode: <- $i_status | -> $o_status ($o_modes)}");
			}
			elsif ($i_status eq 'ON' && $o_status eq 'OFF') {
				$format = $theme->format_expand("{sb daumode: <- $i_status ($i_modes) | -> $o_status}");
			}
			elsif ($i_status eq 'ON' && $o_status eq 'ON') {
				$format = $theme->format_expand("{sb daumode: <- $i_status ($i_modes) | -> $o_status ($o_modes)}");
			}
		}
	} else {
		$item->{min_size} = $item->{max_size} = 0;
		return;
	}

	$item->default_handler($get_size_only, $format, '', 1);
}

################################################################################
# Subroutines (timer)
################################################################################

sub timer_babble {
	# Push all channels where it's ok to babble text in @channels

	my %lookup;
	while ($option{dau_remote_babble_channellist} =~ /\s*([^\/]+)\/([^,]+)\s*,?/g) {
		my $channel = $1;
		$channel    = lc($channel);
		my $ircnet  = $2;
		$ircnet     = lc($ircnet);
		$lookup{$ircnet}{$channel} = 1;
	}

	my @channels;
	foreach my $server (Irssi::servers()) {
		my $server_name = lc($server->{tag});

		foreach my $channel ($server->channels()) {
			my $channel_name = lc($channel->{name});

			if (lc($option{dau_remote_babble_channelpolicy}) eq 'allow' &&
			    !$lookup{$server_name}{$channel_name})
			{
				push(@channels, $channel);
			}
			elsif (lc($option{dau_remote_babble_channelpolicy}) eq 'deny' &&
			       $lookup{$server_name}{$channel_name})
			{
				push(@channels, $channel);
			}
		}
	}

	# No channels found => return

	return if (@channels == 0);

	# Choose one of the @channels

	my $channel = $channels[rand(@channels)];

	# Return a random string from the list in the setting dau_remote_babble_messages

	my $text_setting = parse_setting_list('dau_remote_babble_messages');

	# Return a random line from the dau_files_remote_babble_messages file

	my $text_file;
	my $file = "$option{dau_files_root_directory}/$option{dau_files_remote_babble_messages}";
	$/ = "\n";
	@ARGV = ($file);
	srand;
	rand($.) < 1 && ($text_file = $_) while <>;

	# If we got something from the file take that - otherwise the stuff from the
	# setting

	my $text = $text_file || $text_setting;

	# Substitution: \n to a real newline

	$text =~ s/\\n/\n/g;

	# Substitution: $rnick to a random nick of $channel

	my $rnick;
	my @nicks = ();
	if (defined($channel) && $channel && $channel->{type} eq 'CHANNEL') {
		foreach my $nick ($channel->nicks()) {
			if ($channel->{server}->{nick} ne $nick->{nick}) {
				push(@nicks, $nick->{nick});
			}
		}
	}

	if (@nicks == 0) {
		$rnick = 'foo';
	} else {
		$rnick = $nicks[rand(@nicks)];
	}

	$text =~ s/(?<![\\])\$rnick/$rnick/g;

	# Substitution: irssi's special variables

	$text = $channel->parse_special($text);

	# The standard options for babble

	my $options = $option{dau_remote_babble_standard_options};

	# We have two timers in the game:
	#
	# timer_babble() and timer_babble_reset() managing the big breaks between
	# the babbling
	#
	# timer_babble_writing() and timer_babble_writing_reset() managing the
	# breaks between the lines of one babbling (simulating a user typing).

	# These are some global variables for the writing timer

	$misc{timer_babble_writing}{channelname} = $channel->{name};
	$misc{timer_babble_writing}{channel}     = $channel;
	$misc{timer_babble_writing}{counter}     = 0;
	$misc{timer_babble_writing}{options}     = $options;
	$misc{timer_babble_writing}{text}        = "$text\n";

	# First stop the big breaks timer then start the writing timer. It will
	# write down the dauified text with breaks between the lines simulating a user
	# typing. When it's done it will restart the babble timer for the big breaks.

	Irssi::timeout_remove($misc{remote_babble_timer}) if (defined($misc{remote_babble_timer}));
	timer_babble_writing_reset();
}

sub timer_babble_reset {
	Irssi::timeout_remove($misc{remote_babble_timer}) if (defined($misc{remote_babble_timer}));

	# Do not set the timer, if the permission-bit is not set

	return unless ($option{dau_remote_permissions} =~ /^[01][01][01][01][01]1$/);

	# Calculate interval

	my $interval = $option{dau_remote_babble_interval} * 1000;

	my $addend;
	if ($option{dau_remote_babble_interval_accuracy} == 100) {
		$addend = 0;
	} elsif ($option{dau_remote_babble_interval_accuracy} > 0 &&
	         $option{dau_remote_babble_interval_accuracy} < 100)
	{
		$addend = rand($interval - ($interval * ($option{dau_remote_babble_interval_accuracy} / 100)));
	} else {
		print_err('Invalid value of dau_remote_babble_interval_accuracy');
		return;
	}

	if (int(rand(2))) {
		$interval = $interval + $addend;
	} else {
		$interval = $interval - $addend;
	}

	$interval = int($interval);

	if ($interval < 10 || $interval > 1000000000) {
		print_err('Invalid value of dau_remote_babble_interval');
		return;
	}

	# Store settings value (when setup changes it must know whether to
	# reset timer or not

	$misc{remote_babble_timer_last_interval} = $option{dau_remote_babble_interval};

	# Set timer

	$misc{remote_babble_timer} = Irssi::timeout_add($interval, \&timer_babble, '');
}

sub timer_babble_writing {
	# Dauify the current line then print it

	my $output = parse_text("$misc{timer_babble_writing}{options} $misc{timer_babble_writing}{line}", $misc{timer_babble_writing}{channel});
	output_text($misc{timer_babble_writing}{channel}, $misc{timer_babble_writing}{channelname}, $output);

	# And go to the "managing" subroutine...

	timer_babble_writing_reset();
}

sub timer_babble_writing_reset {
	# Remove used writing timer, if existent (at the first run we don't have any timer)

	Irssi::timeout_remove($misc{remote_babble_timer_writing}) if (defined($misc{remote_babble_timer_writing}));

	# At each run of this managing subroutine remove one line of text

	$misc{timer_babble_writing}{text} =~ s/^(.*?)\n//;
	$misc{timer_babble_writing}{line} = $1;

	# If there is still some text left, add a new timer for the next line

	if (length($misc{timer_babble_writing}{text}) != 0) {
		# First run: Call timer_babble_writing() directly to avoid a break
		# (If dau_remote_babble_interval_accuracy is set to 100 percent
		# this would add an unwanted additional break)

		if ($misc{timer_babble_writing}{counter}++ == 0) {
			timer_babble_writing();
		}

		# Not the first run? Normal behaviour and the timer for the breaks

		else {
			# Calculate the writing breaks
			# The longer the next line is the longer the break will be

			my $interval = 1000 + rand(2000) +
			               50 * length($misc{timer_babble_writing}{line}) +
			               rand(25 * length($misc{timer_babble_writing}{line}));
			$interval = int($interval);

			# Set timer

			$misc{remote_babble_timer_writing} = Irssi::timeout_add($interval, \&timer_babble_writing, '');
		}
	}

	# Nothing left?
	# Go to the managing subroutine for the "big breaks timer" (restart)

	else {
		timer_babble_reset();
	}
}

################################################################################
# Helper subroutines
################################################################################

sub def_dau_cowsay_cowpath {
	my $cowsay = $ENV{COWPATH} || '/usr/share/cowsay/cows';
	chomp($cowsay);
	return $cowsay;
}

sub def_dau_cowsay_path {
	my $cowsay = `which cowsay`;
	chomp($cowsay);
	return $cowsay;
}

sub def_dau_figlet_fontpath {
	my $figlet = `figlet -I2`;
	chomp($figlet);
	return $figlet;
}

sub def_dau_figlet_path {
	my $figlet = `which figlet`;
	chomp($figlet);
	return $figlet;
}

sub cowsay_cowlist {
	my $cowsay_cowpath = shift;

	# clear cowlist

	%{ $switches{combo}{cowsay}{cow} } = ();

	# generate new list

	while (<$cowsay_cowpath/*.cow>) {
		my $cow = (fileparse($_, qr/\.[^.]*/))[0];
		$switches{combo}{cowsay}{cow}{$cow} = 1;
	}
}

sub figlet_fontlist {
	my $figlet_fontpath = shift;

	# clear fontlist

	%{ $switches{combo}{figlet}{font} } = ();

	# generate new list

	while (<$figlet_fontpath/*.flf>) {
		my $font = (fileparse($_, qr/\..*/))[0];
		$switches{combo}{figlet}{font}{$font} = 1;
	}
}

sub fix {
	my $string = shift;
	$string =~ s/^\t+//gm;
	return $string;
}

sub output_text {
	my ($thing, $target, $text) = @_;

	foreach my $line (split /\n/, $text) {

		# --command -out <command>?

		if ($misc{switch_command_out}) {
			if (defined($thing) && $thing) {
				$thing->command("$misc{command_out} $line");
			} else {
				my $server = Irssi::active_server();

				if (defined($server) && $server && $server->{connected}) {
					$server->command("$misc{command_out} $line");
				} else {
					print CLIENTCRAP $line;
				}
			}
		}

		# Not a channel/query-window, --help, --changelog, ...

		elsif ($misc{'print'}) {
			print CLIENTCRAP $line;
		}

		# Normal behaviour

		elsif ($misc{command_out} eq 'ACTION' || $misc{command_out} eq 'MSG') {
			$thing->command("$misc{command_out} $target $line");
		}

		# if weird things happened...

		else {
			print CLIENTCRAP $line;
		}
	}
}

sub parse_setting_list {
	my $arg = shift;
	my @strings;

	while ($option{$arg} =~ /\s*([^,]+)\s*,?/g) {
		push @strings, $1;
	}

	if (@strings == 0) {
		return '';
	} else {
		return $strings[rand(@strings)];
	}
}

sub parse_text {
	my ($data, $channel_rec) = @_;
	my $output;

	%{ $misc{queue} }         = ();
	$misc{'print'}            = 0;
	$misc{command_out}        = 'MSG';
	$misc{counter}            = 0;
	$misc{daumode}            = 0;
	$misc{switch_command_out} = 0;

	OUTER: while ($data =~ /^--(\w+) ?/g) {

		my $first_level_option  = $1;

		# If its the first time we are in the OUTER loop, check
		# if the First-Level-Option is one of the few options,
		# which must not be combined.

		if (ref($switches{nocombo}{$first_level_option}{'sub'}) && $misc{counter} == 0) {

			$data =~ s/^--\w+ ?//;

			# found a First-Level-Option

			$misc{queue}{$misc{counter}}{$first_level_option} = { };

			# Check for Second-Level-Options and Third-Level-Options.
			# Get all of them and put theme in the
			# $misc{queue} hash

			while ($data =~ /^-(\w+) ('[^']+'|\S+) ?/g) {

				my $second_level_option = $1;
				my $third_level_option  = $2;

				$third_level_option =~ s/^'([^']+)'$/$1/;

				# If $switches{nocombo}{$first_level_option}{$second_level_option}{'*'}:
				# The user can give any third_level_option on the commandline

				my $any_option =
				$switches{nocombo}{$first_level_option}{$second_level_option}{'*'} ? 1 : 0;

				if ($switches{nocombo}{$first_level_option}{$second_level_option}{$third_level_option} ||
				    $any_option)
				{
					$misc{queue}{$misc{counter}}{$first_level_option}{$second_level_option} = $third_level_option;
				}

				$data =~ s/^-(\w+) ('[^']+'|\S+) ?//;
			}

			# initialize some values

			foreach my $second_level_option (keys(%{ $switches{nocombo}{$first_level_option} })) {
				if (!defined($misc{queue}{'0'}{$first_level_option}{$second_level_option})) {
					$misc{queue}{'0'}{$first_level_option}{$second_level_option} = '';
				}
			}

			# All done. Run the subroutine

			$output = &{ $switches{nocombo}{$first_level_option}{'sub'} }($data, $channel_rec);

			return $output;
		}

		# Check for all those options that can be combined.

		elsif (ref($switches{combo}{$first_level_option}{'sub'})) {

			$data =~ s/^--\w+ ?//;

			# found a First-Level-Option

			$misc{queue}{$misc{counter}}{$first_level_option} = { };

			# Check for Second-Level-Options and
			# Third-Level-Options. Get all of them and put them
			# in the $misc{queue} hash

			while ($data =~ /^-(\w+) ('[^']+'|\S+) ?/g) {

				my $second_level_option = $1;
				my $third_level_option  = $2;

				$third_level_option =~ s/^'([^']+)'$/$1/;

				# If $switches{combo}{$first_level_option}{$second_level_option}{'*'}:
				# The user can give any third_level_option on the commandline

				my $any_option =
				$switches{combo}{$first_level_option}{$second_level_option}{'*'} ? 1 : 0;

				# known option => Put it in the hash

				if ($switches{combo}{$first_level_option}{$second_level_option}{$third_level_option}
			            || $any_option)
				{
					$misc{queue}{$misc{counter}}{$first_level_option}{$second_level_option} = $third_level_option;
					$data =~ s/^-(\w+) ('[^']+'|\S+) ?//;
				} else {
					last OUTER;
				}
			}

			# increase counter

			$misc{counter}++;
		}

		else {
			last OUTER;
		}
	}

	# initialize some values

	for (my $i = 0; $i < $misc{counter}; $i++) {
		foreach my $first_level (keys(%{ $misc{queue}{$i} })) {
			if (ref($switches{combo}{$first_level})) {
				foreach my $second_level (keys(%{ $switches{combo}{$first_level} })) {
					if (!defined($misc{queue}{$i}{$first_level}{$second_level})) {
						$misc{queue}{$i}{$first_level}{$second_level} = '';
					}
				}
			}
		}
	}

	# text to subroutines

	$output = $data;

	# If theres no text left over, take one item of dau_random_messages

	if ($output =~ /^\s*$/) {
		$output = parse_setting_list('dau_standard_messages');
	}

	# No options? Get options from setting dau_standard_options and run
	# parse_text() again

	if (keys %{ $misc{queue} } == 0) {

		if (!$misc{subcounter}) {
			$misc{subcounter}++;
			$output = parse_text("$option{dau_standard_options} $output", $channel_rec);
		} else {
			print_err('Invalid value for setting dau_standard_options. ' .
			          'Will use %9--moron%9 instead!');
			$output =~ s/^\Q$option{dau_standard_options}\E //;
			$output = parse_text("--moron $output", $channel_rec);
		}

	} else {

		$misc{counter} = 0;

		for (keys(%{ $misc{queue} })) {
			my ($first_level_option) = keys %{ $misc{queue}{$misc{counter}} };
			$output = &{ $switches{combo}{$first_level_option}{'sub'} }($output, $channel_rec);
			$misc{counter}++;
		}
	}

	# reset subcounter

	$misc{subcounter} = 0;

	# return text

	return $output;
}

sub print_err {
	my $text = shift;

	print CLIENTCRAP "%Rdau.pl error%n: $text";
}

sub print_out {
	my $text = shift;

	print CLIENTCRAP "%9dau.pl%9: $text";
}

sub set_settings {
	# setting changed/added => change/add it here

	# boolean
	$option{dau_cowsay_print_cow}                = Irssi::settings_get_bool('dau_cowsay_print_cow');
	$option{dau_figlet_print_font}               = Irssi::settings_get_bool('dau_figlet_print_font');
	$option{dau_statusbar_daumode_hide_when_off} = Irssi::settings_get_bool('dau_statusbar_daumode_hide_when_off');
	$option{dau_tab_completion}                  = Irssi::settings_get_bool('dau_tab_completion');

	# Integer
	$option{dau_remote_babble_interval}          = Irssi::settings_get_int('dau_remote_babble_interval');
	$option{dau_remote_babble_interval_accuracy} = Irssi::settings_get_int('dau_remote_babble_interval_accuracy');

	# String
	$option{dau_cowsay_cowlist}                  = Irssi::settings_get_str('dau_cowsay_cowlist');
	$option{dau_cowsay_cowpath}                  = Irssi::settings_get_str('dau_cowsay_cowpath');
	$option{dau_cowsay_cowpolicy}                = Irssi::settings_get_str('dau_cowsay_cowpolicy');
	$option{dau_cowsay_path}                     = Irssi::settings_get_str('dau_cowsay_path');
	$option{dau_delimiter_string}                = Irssi::settings_get_str('dau_delimiter_string');
	$option{dau_figlet_fontlist}                 = Irssi::settings_get_str('dau_figlet_fontlist');
	$option{dau_figlet_fontpath}                 = Irssi::settings_get_str('dau_figlet_fontpath');
	$option{dau_figlet_fontpolicy}               = Irssi::settings_get_str('dau_figlet_fontpolicy');
	$option{dau_figlet_path}                     = Irssi::settings_get_str('dau_figlet_path');
	$option{dau_files_moron_own_substitutions}   = Irssi::settings_get_str('dau_files_moron_own_substitutions');
	$option{dau_files_remote_babble_messages}    = Irssi::settings_get_str('dau_files_remote_babble_messages');
	$option{dau_files_root_directory}            = Irssi::settings_get_str('dau_files_root_directory');
	$option{dau_moron_eol_style}                 = Irssi::settings_get_str('dau_moron_eol_style');
	$option{dau_moron_substitutions_permissions} = Irssi::settings_get_str('dau_moron_substitutions_permissions');
	$option{dau_random_options}                  = Irssi::settings_get_str('dau_random_options');
	$option{dau_remote_babble_channellist}       = Irssi::settings_get_str('dau_remote_babble_channellist');
	$option{dau_remote_babble_channelpolicy}     = Irssi::settings_get_str('dau_remote_babble_channelpolicy');
	$option{dau_remote_babble_messages}          = Irssi::settings_get_str('dau_remote_babble_messages');
	$option{dau_remote_babble_standard_options}  = Irssi::settings_get_str('dau_remote_babble_standard_options');
	$option{dau_remote_channellist}              = Irssi::settings_get_str('dau_remote_channellist');
	$option{dau_remote_channelpolicy}            = Irssi::settings_get_str('dau_remote_channelpolicy');
	$option{dau_remote_deop_reply}               = Irssi::settings_get_str('dau_remote_deop_reply');
	$option{dau_remote_devoice_reply}            = Irssi::settings_get_str('dau_remote_devoice_reply');
	$option{dau_remote_op_reply}                 = Irssi::settings_get_str('dau_remote_op_reply');
	$option{dau_remote_permissions}              = Irssi::settings_get_str('dau_remote_permissions');
	$option{dau_remote_question_reply}           = Irssi::settings_get_str('dau_remote_question_reply');
	$option{dau_remote_voice_reply}              = Irssi::settings_get_str('dau_remote_voice_reply');
	$option{dau_standard_messages}               = Irssi::settings_get_str('dau_standard_messages');
	$option{dau_standard_options}                = Irssi::settings_get_str('dau_standard_options');
	$option{dau_words_range}                     = Irssi::settings_get_str('dau_words_range');
}

sub signal_handling {
	# complete word

	if ($option{dau_tab_completion}) {
		if ($misc{signals}{'complete word'} != 1) {
			Irssi::signal_add_last('complete word', 'signal_complete_word');
		}
		$misc{signals}{'complete word'} = 1;
	} else {
		if ($misc{signals}{'complete word'} != 0) {
			Irssi::signal_remove('complete word', 'signal_complete_word');
		}
		$misc{signals}{'complete word'} = 0;
	}

	# event privmsg

	if ($option{dau_remote_permissions} =~ /^1[01][01][01][01][01]$/) {
		if ($misc{signals}{'event privmsg'} != 1) {
			Irssi::signal_add_last('event privmsg', 'signal_event_privmsg');
		}
		$misc{signals}{'event privmsg'} = 1;
	} else {
		if ($misc{signals}{'event privmsg'} != 0) {
			Irssi::signal_remove('event privmsg', 'signal_event_privmsg');
		}
		$misc{signals}{'event privmsg'} = 0;
	}

	# nick mode changed

	if ($option{dau_remote_permissions} =~ /^[01]1[01][01][01][01]$/ ||
	    $option{dau_remote_permissions} =~ /^[01][01]1[01][01][01]$/ ||
	    $option{dau_remote_permissions} =~ /^[01][01][01]1[01][01]$/ ||
	    $option{dau_remote_permissions} =~ /^[01][01][01][01]1[01]$/)
	{
		if ($misc{signals}{'nick mode changed'} != 1) {
			Irssi::signal_add_last('nick mode changed', 'signal_nick_mode_changed');
		}
		$misc{signals}{'nick mode changed'} = 1;
	} else {
		if ($misc{signals}{'nick mode changed'} != 0) {
			Irssi::signal_remove('nick mode changed', 'signal_nick_mode_changed');
		}
		$misc{signals}{'nick mode changed'} = 0;
	}

	# send text

	my $odaumode = 0;

	foreach my $server (keys %{ $misc{daumode_ochannels} }) {
		foreach my $channel (keys %{ $misc{daumode_ochannels}{$server} }) {
			if ($misc{daumode_ochannels}{$server}{$channel} == 1) {
				$odaumode = 1;
			}
		}
	}

	if ($odaumode) {
		if ($misc{signals}{'send text'} != 1) {
			Irssi::signal_add_first('send text', 'signal_send_text');
		}
		$misc{signals}{'send text'} = 1;
	} else {
		if ($misc{signals}{'send text'} != 0) {
			Irssi::signal_remove('send text', 'signal_send_text');
		}
		$misc{signals}{'send text'} = 0;
	}

	# signals idaumode (incoming messages - daumode)

	my $idaumode = 0;

	foreach my $server (keys %{ $misc{daumode_ichannels} }) {
		foreach my $channel (keys %{ $misc{daumode_ichannels}{$server} }) {
			if ($misc{daumode_ichannels}{$server}{$channel} == 1) {
				$idaumode = 1;
			}
		}
	}

	if ($idaumode) {
		if ($misc{signals}{'signals idaumode'} != 1) {
			Irssi::signal_add_last('message public', 'signals_idaumode');
			Irssi::signal_add_last('message irc action', 'signals_idaumode');
		}
		$misc{signals}{'signals idaumode'} = 1;
	} else {
		if ($misc{signals}{'signals idaumode'} != 0) {
			Irssi::signal_remove('message public', 'signals_idaumode');
			Irssi::signal_remove('message irc action', 'signals_idaumode');
		}
		$misc{signals}{'signals idaumode'} = 0;
	}
}

################################################################################
# Debugging
################################################################################

#BEGIN {
#	use warnings;
#
#	open(STDERR, ">> dau-stderr") or print "STDERR redirect failed: $!";
#}
