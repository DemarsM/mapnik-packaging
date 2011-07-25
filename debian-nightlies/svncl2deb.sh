#! /usr/bin/perl

#use Data::Dumper;

# create Debian changelog from svn log -v -rX:Y output
# Thomas Lange, lange@informatik.uni-koeln.de
# 11/2010

#    This program is free software; you can redistribute it and/or modify it
#    under the same terms as Perl itself.

# subroutine _do_log_commandline stolen from SVN::Log, http://search.cpan.org/~nikc/SVN-Log-0.03/lib/SVN/Log.pm
# modified to get information we need

# ==================================================

sub _do_log_commandline {
  my ($repos, $start_rev, $end_rev, $callback) = @_;

#  open my $log, "svn log -v -r $start_rev:$end_rev $repos|"
#    or die "couldn't open pipe to svn process: $!";

#  my ($paths, $rev, $author, $date, $msg);

  my $state = 'start';

  my $seprule  = qr/^-{72}$/;
  my $headrule = qr/r(\d+) \| (\w+) \| (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/;

  # XXX i'm sure this can be made much much cleaner...
  while (<>) {
    if ($state eq 'start' or $state eq 'message' and m/$seprule/) {
      if ($state eq 'start') {
        $state = 'head';
      } elsif ($state eq 'message') {
        $state = 'head';
        ####       $callback->($paths, $rev, $author, $date, $msg);
        # print Dumper($paths);

	# remove path from files, keep only file name
	foreach (@files) { s#.+/##}
	$fi = join ",",@files;
	$msg = (split /\n/,$msg)[0]; # only first line of commit message
	#DEBUG	print "FILES: $f\nAUT: $author\nMSG: $msg\n";
	push @{$all{$author}},"$fi: $msg\n";
      }
    } elsif ($state eq 'head' and m/$headrule/) {
      $rev = $1;
      $author = $2;
      $date = $3;
      $paths = {};
      @files=();
      $msg = "";

      $state = 'paths';
    } elsif ($state eq 'paths') {
      unless (m/^Changed paths:$/) {
        if (m/^$/) {
          $state = 'message';
        } else {
          if (m/^\s+(\w+) (.+)$/) {
	    my $action = $1;
	    my $str    = $2;

	    # If a copyfrom_{path,rev} is listed then include it,
	    # otherwise just note the path and the action.
	    if($str =~ /^(.*?) \(from (.*?):(\d+)\)$/) {
	      push @files,$1;
	      $paths->{$1}{action} = $action;
	      $paths->{$1}{copyfrom_path} = $2;
	      $paths->{$1}{copyfrom_rev} = $3;
	    } else {
	      push @files,$str;
	      $paths->{$str}{action} = $action;
	    }
          }
        }
      }
    } elsif ($state eq 'message') {
      $msg .= $_;
    }
  }
}

_do_log_commandline;

# print changelog entries
foreach (keys %all) {
  print "  [ $_ ]\n"; #author
  foreach (@{$all{$_}}) {
    print "  * $_";
  }
  print "\n\n";
}