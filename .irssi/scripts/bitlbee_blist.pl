use strict;
use vars qw(%topics);
use vars qw($VERSION %IRSSI);
use Irssi;

$VERSION = '0.1';
%IRSSI = (
    authors	=> 'Tijmen Ruizendaal',
    contact	=> 'timing@fokdat.nl',
    name	=> 'blist',
    description	=> '/blist <all|online|offline|away> <word>,  greps <word> from blist for bitlbee',
    license	=> 'GPLv2',
    url		=> 'http://fokdat.nl/~tijmen/software/index.html',
    changed	=> 'today',
);

my ($list, $word);
sub blist {
  my ($args, $server, $winit) = @_;
  ($list, $word) = split(/ /, $args, 2);
  Irssi::active_win()->command("msg #bitlbee blist $list");
  Irssi::signal_add('event privmsg', 'grep');  
}
sub grep{
  my ($server, $data, $nick, $address) = @_;
  my ($target, $text) = split(/ :/, $data, 2);
  if ($text =~ /$word/ && $target =~ /#bitlbee/){
  ##do nothing
  }else{Irssi::signal_stop();}
  if ($text =~ /buddies/ && $target =~/#bitlbee/){Irssi::signal_remove('event privmsg', 'grep');} 
}
Irssi::command_bind('blist','blist');
