use strict;
use vars qw($VERSION %IRSSI);
use Irssi;
use LWP::Simple;
use HTML::TableExtract;
use HTML::Tree;
use Date::Manip;

$VERSION = '1.10';
%IRSSI = (
    authors     => 'R1cochet',
    contact     => '#F1 on zone.ircworld.org',
    name        => 'F1 Script',
    description	=> 'Gets F1 Info',
    modules     => 'LWP::Simple, HTML::TableExtract, HTML::Tree, Date::Manip',
    license     => 'GNU General Public License v3.0',
    changed     => 'Thu Oct 20 21:25:36 PDT 2011',
);

sub message_public {
   my ($server, $msg, $nick, $nick_addr, $target) = @_;
   my $nickname = $server->{nick};                          # gets bots current nickname
   return if ( $msg !~ /^!/i );                             # if text does not start with "!"
   if ($target  =~ m/#(?:f1|testbed)/) {                    # limit channels  "f1" or "testbed"
      if ( $msg =~ /^!triggers$/i ) {                       # if text is triggers
         my $help = "!constructors, !drivers, !next, !weekend";
         $server->send_raw_now ( "privmsg $target :\002Triggers:\002 $help" );
         $server->print($target, "\002Triggers:\002 $help", MSGLEVEL_NOTICES);
      }
      ######################## Drivers Listing ####################
      if ( $msg =~ /^!drivers$/i ) {                        # if text is drivers
         my $drivrs  = new HTML::TableExtract( depth=>2, count=>0, gridmap=>0);     # set table to extract from
         my $content = get("http://news.bbc.co.uk/sport2/hi/motorsport/formula_one/standings/default.stm");   # webpage
         $drivrs->parse($content);                          # parse the content of table on webpage
         my $row;                                           # initialize variables
         my $standings1;
         my $standings2;
         my $row_Count = 0;
         foreach $row ($drivrs->rows) {                     # Counts total number of drivers
            $row_Count++;
         }
         $server->send_raw_now ( "privmsg $target :\002Drivers Championship Standings:\002" );     # send header
         $server->print($target, "\002Drivers Championship Standings:\002", MSGLEVEL_NOTICES);     # print header to channel for self
         my $i = 1;
         foreach $row ($drivrs->rows) {                     # print each row to variable
            if ( $i == 1 ) {
               $i++;                                        # skip first field
            }
            elsif ( $i > 1 && $i < 16 ) {
               $standings1 = $standings1 . "@$row[0]) @$row[1] @$row[4] \002|\002 ";
               $i++;
            }
            elsif ( $i >= 16 && $i < $row_Count ) {
               $standings2 = $standings2 . "@$row[0]) @$row[1] @$row[4] \002|\002 ";
               $i++;
            }
            elsif ( $i == $row_Count ) {
               $standings2 = $standings2 . "@$row[0]) @$row[1] @$row[4]";
               $i++;
            }
         }
         $server->send_raw_now( "privmsg $target :$standings1" );     # sends instantly negating client flood control
         $server->send_raw_now( "privmsg $target :$standings2" );
         $server->print($target, "$standings1 $standings2", MSGLEVEL_NOTICES);      # print to channel for self
#         $server->print($target, $standings2, MSGLEVEL_NOTICES);
      }
      ######################## Constructors Listing ########################
      if ( $msg =~ /^!constructors$/i ) {
         my $const  = new HTML::TableExtract( depth=>2, count=>1, gridmap=>0);     # set table to extract from
         my $content = get("http://news.bbc.co.uk/sport2/hi/motorsport/formula_one/standings/default.stm");   # webpage
         $const->parse($content);                           # parse the content of table on webpage
         my $row;                                           # initialize variables
         my $standings1;
         my $standings2;
         my $row_Count = 0;
         foreach $row ($const->rows) {                      # Counts total number of drivers
            $row_Count++;
         }
         $server->send_raw_now ( "privmsg $target :\002Constructors Championship Standings:\002" );    # send header
         $server->print($target, "\002Constructors Championship Standings:\002", MSGLEVEL_NOTICES);    # print header to channel for self
         my $i = 1;
         foreach $row ($const->rows) {                      # print each row to variable
            if ( $i == 1 ) {
               $i++;                                        # skip first field
            }
            elsif ( $i > 1 && $i <= $row_Count / 2 + 1) {
               $standings1 = $standings1 . "@$row[0]) @$row[1] @$row[2] \002|\002 ";
               $i++;
            }
            elsif ( $i > $row_Count / 2 + 1 && $i < $row_Count ) {
               $standings2 = $standings2 . "@$row[0]) @$row[1] @$row[2] \002|\002 ";
               $i++;
            }
            elsif ( $i == $row_Count ) {
               $standings2 = $standings2 . "@$row[0]) @$row[1] @$row[2]";
               $i++;
            }
         }
         $server->send_raw_now ( "privmsg $target :$standings1" );    # sends instantly negating client flood control
         $server->send_raw_now ( "privmsg $target :$standings2" );
         $server->print($target, $standings1, MSGLEVEL_NOTICES);      # print to channel for self
         $server->print($target, $standings2, MSGLEVEL_NOTICES);
      }
      ######################## Next Race countdown #######################
      if ( $msg =~ /^!next$/i ) {
         my $page = "http://www.formula1.com/default.html";
         my $content = get($page);
         my $tree = HTML::Tree->new();
         $tree->parse($content);
         my $c;
         my @race;
         for my $script ($tree->look_down( '_tag' , 'script' )) {
            $c = join '\n', $script->content_list();
            if ($c =~ /grand_prix\[0\]/) {
               @race = split('ArrayItem',$c);               # split string by 'ArrayItem' if 'grand_prix' is in text
               shift(@race);                                # removes first element of array ( not needed )
            }
         }
         my @location = split(';',$race[0]);            # split $race[0] by ';'
         $race[0] = $location[0];                       # $race[0] = $location[0] after being split
         my @location = split(',',$race[0]);            # split $race[0] by ','
         shift(@location); shift(@location);            # pop(@location);
         for (my $i = 0; $i <= $#location; $i++) {
            $location[$i] =~ s/[^a-zA-Z0-9 \:]//g;      # removes all non-character,digit, and :'s
         }
         my @gp = split(',',$race[5]);
         pop(@gp); pop(@gp); pop(@gp);
         for ( my $i = 0; $i <= $#gp; $i++ ) {
            $gp[$i] =~ s/[^a-zA-Z0-9 \:]//g;
         }
         ##### Parse the time dfference #####
         my $time = localtime;
         $time = &ParseDate($time);
         my $delta = &DateCalc($time,$gp[1]);
         $delta =~ s/\+//g;
         my ($year, $month, $week, $day, $hour, $min, $sec) = split(":",$delta);
         my $weeks = "weeks";
         my $days = "days";
         $hour =~ s/(^[0-9]$)/0$1/;
         $min =~ s/(^[0-9]$)/0$1/;
         $sec =~ s/(^[0-9]$)/0$1/;
         if ( $week == 1 ) { $weeks = "week"; }
         if ( $day == 1 ) { $days = "day"; }
         my $nextrace1 = "\002Next Race:\002 $location[0], $location[1]";
         my $nextrace2 = "\002Start Time:\002 $week $weeks $day $days $hour:$min:$sec";
         $server->send_raw_now ( "privmsg $target :$nextrace1" );    # sends instantly negating client flood control
         $server->send_raw_now ( "privmsg $target :$nextrace2" );
         $server->print($target, $nextrace1, MSGLEVEL_NOTICES);      # print to channel for self
         $server->print($target, $nextrace2, MSGLEVEL_NOTICES);
      }
      ######################## Weekend Events ############################
      if ( $msg =~ /^!weekend/i ) {
         my $page = "http://www.formula1.com/default.html";
         my $content = get($page);
         my $tree = HTML::Tree->new();
         $tree->parse($content);
         my $c;
         my @race;
         for my $script ($tree->look_down( '_tag' , 'script' )) {
            $c = join '\n', $script->content_list();
            if ($c =~ /grand_prix\[0\]/) {
               @race = split('ArrayItem',$c);               # split string by 'ArrayItem' if 'grand_prix' is in text
               shift(@race);                                # removes first element of array ( not needed )
            }
         }
         my @location = split(';',$race[0]);            # split $race[0] by ';'
         $race[0] = $location[0];                       # $race[0] = $location[0] after being split
         my @location = split(',',$race[0]);            # split $race[0] by ','
         shift(@location); shift(@location);            # pop(@location);
         for (my $i = 0; $i <= $#location; $i++) {
            $location[$i] =~ s/[^a-zA-Z0-9 \:]//g;      # removes all non-character,digit, and :'s
         }
         my @p1 = split(',',$race[1]);
         pop(@p1); pop(@p1); pop(@p1); pop(@p1);
         for ( my $i = 0; $i <= $#p1; $i++ ) {
            $p1[$i] =~ s/[^a-zA-Z0-9 \:]//g;
         }
         my @p2 = split(',',$race[2]);
         pop(@p2); pop(@p2); pop(@p2); pop(@p2);
         for ( my $i = 0; $i <= $#p2; $i++ ) {
            $p2[$i] =~ s/[^a-zA-Z0-9 \:]//g;
         }
         my @p3 = split(',',$race[3]);
         pop(@p3); pop(@p3); pop(@p3); pop(@p3);
         for ( my $i = 0; $i <= $#p3; $i++ ) {
            $p3[$i] =~ s/[^a-zA-Z0-9 \:]//g;
         }
         my @quali = split(',',$race[4]);
         pop(@quali); pop(@quali); pop(@quali); pop(@quali);
         for ( my $i = 0; $i <= $#quali; $i++ ) {
            $quali[$i] =~ s/[^a-zA-Z0-9 \:]//g;
         }
         my @gp = split(',',$race[5]);
         pop(@gp); pop(@gp); pop(@gp);
         for ( my $i = 0; $i <= $#gp; $i++ ) {
            $gp[$i] =~ s/[^a-zA-Z0-9 \:]//g;
         }
         if ( $msg =~ /(.+) (\w+)/ ) {
            my $time_zone = uc($2);
            $p1[1] = Date_ConvTZ($p1[1], "GMT", $time_zone);
            $p1[1] = UnixDate($p1[1],"%e %b %Y %T $time_zone");
            $p2[1] = Date_ConvTZ($p2[1], "GMT", $time_zone);
            $p2[1] = UnixDate($p2[1],"%e %b %Y %T $time_zone");
            $p3[1] = Date_ConvTZ($p3[1], "GMT", $time_zone);
            $p3[1] = UnixDate($p3[1],"%e %b %Y %T $time_zone");
            $quali[1] = Date_ConvTZ($quali[1], "GMT", $time_zone);
            $quali[1] = UnixDate($quali[1],"%e %b %Y %T $time_zone");
            $gp[1] = Date_ConvTZ($gp[1], "GMT", $time_zone);
            $gp[1] = UnixDate($gp[1],"%e %b %Y %T $time_zone");
         }
         my $weekend1 = "\002$p1[0]:\002 $p1[1] | \002$p2[0]:\002 $p2[1] | \002$p3[0]:\002 $p3[1]";
         my $weekend2 = "\002$quali[0]:\002 $quali[1] | \002$gp[0]:\002 $gp[1]";
         $server->send_raw_now ( "privmsg $target :$weekend1" );     # sends instantly negating client flood control
         $server->send_raw_now ( "privmsg $target :$weekend2" );
         $server->print($target, $weekend1, MSGLEVEL_NOTICES);       # print to channel for self
         $server->print($target, $weekend2, MSGLEVEL_NOTICES);
      }
   }
}
sub own_public {
    my ($server, $msg, $target) = @_;
    message_public ($server, $msg, $server->{nick}, "", $target);     # I think the "" fill a var to empty
}                                                                     # needed for proper var spacing
Irssi::signal_add_last('message public', 'message_public');
Irssi::signal_add_last('message own_public', 'own_public');
