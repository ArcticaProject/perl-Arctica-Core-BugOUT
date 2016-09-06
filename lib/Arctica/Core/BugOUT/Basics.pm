################################################################################
#          _____ _
#         |_   _| |_  ___
#           | | | ' \/ -_)
#           |_| |_||_\___|
#                   _   _             ____            _           _
#    / \   _ __ ___| |_(_) ___ __ _  |  _ \ _ __ ___ (_) ___  ___| |_
#   / _ \ | '__/ __| __| |/ __/ _` | | |_) | '__/ _ \| |/ _ \/ __| __|
#  / ___ \| | | (__| |_| | (_| (_| | |  __/| | | (_) | |  __/ (__| |_
# /_/   \_\_|  \___|\__|_|\___\__,_| |_|   |_|  \___// |\___|\___|\__|
#                                                  |__/
#          The Arctica Modular Remote Computing Framework
#
################################################################################
#
# Copyright (C) 2015-2016 The Arctica Project 
# http://http://arctica-project.org/
#
# This code is dual licensed: strictly GPL-2 or AGPL-3+
#
# GPL-2
# -----
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
# Free Software Foundation, Inc.,
#
# 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
#
# AGPL-3+
# -------
# This programm is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This programm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Copyright (C) 2015-2016 Guangzhou Nianguan Electronics Technology Co.Ltd.
#                         <opensource@gznianguan.com>
# Copyright (C) 2015-2016 Mike Gabriel <mike.gabriel@das-netzwerkteam.de>
#
################################################################################
package Arctica::Core::BugOUT::Basics;
use strict;
use Exporter qw(import);
use Data::Dumper;
# Be very selective about what (if any) gets exported by default:
our @EXPORT = qw(genRandID);
# And be mindfull of what we lett the caller request here too:
our @EXPORT_OK = qw( BugOUT bugOutCfg BugOUT_dumpObjects);



my %bugOutCfg = (
	'bug_level' => 9,
	'log_target' => 'stderr',
	'dev_mode' => 0,
	'live_stream' => 1,
	'active' => 0,
	'aexid' => 0,
);

sub new {
	my ($className,$options) = @_;
#print "<<<<<<<<< NEW BUG: $options->{'aexid'}\n";
	my $BugOUT_self = {	
		dummydata => {
			somevalue	=> 123,
			otherinfo	=> "The Other INFO!",
		},
		_conf => \%bugOutCfg,
		isArctica => 1, # Declare that this is a Arctic "something" 
	};
	
	bless ($BugOUT_self, $className);
	bugOutCfg(undef,'set','aexid',$options->{'aexid'});
	bugOutCfg(undef,'set','log_target','stdquiet');
	bugOutCfg(undef,'set','active',1);
	
	BugOUT(8,"Initiating DEBUGGER...");
	# DO SOMETHING ELSE TO TIE INDIVIDUAL SIGNALS TO RESPECTIVE FUNCTIONS
	# Probably Make a SIG SET sub at some point....
	$SIG{__WARN__} = sub {BugOUT(1,$_[0]);};
	$SIG{__DIE__} = sub {BugOUT(0,$_[0]);};

	return $BugOUT_self;
}

sub BugOUT_dumpObjects {
# TMP function, will be replaced soon!
	my $theObj = $_[0];
	if ($theObj) {
		if ($bugOutCfg{'aexid'} =~ /^([a-zA-Z0-9\_\-]{16,})$/) {
			my $progid = $1;
			unless (-d "/tmp/arctica_BugOUT") {
				mkdir("/tmp/arctica_BugOUT") or BugOUT(1,"Unable to create /tmp/arctica_BugOUT");
			}
	
			if  (-d "/tmp/arctica_BugOUT") {
				my $timeout = Glib::Timeout->add(2000, 
				sub {
					open(DUMP,">/tmp/arctica_BugOUT/$progid.otdmp");
					print DUMP time,"\n",Dumper($theObj);
					close(DUMP);		
				} );
			}
		}
		return 1;
	} else {return 0;}
}

sub BugOUT {
	my $bug_level = $_[0];
	my $bugText = $_[1];
	my $bugCode = $_[2];
	if ($bugCode) {# Primarily overdone to keep from warn when warn...
		$bugCode =~ s/\D//g;
		if ($bugCode =~ /^(\d{1,})$/) {
			$bugCode = $1;
		} else {
			$bugCode = 0;
		}
	} else {
		$bugCode = 0;
	}
	$bug_level =~ s/\D//g;
	if ($bug_level =~ /^(\d)$/) {
		$bug_level = $1;
		my $logLine;
		if ($bug_level <= $bugOutCfg{'bug_level'}) {
			$bugText =~ s/\n//g;
			my $bugTime;
			if ($bugOutCfg{'bug_level'} eq 1) {
				$bugTime = time();#replace this with high resolution time!
			} else {
				$bugTime = time();
			}
			my $progid = 0;
			if ($bugOutCfg{'aexid'} =~ /^([a-zA-Z0-9\_\-]{16,})$/) {
				$progid = $1;
			}
			$logLine = "$bugTime;$progid;$bug_level;$bugCode;$bugText";
			$logLine =~ s/\n//g;

			if (1 eq 2) {
			} elsif ($bugOutCfg{'log_target'} eq "stderr") {
				print STDERR "BUGOUT:$logLine\n";
			} elsif ($bugOutCfg{'log_target'} eq "stdout") {
				print STDOUT "BUGOUT:$logLine\n";
			} elsif ($bugOutCfg{'log_target'} eq "stdquiet") {
				# DO NOTHING!
			}

			if ($bugOutCfg{'live_stream'} eq 1) {
				# COPY TO LIVE VIEW
				open(TMP,">>/tmp/arctica.log");#dirty FIX THIS!
				print TMP "$logLine\n";
				close(TMP);
			}
		}
		if ($bug_level eq 0) {
			exit 0;
		}
	}
	return 1;
}

sub bugOutCfg {
	# WONKY PLACE KEEPER...
	# WILL BE REPALCED WITH GENERIC CONFIG ROUTINE
	# and when we do, we'll be more purlish...
	my $action = $_[1];
	my $valueName = $_[2];
	my $theValue = $_[3];
	if ($action eq "get") {
		if ($bugOutCfg{$valueName} ne '') {
			return $bugOutCfg{$valueName};
		} else {return 0;}
	} elsif ($action eq "set") {
		if ($bugOutCfg{$valueName} ne '') {
			if ($valueName eq "bug_level") {
				if ($theValue =~ /^(\d)$/) {
					if (($theValue > 1) and ($theValue < 10)) {
						$bugOutCfg{'bug_level'} = $1;
						return 1;
					} else {return 0;}
				} else {return 0;}
			} elsif ($valueName eq "log_target") { 
				if ($theValue eq "stdout") {
					$bugOutCfg{'log_target'} = "stdout";
				} elsif ($theValue eq "stderr") {
					$bugOutCfg{'log_target'} = "stderr";
				} elsif ($theValue eq "stdquiet") {
					$bugOutCfg{'log_target'} = "stdquiet";
				} else {return 0;}
			} elsif ($valueName eq "active") { 
				if ($theValue eq 1) {
					$bugOutCfg{'active'} = 1;
				} elsif ($theValue eq 0) {
					$bugOutCfg{'active'} = 0;
				} else {return 0;}
			} elsif ($valueName eq "aexid") { 
				if ($theValue =~ /^([a-zA-Z0-9\_\-]{16,})$/) {
					$bugOutCfg{'aexid'} = $1;
				} else {
					$bugOutCfg{'aexid'} = undef;
					return 0;
				}
				
			} else {return 0;}
		} else {return 0;}
	} else {return 0;}
}

1;
