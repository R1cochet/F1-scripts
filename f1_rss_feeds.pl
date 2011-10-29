use strict;
use warnings;
use vars qw($VERSION %IRSSI);
use Irssi;
use XML::FeedPP;

$VERSION = '1.05.013';
%IRSSI = (
    authors     => 'R1cochet',
    contact     => '#F1 on irc.chatspike.net',
    name        => 'F1 RSS Feed Reader',
    description	=> 'Retrieves and posts F1 RSS feeds to the channel',
    modules     => 'XML::FeedPP',
    license	    => 'GNU General Public License v3.0',
    changed     => 'Tue Jul 26 18:42:01 PDT 2011',
);

my $rsshelp = <<'EOL';
Use "!rss-use" for help on how to use the triggers
Use "!rss-feeds" to see the available feeds and their triggers
EOL

my $rssuse = <<'EOL';
There are two different ways to use the triggers.
You can just type the trigger, in which case the
three most recent articles from that feed will be
sent to the channel. The other way is to type the
trigger then space then a number. ex: !f1-late 5
The preceeding example will pm the five most recent
artcles to the user. You may use as large a number
as you like, but the returned results depends on
how many articles the feed contains.
EOL

my $rssfeeds = <<'EOL';
Trigger:      Feed:
!bbc          BBC.co.uk
!espn         ESPNf1.com
!f1-late      Formula1.com - Latest News
!f1-head      Formula1.com - Headlines
!f1-feat      Formula1.com - Features
!f1-int       Formula1.com - Interviews
!f1fan        F1fanatic.co.uk
!f1tech-dev   F1technical.net - Development News
!f1tech-tech  F1technical.net - Technical News
!forum        Forumula1.com
!gp           Granprix.com
!scarbs       Scarbs F1 Wordpress
!wtf1         WTF1.co.uk
!slate        TheF1Slate.com
EOL

sub message_public {                                         # parse the message
    my ($server, $msg, $nick, $nick_addr, $target) = @_;
    return if ( $msg !~ /^!/i );                             # stop if text does not start with "!"
    if ($target  =~ m/#(?:f1|testbed)/) {                    # limit channels  "f1" or "testbed"
        if ( $msg =~ /^!rss-help$/i ) {                      # if text is !rss-help
            foreach my $line ( split /\n/, $rsshelp ) {
                $server->send_raw_now ( "privmsg $nick :$line" );
            }
        }
        if ( $msg =~ /^!rss-use$/i ) {                       # explains how to use
                                                             # after setup to req amount of links
            foreach my $line ( split /\n/, $rssuse ) {
                $server->send_raw_now ( "privmsg $nick :$line" );
            }
        }
        if ( $msg =~ /^!rss-feeds$/i ) {                     # if text is !rss-feed
            foreach my $line ( split /\n/, $rssfeeds ) {
                $server->send_raw_now ( "privmsg $nick :$line" );
            }
        }

        if ( $msg =~ /^!f1-late/i ) {
            my $source = 'http://www.formula1.com/rss/news/latest.rss';
            parse_amount ($server, $target, $nick, $source, $msg);
        }
        if ( $msg =~ /^!f1-head/i ) {
            my $source = 'http://www.formula1.com/rss/news/headlines.rss';
            parse_amount ($server, $target, $nick, $source, $msg);
        }
        if ( $msg =~ /^!f1-feat/i ) {
            my $source = 'http://www.formula1.com/rss/news/features.rss';
            parse_amount ($server, $target, $nick, $source, $msg);
        }
        if ( $msg =~ /^!f1-int/i ) {
            my $source = 'http://www.formula1.com/rss/news/interviews.rss';
            parse_amount ($server, $target, $nick, $source, $msg);
        }
        if ( $msg =~ /^!bbc/i ) {
            my $source = 'http://newsrss.bbc.co.uk/rss/sportonline_uk_edition/motorsport/formula_one/rss.xml';
            parse_amount ($server, $target, $nick, $source, $msg);
        }
        if ( $msg =~ /^!espn/i ) {
            my $source = 'http://en.espnf1.com/rss/motorsport/story/feeds/0.xml?type=2';
            parse_amount ($server, $target, $nick, $source, $msg);
        }
        if ( $msg =~ /^!gp/i ) {
            my $source = 'http://www.grandprix.com/ft/rss.xml';
            parse_amount ($server, $target, $nick, $source, $msg);
        }
        if ( $msg =~ /^!f1tech-tech/i ) {
            my $source = 'http://feeds.feedburner.com/F1technicalnetTechnicalArticles';
            parse_amount ($server, $target, $nick, $source, $msg);
        }
        if ( $msg =~ /^!f1tech-dev/i ) {
            my $source = 'http://feeds.feedburner.com/F1technicalnetDevelopment';
            parse_amount ($server, $target, $nick, $source, $msg);
        }
        if ( $msg =~ /^!scarbs/i ) {
            my $source = 'http://scarbsf1.wordpress.com/feed/';
            parse_amount ($server, $target, $nick, $source, $msg);
        }
        if ( $msg =~ /^!f1fan/i ) {
            my $source = 'http://feeds.feedburner.com/f1fanatic';
            parse_amount ($server, $target, $nick, $source, $msg);
        }
        if ( $msg =~ /^!forum/i ) {
            my $source = 'http://feeds.feedburner.com/Forumula1-News';
            parse_amount ($server, $target, $nick, $source, $msg);
        }
        if ( $msg =~ /^!wtf1/i ) {
            my $source = 'http://wtf1.co.uk/rss';
            parse_amount ($server, $target, $nick, $source, $msg);
        }
        if ( $msg =~ /^!slate/i ) {
            my $source = 'http://feeds.feedburner.com/TheF1Slate';
            parse_amount ($server, $target, $nick, $source, $msg);
        }
    }
}

sub parse_amount {
    my ($server, $target, $nick, $source, $msg) = @_;
    if ( $msg =~ /(.+) (\d+)/ ) {
        my $amount = $2;
        print_feeds ($server, $nick, $source, $amount);
    }
    else {
        my $amount = 3;
        print_feeds ($server, $target, $source, $amount);
    }
}

sub print_feeds {
    my ($server, $target, $source, $amount) = @_;                         # retrive vars from calling routine
    my $count = 0;
    my $feed = XML::FeedPP->new( $source );
    my $site = $feed->title();

    $server->send_raw_now ( "privmsg $target :\002Feed: $site\002" );     # send RSS Feed Title
    if ( $target =~ /^#/ ) {                                              # limit print to channel only
        $server->print($target, "\002Feed: $site\002", MSGLEVEL_NOTICES);     # print RSS Feed Title if not a pm
    }

    foreach my $item ( $feed->get_item() ) {
        my $title = $item->title();
        my $link = $item->link();
        $server->send_raw_now ( "privmsg $target :\002Title:\002 $title" );
        $server->send_raw_now ( "privmsg $target :\002URL:\002 $link" );

        if ( $target =~ /^#/ ) {
            $server->print($target, "\002Title:\002 $title", MSGLEVEL_NOTICES);
            $server->print($target, "\002URL:\002 $link", MSGLEVEL_NOTICES);
        }

        $count++;
        if ( $count == $amount) {
            return;
        }
    }
}

sub own_public {                                                      # passes own msg to message_public routine
    my ($server, $msg, $target) = @_;
    message_public ($server, $msg, $server->{nick}, "", $target);     # I think the "" fill a var to empty
}

Irssi::signal_add('message public', 'message_public');
Irssi::signal_add('message own_public', 'own_public');
