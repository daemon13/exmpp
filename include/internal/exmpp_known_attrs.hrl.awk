# $Id$

BEGIN {
	print "% $Id$";
}

/^# Generated by/ {
	print "% " $0 "\n";
	print "-define(XMPP_KNOWN_ATTRS, [";
}

/^[^#]/ {
	if (!already_processed[$1]) {
		print "  '" $1 "',";
		already_processed[$1] = 1;
	}
}

END {
	print "  '$end_of_table'";
	print "]).";
}
