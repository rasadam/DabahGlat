#Copyright (c) 2021 RAS.Land All Rights Reserved.
#writen by Adam Borenstein
#Version 1.0

#Changelog
#v1.0 initial release

use strict;
use warnings;
use Getopt::Long;
use Path::Tiny;
use Data::Dumper;
use File::BOM qw( :all );
use POSIX;

use constant PROMOTYPE => 29;
use constant MINQTY => 20;
use constant ISWEIGHT => 2;
use constant DISCOUNTEDPRICE => 25;
use constant DISCOUNTEDPRICEPERUNIT => 26;
# use constant SCM_KNE => 15;
# use constant CMT_KNE => 14;
# use constant PrtSwShakil => 9;

my $g_fileName;

Init();

my @lines = ReadFile( $g_fileName );
my $header = shift @lines;
my @g_header = GetHeaders( $header );

# my $index = 0;
# foreach my $header ( @g_header ) {
#   print "${index} - ${header}\n";
#   ++$index;
# }
# exit();

#now the lines contain only data with no headers.

@lines = ProcessLines( @lines );
$header =~ s/\n//;
$header =~ s/\r//;

unshift( @lines, $header );
SaveNewFile( $g_fileName , \@lines );


################################################################################
################################Internal use subs###############################
################################################################################

sub SaveNewFile {
  my $outFile = shift @_;
  my @data = @{shift @_};
  open(HANDLE, '>:via(File::BOM)', $outFile) or die $!;
  while ( scalar @data ) {
    print HANDLE shift @data;
    print HANDLE "\n";
  }
  close( HANDLE );
}

sub ProcessLines {
  my @lines = @_;
  my @processedLines;
  while ( @lines ) {
    my $line = shift @lines;
    $line =~ s/\n//;
    $line =~ s/\r//;
    my @lineData = split( ",", $line );
    my $createNewLine = 0;
    if ( $lineData[PROMOTYPE] && $lineData[PROMOTYPE] eq "4" && $lineData[MINQTY] < 1 ) {
      $lineData[MINQTY] = "1";
      $createNewLine = 1;
    }
    if ( $lineData[DISCOUNTEDPRICE] && $lineData[ISWEIGHT] == 1 ) {
      $lineData[DISCOUNTEDPRICEPERUNIT] = RoundPrice(  $lineData[DISCOUNTEDPRICEPERUNIT] );
      $lineData[DISCOUNTEDPRICE] = RoundPrice(  $lineData[DISCOUNTEDPRICE] );
      $createNewLine = 1;
    }

    if ( $createNewLine == 1) {
      $line = join( ",", @lineData );
    }

    push( @processedLines, $line );
  }
  return @processedLines;
}

sub RoundPrice {
  my $price = shift @_;
  my ( $shekel, $agorot ) = split( /\./, $price );
  if ( !defined $agorot ) {
    $price = $shekel . ".00";
    return $price;
  }
  if ( length($agorot) == 1 ) {
    $agorot .= "0";
  }

  my $lastDig = $agorot % 10;
  if ( $lastDig != 0 ) {
    my $diff = 10 - $lastDig;
    $agorot += $diff;
  }
  if ( $agorot >= 100 ) {
    $agorot -= 100;
    ++$shekel;
  }
  if ( $agorot == 0 ) {
    $agorot = "00";
  }

  $price = "$shekel.$agorot";
  return $price;
}

sub GetPrice {
  my $data = shift @_;
  $data =~ m/(\d+).* ([0-9]*)/;
  return ( $1, $2 );
}


sub GetAmount {
  my $str = shift @_;
  my ($num) = $str =~ m/^.*?(\d+)/;
  if ( $num < 2 || $num >8 ) { #number is probebly a price and not an amount
    $num = 1;
  }
  return $num;
}


sub GetHeaders {
  my $headerLine = shift @_;
  my @headerList = split( ",", $headerLine );
  return @headerList;
}


# sub ReadFile {
#   my @fileLines = path( $g_fileName )->lines_utf8;
#   return @fileLines;
# }

sub ReadFile {
  my $file = shift @_;
  open(HANDLE, '<:via(File::BOM)', $file);
  my @lines;
  while ( my $string = <HANDLE> ) {
    push( @lines, $string );
  }
  close( HANDLE );
  return @lines;
}


sub Init {
  GetCommadLineParams();
  VerifyParameters();
}

sub VerifyParameters {
  unless ( $g_fileName ) {
    ExitProg( " File name is a mandatory parameter.\n Use -f" );
  }
  unless ( -f $g_fileName ) {
    ExitProg( "'${g_fileName}' is not a file.\n" );
  }
}

sub ExitProg {
  print shift @_;
  exit();
}


sub GetCommadLineParams {
  GetOptions(
      "f|file=s" => \$g_fileName
    );
}
