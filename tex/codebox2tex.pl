#!/usr/bin/perl

# codebox2tex.pl
# Mike Rosulek, 2024-04-17
# 
# input (STDIN): 
#   simple domain-specific language for typesetting "library-based"
#   cryptography, as in "The Joy of Cryptography" textbook
#
# output: (STDOUT)
#   LaTeX code

chomp( my @lines = <> );

my $commonindent = 999;

# first line can be screwed up by latex
for (@lines[1..$#lines]) {
    next if ! /\S/;

    /^(\s*)/;
    $commonindent = min( $commonindent, length($1) );
}
for (@lines[1..$#lines]) {
    substr($_,0,$commonindent,"");
}

my @output;

my $insidelib = 0;
my $needlinebreak = 0;
my $emptybetweenboxes = 0;

for (@lines) {
    s/^(\s*)//;
    my $indentlevel = length($1)/4 - 1;

    if (/^(hl lib|lib|code)/) {
        if ($emptybetweenboxes) {
            push @output, "\\quad";
        }

        if (/^code/) {
            push @output, "\\codebox{";
        } elsif (/^hl lib\s+(\S.*?)\s*$/) {
            push @output, "\\hltitlecodebox{\$$1\$}{";
        } elsif (/^lib\s+(\S.*?)\s*$/) {
            push @output, "\\titlecodebox{\$$1\$}{";
        } else {
            push @output, "\\fcodebox{";
        }
        $insidelib = 1;
        $needlinebreak = 0;
        $emptybetweenboxes = 0;
    }
    elsif (/^fig (.*)/) {
        push @output, "\\includefig{$1}";
    }
    elsif (/^end/) {
        push @output, "}";
        $insidelib = $needlinebreak = 0;
        $emptybetweenboxes = 1;
    }
    elsif (/^proc\s+(.*?)\((.*)\)/) {
        my $procname   = $1;
        my $args       = $2;

        $args = "\\," if $args eq "";

        if ($procname =~ /^\$(.*)\$$/) {
            $procname = $1;
        } elsif ($procname =~ /^[a-zA-Z.]*$/) {
            $procname = "\\subname{$procname}";
        }

        $output[-1] .= "\\\\" if $needlinebreak;

        push @output, ("\\> " x $indentlevel)
            . "\\procheader{\$$procname($args)\$:}";

        $needlinebreak = 1;
    }
    elsif (/^$/) {
        if ($insidelib) {
            $output[-1] .= "\\\\[8pt]" if $needlinebreak;
            $needlinebreak = 0;
        }
    }
    else {
        $output[-1] .= "\\\\" if $needlinebreak;

        # no dollar signs --> the entire line is math
        # exception: a line like "else:" or "abort"
        $_ = "\$$_\$" if not /\$/ and not /\/\//
                     and not /^\w*:?$/;

        s/(?:\/\/|\#)[ ]*(.*)/\\mycomment{$1}/;

        push @output, ("\\> " x $indentlevel) . $_;
        $needlinebreak = 1 if $insidelib;
        $emptybetweenboxes = 0 if not $insidelib;
    }
}

push @output, '\\PackageError{pipetex}{Missing end-of-library command in pipetex}{}' 
    if $insidelib;


print "\\begin{varwidth}{\\linewidth}\n";
print "    $_\n" for @output;
print "\\end{varwidth}";


sub min {
    $_[0] < $_[1] ? $_[0] : $_[1];
}
