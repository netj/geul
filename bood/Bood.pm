#!/usr/bin/perl
# 붓 Bood: A Transformer for Documents into XML
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2005-12-17

package Bood;

use strict;
use utf8;
use XML::Generator;
use POSIX;

our $TextWidth = 74; # We will assume the author did not intentionally break
                     # the lines longer than this width.

our $NameSpace_XHTML = ["http://www.w3.org/1999/xhtml"];
our $NameSpace_XInclude = ["xi" => "http://www.w3.org/2001/XInclude"];
our $X = new XML::Generator(namespace => $NameSpace_XHTML);


sub body2xml {
    my $fh = shift;
    my $body = { type => "body", indent => -1, content => [] };
    my @blocks = ($body);
    while (my $line = <$fh>) {
        utf8::decode($line);
        my $block = { type => undef, indent => undef, content => [] };
        my $lineoverflow = (length $line) gt $TextWidth;
        # TODO How about extending lines with \ or nesting blocks with
        # something else like ((( ))) and process recursively?
        # Long lines for table cells look terrible :(  And we can't use
        # smart layouts with tables, either.
        if ($blocks[-1]->{type} =~ /verbatim|preformatted/) {
            if ($line =~ /^(.*)(}}}|--8<--)\s*$/) {
                my $inner = $1;
                if (not escaped($inner)) {
                    # found the end of verbatim|preformatted
                    $line = $inner;
                    # suppose we found our parent block
                    $block = $blocks[-2];
                }
            }
            $blocks[-1]->{content}->[-1] .= $line;
            next if not defined $block->{type};
            # verbatim|preformatted block has ended
            $line = "";
        } else {
            # count current indent
            chomp $line;
            $line =~ /^(\s*)/;
            $block->{indent} = length $1;
            substr $line, 0, $block->{indent}, "";
            # detect type of current line
            if ($line =~ /^((\*|([aAiI]|\d+)\.) )(.*)$/) {
            # TODO: What about indentataion for lines following ordered items
            #       with digits more than one character, e.g. "17. blahblah"?
                $block->{type} = "listing";
                $block->{marker_indent} = length $1;
                $block->{marker} = $2;
                $line = $4;
                $block->{marker} =~ s/\.$//;
                $block->{marker} =~ s/^\d+$/1/;
                $block->{listtype} = $block->{marker} eq "*" ? "ul" : "ol";
            } elsif ($line =~ /^{{{(.*)$/) {
                $block->{type} = "preformatted";
                $block->{content} = [""];
                $line = $1 ? $1 . "\n" : "";
            } elsif ($line =~ /^-->8--(.*)$/) {
                $block->{type} = "verbatim";
                $block->{content} = [""];
                $line = $1 ? $1 . "\n" : "";
            } elsif ($line =~ /^\|\|[^|].*[^|]\|\|\s*$/) {
                $block->{type} = "table";
            } elsif ($line =~ /^(=+) (.*) =+\s*$/) {
                $block->{type} = "heading" . length $1;
                $line = $2;
            } elsif ($line =~ /^(-{4,})\s*$/) {
                $block->{type} = "rule";
                $block->{thickness} = length $1;
                $line = "";
            } else {
                $block->{type} = "paragraph";
            }
        }
        debug("found $block->{type}($block->{indent}) in $blocks[-1]->{type}($blocks[-1]->{indent}): $line => ");
        my $addtextcontent = sub {
            push @{$blocks[-1]->{content}}, do {
                if ($line eq "") {
                    ""
                } elsif ($line =~ /(.*)\\$/ and not escaped($1)) {
                    $line =~ s/\\$//;
                    $line
                } elsif ($lineoverflow) {
                    $line . " "
                } else {
                    $line, "" # line breaker
                }
            };
        };
        if ($block->{type} ne "table"
                and ($block->{type} eq $blocks[-1]->{type}
                    or $block->{type} eq "paragraph"
                    and $blocks[-1]->{type} eq "listitem")
                and $block->{indent} == $blocks[-1]->{indent}) {
            if ($line eq "" and $blocks[-1]->{type} eq "paragraph") {
                # restart a same block
                debug("end and begin new in $blocks[-1]->{type}($blocks[-1]->{indent})\n");
                pop @blocks;
                push @{$blocks[-1]->{content}}, $block;
                push @blocks, $block;
            } else {
                # continued block
                debug("continued\n");
            }
            $addtextcontent->();
        } else {
            # end previous inner blocks
            while (@blocks > 1 and ($blocks[-1]->{indent} > $block->{indent}
                    or $blocks[-1]->{indent} == $block->{indent}
                    and $blocks[-1]->{type} ne $block->{type})) {
                debug("end $blocks[-1]->{type}\n");
                pop @blocks;
            }
            # begin a new block if necessary
            if ($block->{indent} > $blocks[-1]->{indent}
                    or $block->{type} ne $blocks[-1]->{type}) {
                debug("begin new in $blocks[-1]->{type}($blocks[-1]->{indent})\n");
                push @{$blocks[-1]->{content}}, $block;
                push @blocks, $block;
            }
            # process auto sub-blocks
            if ($block->{type} eq "listing") {
                my $subblock = {
                    type => "listitem",
                    indent => $block->{indent} + $block->{marker_indent},
                    content => [],
                };
                debug("begin new listitem in $blocks[-1]->{type}($blocks[-1]->{indent})\n");
                push @{$blocks[-1]->{content}}, $subblock;
                push @blocks, $subblock;
            }
            if ($blocks[-1]->{type} eq "table") {
                # parse row
                my @cells;
                my @rawcells = split quotemeta "||", $line;
                shift @rawcells;
                # process escaped delimiters
                for (my $i=0; $i<@rawcells; $i++) {
                    if (escaped($rawcells[$i])) {
                        $rawcells[$i] .= "||" . $rawcells[$i+1];
                        splice @rawcells, $i+1, 1;
                        $i--;
                    } else {
                        my $raw = $rawcells[$i];
                        my $attrs;
                        if ($raw =~ /^\s*(<([^>]*)>)?\s*(.*)$/) {
                            $raw = $3;
                            $attrs = parse_attrs($2);
                        }
                        $cells[$i] = {
                            type => "cell",
                            content => [$raw],
                            $attrs && %$attrs
                        }
                    }
                }
                debug("cells: @cells\n");
                # push a row to table
                push @{$blocks[-1]->{content}}, {
                    type => "row",
                    content => \@cells
                };
            } else {
                # append content to current block
                $addtextcontent->() if $line ne "";
            }
            # process immediately ending blocks
            if ($block->{type} =~ /heading\d+|rule/) {
                pop @blocks;
            }
        }
    }
    trimspaces($body);
    parse_alignments($body);
    #intermediate2xml($body)
    join "", map {intermediate2xml($_)} @{$body->{content}}
}

sub parse_alignments {
    my $body = shift;
    my $content = $body->{content};
    my $aligned = 0;
    for my $n (@$content) {
        if (ref $n) {
            parse_alignments($n);
            $aligned = 1;
        } elsif (not $aligned and $body->{type} eq "paragraph") {
            if ($n !~ /^\s*$/) {
                if ($n =~ /^\s*(<<|>>|><)/) {
                    $body->{align} = ($1 eq "<<" ? "left" :
                        $1 eq ">>" ? "right" : "center");
                    $n =~ s/^$&//;
                }
                $aligned = 1;
            }
        }
    }
}


sub trimspaces {
    my $body = shift;
    my $c = $body->{content};
    while (my $n = shift @$c) {
        if ($n ne "") {
            unshift @$c, $n;
            last;
        }
    }
    while (my $n = pop @$c) {
        if ($n ne "") {
            push @$c, $n;
            last;
        }
    }
    $body->{content} = [];
    for my $n (@$c) {
        if (ref $n eq "HASH") {
            trimspaces($n);
            next if $n->{type} eq "paragraph"
                and @{$n->{content}} == 0;
        }
        push @{$body->{content}}, $n;
    }
}

sub intermediate2xml {
    my $node = shift;
    my %options = @_;
    sub dochild {
        my $node = shift;
        attrs($node), map {intermediate2xml($_)} @{$node->{content}}
    }
    if (ref $node eq "") {
        if ($node eq "") {
            $X->br($NameSpace_XHTML)
        } else {
            content2xml($node);
        }
    } elsif ($node->{type} eq "rule") {
        $X->hr($NameSpace_XHTML)
    } elsif (exists $node->{content}) {
        if ($node->{type} eq "paragraph") {
            $X->p($NameSpace_XHTML, dochild($node))
        } elsif ($node->{type} eq "listitem") {
            $X->li($NameSpace_XHTML, dochild($node))
        } elsif ($node->{type} eq "listing") {
            my ($attrs, @childs) = dochild($node);
            my $name = $node->{listtype};
            $attrs->{type} = $node->{marker} ne "*" ? $node->{marker} : undef;
            $X->$name($NameSpace_XHTML, $attrs, @childs)
        } elsif ($node->{type} =~ /heading(\d+)/) {
            my $level = $1 + 1;
            my $name = "h$level";
            $X->$name($NameSpace_XHTML, dochild($node))
        } elsif ($node->{type} eq "preformatted") {
            $X->pre($NameSpace_XHTML, map {preformatted2xml($_)} @{$node->{content}})
        } elsif ($node->{type} eq "verbatim") {
            $X->pre($NameSpace_XHTML, {class=>"verbatim"}, map {verbatim2xml($_)} @{$node->{content}})
        } elsif ($node->{type} eq "table") {
            $X->table($NameSpace_XHTML, map {
                    $X->tr($NameSpace_XHTML, 
                        map {
                            $X->td($NameSpace_XHTML, 
                                dochild($_)
                            )
                        } @{$_->{content}}
                    )
                } @{$node->{content}})
        } elsif ($node->{type} eq "body") {
            $X->body($NameSpace_XHTML, dochild($node))
        } else {
            # TODO clean up
            use Data::Dumper;
            debug(Dumper($node));
        }
    } else {
        undef
    }
}

sub content2xml {
    my $content = shift;
    my %param = @_;
    my @content;
    # find each beginning of special block
    while ($content =~ m#^(.*?)(\*\*|'''?|//|__|,,|\^\^|\`|\{\{\{|\[)#s) {
        # munch the text in the front
        my $prefix = $1;
        my $begin = $2;
        (substr $content, 0, length $&) = "";
        # check escape sequence
        if (escaped($prefix)) {
            push @content, text2xml($prefix . $begin, %param);
        } else {
            push @content, text2xml($prefix, %param);
            my $name;
            # determine the type and terminator
            my $end = $begin;
            if ($begin eq "**" or $begin eq "'''") {
                $name = "strong";
            } elsif ($begin eq "''" or $begin eq "//") {
                $name = "em";
            } elsif ($begin eq "__") {
                $name = "u";
            } elsif ($begin eq ",,") {
                $name = "sub";
            } elsif ($begin eq "^^") {
                $name = "sup";
            } elsif ($begin eq "`") {
                $name = "tt";
            } elsif ($begin eq "{{{") {
                $name = "tt";
                $end = "}}}";
            } elsif ($begin eq "[") {
                $name = "ref";
                $end = "]";
            }
            my $block;
            my $buffer = "";
            # handle escape sequences and nested blocks
            # while finding the end of this block
            my $pbegin = quotemeta $begin;
            my $pend = quotemeta $end;
            my $nested = 0 if $begin ne $end;
            while ($content =~ m#^(.*?)$pend#s) {
                # munch block
                my $inner = $1;
                $buffer .= $inner;
                (substr $content, 0, length $&) = "";
                # check escape sequence
                if (escaped($inner)) {
                    $buffer .= $end;
                } else {
                    if (defined $nested) {
                        # count nested blocks
                        while ($inner =~ m#^(.*)$pbegin#gs) {
                            $nested++ if not escaped($1);
                        }
debug(">>> nested:", $nested, ";", $buffer, "\n");
                    }
                    if (not defined $nested or $nested == 0) {
                        $block = $buffer;
                        last;
                    } else {
                        $buffer .= $end;
                        $nested--;
                    }
                }
            }
            if (not defined $block) {
                # treat block beginner as ordinary text if no terminator exists
                push @content, text2xml($begin, %param);
                # restore munched stuff
                (substr $content, 0, 0) = $buffer;
debug(">XXX", $name, ":", $content, "\n");
            } else {
debug("><<<", $name, ":", $block, "\n");
                # handle nested special blocks recursively
                push @content, ($name eq "ref" ? reference2xml($block, %param) :
                    $X->$name($NameSpace_XHTML, content2xml($block, %param)));
            }
        }
    }
    push @content, text2xml($content, %param);
    @content
}

sub reference2xml {
    my $ref = shift;
    my %param = @_;
    my $name;
    my @content;
    my $attrs = {};
    my $ns;
    if ($ref =~ /^=(\S+)\s*(.*)?$/s) {
        $ns = $NameSpace_XInclude;
        $attrs->{href} = normal2attr($1);
        $name = "include";
        foreach (split /\s+/, $2) {
            $attrs->{$1} = $2 if /(\w+)="([^"]*)"/;
        }
        $attrs->{parse} = "xml" if not defined $attrs->{parse};
        $attrs->{parse} = "text" if $attrs->{parse} !~ /^(text|xml)$/;
        delete $attrs->{xpointer} if $attrs->{parse} eq "text"
            and defined $attrs->{xpointer};
    } else {
        $ns = $NameSpace_XHTML;
        if ($ref =~ /^#(\S+)\s*(.*)$/s) {
            $attrs->{id} = normal2attr($1);
            $ref = $2;
        }
        if ($ref =~ /^%(\S+)\s*(<([^>]*)>\s*)?(.*)$/s) {
            $name = "img";
            $attrs->{src} = normal2attr($1);
            $attrs->{alt} = normal2attr($4);
            $attrs->{title} = $attrs->{alt};
            extend_with($attrs, parse_attrs($3));
        } else {
            $name = "a";
            $ref =~ /^(\S+)\s*(.*)$/s;
            $attrs->{href} = normal2attr($1);
            @content = content2xml($2 || $1, inside_ref => 1);
        }
    }
    $X->$name($ns, $attrs, @content)
}

sub preformatted2xml {
    my $text = shift;
#    $text =~ s/\\(\\|}}})/$1/g;
    text2xml($text)
}

sub text2xml {
    my $text = shift;
    my %param = @_;
    my @content;
    if (not $param{inside_ref}) {
        # detect url and email addresses
        while ($text =~ m#^(.*?)((?<![\[|"])(http|ftp)://
            (\[[0-9a-f:]+\]|[-0-9a-z_\.]+)(:\d+)?
            [-\w/\.~\#\?=&\+%\*@!^\$,:;\[\]\{\}\|'"`]+
            |[-\w\.]+@(\[[0-9a-f:]+\]|[-0-9a-z_\.]+))#six) {
            push @content, normal2xml($1);
            (substr $text, 0, length $&) = "";
            my $url = normal2xml($2);
            push @content, $X->a($NameSpace_XHTML, {href=>($url =~
                        /^[-\w\.]+@(\[[0-9a-f:]+\]|[-0-9a-z_\.]+)$/i
                        ? "mailto:" : "") . $url}, $url);
        }
    }
    push @content, normal2xml($text);
    @content
}

sub normal2xml { escapeXML(unescape(@_)) }

sub normal2attr {
    my $text = escapeXML(unescape(@_));
    $text =~ s#"#&quot;#gs;
    $text
}

sub verbatim2xml {
    my $text = shift;
#    $text =~ s/\\(\\|-->8--)/$1/g;
    escapeXML($text)
}

sub escapeCDATA {
    # handle XML CDATA tokens
    my $text = shift;
    $text =~ s#]]>#]]&gt;#gs;
    utf8::decode($text);
    '<![CDATA[' . $text . ']]>'
}

sub escapeXML {
    # handle XML tokens
    my $text = shift;
    $text =~ s#&#&amp;#gs;
    $text =~ s#<#&lt;#gs;
    $text =~ s#>#&gt;#gs;
    utf8::decode($text);
    $text
}

sub escaped { $_[0] =~ m#(\\+)$# and (length $1) % 2 == 1 }

sub unescape {
    # decode our escape sequences
    my $text = shift;
    $text =~ s#\\(.)#$1#sg;
    $text
}

sub parse_attrs {
    my $a = shift;
    $a = unescape($a);
    my $attrs = {};
    if ($a =~ /style="(.*?)"/) {
        $attrs->{style} = $1;
        $a =~ s/$&//;
    }
    $attrs->{rowspan} = $1 if $a =~ /\|(\d+)/i;
    $attrs->{colspan} = $1 if $a =~ /-(\d+)/i;
    my $style = {};
    $style->{'width'} = "$&"
    if $a =~ /(100|[1-9][0-9]|[0-9])%/;
    $style->{'text-align'} = "left" if $a =~ /\(/;
    $style->{'text-align'} = "right" if $a =~ /\)/;
    $style->{'text-align'} = "center" if $a =~ /:/;
    $style->{'vertical-align'} = "bottom" if $a =~ /v/;
    $style->{'vertical-align'} = "top" if $a =~ /\^/;
    $style->{'vertical-align'} = "middle" if $a =~ /=/;
    $style->{'background-color'} = lc $&
    if $a =~ /#[a-fA-F0-9]{6}/;
    $attrs->{style} .= $_ . ":" . $style->{$_} . ";" foreach keys %$style;
    $attrs
}

sub attrs {
    my $node = shift;
    if (ref $node ne "") {
        my $style = normal2xml($node->{style});
        $style .= $node->{align} ? "text-align:$node->{align}; " : "";
        {
            rowspan => normal2xml($node->{rowspan}),
            colspan => normal2xml($node->{colspan}),
            $style && (style => $style),
        }
    }
}

sub extend_with {
    my $base = shift;
    my $extension = shift;
    $base->{$_} = $extension->{$_} foreach keys %$extension;
}

sub debug {
#    print STDERR @_;
}

sub time2iso {
    my $t = shift;
    return undef unless defined $t;
    $t = strftime('%Y-%m-%dT%H:%M:%S%z', localtime $t);
    $t =~ s/^(.*)([+-])(\d{2})(\d{2})$/$1$2$3:$4/;
    $t = "$1Z" if $3 eq "00" and "$4" eq "00";
    $t
}

#print Bood::fh2xml(\*STDIN);
1;
