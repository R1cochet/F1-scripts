use strict;
use warnings;
use vars qw($VERSION %IRSSI);
use Irssi;
#binmode(STDOUT, ":utf8");
use LWP::Simple;
use HTML::TableExtract;
use HTML::TreeBuilder;

$VERSION = '1.00';
%IRSSI = (
    authors     => 'R1cochet',
    contact     => '#F1 on zone.ircworld.org',
    name        => 'F1 Script',
    description	=> 'Gets F1 Info',
    modules     => 'LWP::Simple, HTML::TableExtract, HTML::TreeBuilder',
    license     => 'GNU General Public License v3.0',
    changed     => 'Sun Oct 23 12:57:43 PDT 2011',
);

sub message_public {
    my ($server, $msg, $nick, $nick_addr, $target) = @_;
    return if ( $msg !~ /^!/i );                             # if text does not start with "!"
    if ($target  =~ m/#(?:f1|testbed)/) {                    # limit channels  "f1" or "testbed"
        #### Results Current ####
        if ( $msg =~ /^!results$/i ) {                       # if text is triggers
            my $table_current = new HTML::TableExtract( depth=>0, count=>0, gridmap=>0);     # set table to extract from
            my $tree_current = HTML::TreeBuilder->new;

            my $content_current = get("http://www.formula1.com/results/season/");   # webpage
            $table_current->parse($content_current);                          # parse the content of table on webpage
            $tree_current->parse($content_current);

            for my $header ($tree_current->look_down('_tag', 'h2')) {
                if ($header->as_text =~ /FIA/) {
                    my $current_header = $header->as_text;
                    $server->send_raw_now ( "privmsg $target :\002$current_header\002" );     # sends instantly negating client flood control
                }
            }

            foreach my $row ($table_current->rows) {
                if (@$row[2]) {
                    my $results_table = sprintf("%-14s%-11s%-21s%-18s%-5s%-10s", @$row[0], @$row[1], @$row[2], @$row[3], @$row[4], @$row[5]);
                    $server->send_raw_now ( "privmsg $target :$results_table" );
                }
                else {
                    my $results_table = sprintf("%-14s%-10s", @$row[0],  @$row[1]);
                    $server->send_raw_now ( "privmsg $target :$results_table" );
                }
            }
            $tree_current = $tree_current->delete;
        }
        #### Results by Year ####
        if ( $msg =~ /^!results (\d{4})$/ ) {
            my $season_year = $1;

            my $table_year = new HTML::TableExtract( depth=>0, count=>0, gridmap=>0);   # set the table
            my $tree_year = HTML::TreeBuilder->new;                                      # set the tree

            my $content_year = get("http://www.formula1.com/results/season/$season_year/"); # set the webpage

            if ($content_year) {
                $table_year->parse($content_year);                          # parse the content of table on webpage
                $tree_year->parse($content_year);                           # parse the content of tree on webpage

                for my $header ($tree_year->look_down('_tag', 'h2')) {
                   if ($header->as_text =~ /Formula|Grand\sPrix|FORMULA/) {
                        my $season_header = $header->as_text;
                        $server->send_raw_now ( "privmsg $target :\002$season_header\002" );     # sends instantly negating client flood control
                   }
                }

                my @link_year;
                my $line_year;
                foreach my $row ($table_year->rows) {
                    for my $link_year ($tree_year->look_down('_tag','a')) {
                        $line_year = $link_year->as_text;
                        if ($line_year =~ /@$row[0]/) {
                            @link_year = split('/',$link_year->as_HTML);
                            push(@$row, $link_year[4]);
                        }
                    }
                    @$row[3] = ltrim(@$row[3]);
                    @$row[6] = "GP#" unless defined @$row[6];
                    my $results_table = sprintf("%-17s%-11s%-5s%-22s%-21s%-5s%-10s", @$row[0], @$row[1], @$row[6], @$row[2], @$row[3], @$row[4], @$row[5]) if defined @$row[2];
                    $server->send_raw_now ( "privmsg $target :$results_table" );
                }
                $tree_year = $tree_year->delete;
            }
            else { $server->send_raw_now ( "privmsg $target :Season does not exist" ); }
        }
        #### Results by Race ####
        if ( $msg =~ /^!results (\d{4}) (\d+)$/ ) {
            my $race_year = $1;
            my $race_number = $2;

            my $table_race = new HTML::TableExtract( depth=>0, count=>0, gridmap=>0);   # set the table
            my $tree_race = HTML::TreeBuilder->new;                                      # set the tree

            my $content_race = get("http://www.formula1.com/results/season/$race_year/$race_number/"); # set the webpage

            if ($content_race) {
                $table_race->parse($content_race);                          # parse the content of table on webpage
                $tree_race->parse($content_race);                           # parse the content of tree on webpage

                for my $header ($tree_race->look_down('_tag', 'h2')) {
                    if ($header->as_text =~ m/Formula|Grand\sPrix|FORMULA/) {
                        my $race_header = $header->as_text;
                        $server->send_raw_now ( "privmsg $target :\002$race_header\002" );
                    }
                }

                my @link_race;
                my $line_race;
                foreach my $row ($table_race->rows) {
                    if (@$row[0] =~ /DSQ/) {
                        @$row[6] = "";
                    }
                    if (@$row[0] =~ /DNQ/) {
                        @$row[4] = @$row[5] = @$row[6] = "";
                    }
                    @$row[7] = "" unless defined @$row[7];
                    my $results_table = sprintf("%-4s%-4s%-22s%-21s%-5s%-16s%-5s%-3s", @$row[0], @$row[1], @$row[2], @$row[3], @$row[4], @$row[5], @$row[6], @$row[7]);
                    $server->send_raw_now ( "privmsg $target :$results_table" );
                }
                $tree_race = $tree_race->delete;
            }
            else { $server->send_raw_now ( "privmsg $target :Race does not exist" ); }
        }
        #### Constructors bt Year
        if ( $msg =~ /^!constructors (\d{4})$/ ) {
            my $constructor_year = $1;

            my $table_constructor = new HTML::TableExtract( depth=>0, count=>0, gridmap=>0);   # set the table

            my $content_constructor = get("http://www.formula1.com/results/team/$constructor_year/"); # set the webpage

            if ($content_constructor) {
                $table_constructor->parse($content_constructor);                          # parse the content of table on webpage

                $server->send_raw_now ( "privmsg $target :\002$constructor_year Constructors Standings\002" );

                foreach my $row ($table_constructor->rows) {
                    my $results_table = sprintf("%-4s%-21s%-6s", @$row[0], @$row[1], @$row[2]);
                    $server->send_raw_now ( "privmsg $target :$results_table" );
                }
            }
            else { $server->send_raw_now ( "privmsg $target :Season does not exist" ); }
        }
        #### Drivers by Year
        if ( $msg =~ /^!drivers (\d{4})$/ ) {
            my $driver_year = $1;

            my $table_driver = new HTML::TableExtract( depth=>0, count=>0, gridmap=>0);   # set the table

            my $content_driver = get("http://www.formula1.com/results/driver/$driver_year/");

            if ($content_driver) {
                $table_driver->parse($content_driver);                          # parse the content of table on webpage

                $server->send_raw_now ( "privmsg $target :\002$driver_year Drivers Standings\002" );

                foreach my $row ($table_driver->rows) {
                    @$row[1] = ltrim(@$row[1]);
                    @$row[3] = ltrim(@$row[3]);
                    my $results_table = sprintf("%-4s%-22s%-13s%-21s%-6s", @$row[0], @$row[1], @$row[2], @$row[3], @$row[4]);
                    $server->send_raw_now ( "privmsg $target :$results_table" );
                }
            }
            else { $server->send_raw_now ( "privmsg $target :Season does not exist" ); }
        }
    }
}

# Left trim function to remove leading whitespace
sub ltrim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}
Irssi::signal_add_last('message public', 'message_public');
