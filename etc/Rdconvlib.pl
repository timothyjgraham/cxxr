# Subroutines for converting R documentation into HTML, LaTeX and
# nroff format  

# Copyright (C) 1997 Friedrich Leisch
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
# 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details. 
# 
# A copy of the GNU General Public License is available via WWW at
# http://www.gnu.org/copyleft/gpl.html.  You can also obtain it by
# writing to the Free Software Foundation, Inc., 675 Mass Ave,
# Cambridge, MA 02139, USA.

# Send any bug reports to Friedrich.Leisch@ci.tuwien.ac.at

$VERSION = "0.1.5";

# names of unique text blocks, these may NOT appear MORE THAN ONCE! 
@blocknames = ("name", "title", "usage", "arguments", "description", 
	       "value", "references", "seealso", "examples", "author", "note");
# These may appear multiply but are of simple structure:
@multiblocknames = ("alias", "keyword");


$NB = "normal_bracket";
$BN = "bracket_normal";
$EOB = "escaped_opening_bracket";
$ECB = "escaped_closing_bracket";
$ID = "$NB\\d+$BN";
$ECODE = "this_is_escaped_code";
$LATEX_SPECIAL = '\$\^%&~_\{\}#\\\\';

sub Rdconv {

    open rdfile, "<$_[0]";

    $type = $_[1];
    $debug = $_[2];
    
    $max_bracket = 0;
    $max_section = 0;
    
    undef $complete_text;
    undef %blocks;
    undef @section_body;
    undef @section_title;
    

    #-- remove comments (everything after a %)
    while(<rdfile>){
	while(s/^\\%|([^\\])\\%/$1escaped_percent_sign/go){};
	s/^([^%]*)%.*$/$1/o;
	s/escaped_percent_sign/\\%/go;
	$complete_text = "$complete_text$_";
    }


    mark_brackets();
    escape_codes();

    if($type) {
	#-- These may be used in all cases :
	@aliases = get_multi($complete_text,"alias");
	@keywords= get_multi($complete_text,"keyword");
    }

    rdoc2html()  if $type =~ /html/i;
    rdoc2nroff() if $type =~ /nroff/i;
    rdoc2latex() if $type =~ /tex/i;
    rdoc2ex()    if $type =~ /example/i;
}    


# Mark each matching opening and closing bracket with a unique id.
# Idea and original code from latex2html
sub mark_brackets {
	
    $complete_text =~ s/^\\{|([^\\])\\{/$1$EOB/gso;
    $complete_text =~ s/^\\}|([^\\])\\}/$1$ECB/gso;
    
    while($complete_text =~ /{([^{}]*)}/s){
	my $id = $NB . ++$max_bracket . $BN;
	$complete_text =~ s/{([^{}]*)}/$id$1$id/s;
    }
}

sub unmark_brackets {
    my $text = $_[0];

    while($text =~ /($ID)(.*)($ID)/s){
	$id = $1;
	if($text =~ s/$id(.*)$id/\{$1\}/s){
	    $text =~ s/$id(.*)$id/\{$1\}/so;
	}
	else{
	    return $text;
	}
    }

    $text =~ s/$EOB/\{/gso;
    $text =~ s/$ECB/\}/gso;
    $text;
}

sub escape_codes {
    while($complete_text =~ /\\code/){
	my ($id, $arg)  = get_arguments("code", $complete_text, 1);
	$complete_text =~ s/\\code$id(.*)$id/$ECODE$id/s;
	$ecodes{$id} = $1;
    }
}

    
# Write documentation blocks such as title, usage, etc. into the
# global hash array %blocks
sub get_blocks {
    
    my $text = $_[0];

    my $id="";
    print stderr "--- Blocks\n" if $debug;
    foreach $block (@blocknames){
	if($text =~ /\\($block)($ID)/){
	    ($id, $blocks{$block}) = get_arguments($block, $text, 1);
	    print stderr "found: $block\n" if $debug;
	    if((($block =~ /usage/) || ($block =~ /examples/))){
		$blocks{$block} =~ s/^[ \t]+$//; #- multiple empty lines to one
		$blocks{$block} =~ s/\n\n\n/\n\n/gom;
	    } else {
		$blocks{$block} =~ s/^\s*(\S)/$1/;
		$blocks{$block} =~ s/\n[ \t]*(\S)/\n$1/g;
	    }
	}	    
    }
    print stderr "---\n" if $debug;
}

# Get  ALL  multiblock things -- their simple arg. is put in array:
#
sub get_multi {
   
    my $text = $_[0];
    my $name = $_[1]; # "alias" or "keyword"
    my @res, $k=0;
    print stderr "--- Multi: $name\n" if $debug;
    while($text =~ /\\$name($ID)/) {
	my $id = $1;
	my ($endid, $arg) = 
	    get_arguments($name, $text, 1);
	print stderr "found:" if $debug && $k==0;
	print stderr " $k:$arg" if $debug;
	$arg =~ s/^\s*(\S)/$1/;
	$arg =~ s/\n[ \t]*(\S)/\n$1/g;
	$res[$k++] = $arg;
	$text =~ s/\\$name//s;
    }
    print stderr "\n---\n" if $debug;
    @res;
}

# Write the user defined sections into the 
# global hashs @section_body and @section_title
sub get_sections {
    
    my $text = $_[0];

    print stderr "--- Sections\n" if $debug;
    while($text =~ /\\section($ID)/){
	my $id = $1;
	my ($endid, $section, $body)
	    = get_arguments("section", $text, 2);
	print stderr "found: $section\n" if $debug;
	$body =~ s/^\s*(\S)/$1/;
	$body =~ s/\n[ \t]*(\S)/\n$1/g;
	$section_body[$max_section] = $body;
	$section_title[$max_section++] = $section;
	$text =~ s/\\section//s;
    }
    print stderr "---\n" if $debug;
}
	

# Get the arguments of a command.
# Arguments of get_arguments:
#  1: next occurence of $_[0] is searched
#  2: $_[1] is the text containing the command
#  3: $_[2] is the optional number of arguments to be extracted,
#     default is to extract 1 argument 
# Returns a list with the id of the last closing bracket and
# the arguments. 
sub get_arguments {
    
    my $command = $_[0];
    my $text = $_[1];
    my $nargs = $_[2];
    my @retval;
    
    if($text =~ /\\($command)($ID)/){
	$id = $2;
	$text =~ /$id(.*)$id/s;
	$retval[1] = $1;
	my $k=2;
	while(($k<=$nargs) && ($text =~ /$id($ID)/)){
	    $id = $1;
	    $text =~ /$id\s*(.*)$id/s;
	    $retval[$k++] = $1;
	}
    }
    $retval[0] = $id;
    @retval;
}

# Print a short vector of strings  (utility).
sub print_vec {
    my($F, $nam, $do_nam, $sep, $end) = @_;    
    my($i)=0;
    $sep = ', '  unless $sep;
    $end = ".\n" unless $end;
    print $F "\@$nam = " if $do_nam;
    foreach (@$nam) { print $F ($i>0 ? $sep : '') . "'$_'"; $i++ }
    print $F $end;
}

	    
	
# Print the hash %blocks ... for debugging only (I just insert this
# function manually at places where I need it :-) 
sub print_blocks {

    while(($block,$text) = each %blocks) {

	print "\n\n********** $block **********\n\n";
	print $text;
    }
    print "\n";
}



sub usage {

    print "Rdconv version $VERSION\n";
    print "Usage: Rdconv [--debug/-d] [--help/-h]";
    print " [--type/-t html|nroff|latex|examp] file\n\n";

    exit 0;
}


sub undefined_command {

    my $text = $_[0];
    my $cmd = $_[1];
    
    while($text =~ /\\$cmd/){
	my ($id, $arg)  = get_arguments($cmd, $text, 1);
	$text =~ s/\\$cmd$id(.*)$id/$1/s;
    }

    $text;
}
    

sub replace_command {

    my $text = $_[0];
    my $cmd = $_[1];
    my $before = $_[2];
    my $after = $_[3];

    while($text =~ /\\$cmd/){
	my ($id, $arg)  = get_arguments($cmd, $text, 1);
	$text =~ s/\\$cmd$id(.*)$id/$before$1$after/s;
    }

    $text;
}



#************************** HTML ********************************

sub rdoc2html {

    get_blocks($complete_text);
    get_sections($complete_text);

    print htmlout "<HTML><HEAD><title>";
    print htmlout $blocks{"title"};
    print htmlout "</title></HEAD><BODY>\n";

    print htmlout "[ <A HREF=\"../../../html/index.html\">top</A>";
    print htmlout " | <A HREF=\"00Index.html\">up</A> ]\n";
    
    print htmlout "<H2 align=center><I>";
    print htmlout $blocks{"title"};
    print htmlout "</I></H2>\n";

    html_print_codeblock("usage", "Usage");
    html_print_argblock("arguments", "Arguments");
    html_print_block("description", "Description");
    html_print_argblock("value", "Value");

    html_print_sections();

    html_print_block("note", "Note");
    html_print_block("author", "Author(s)");
    html_print_block("references", "References");
    html_print_block("seealso", "See Also");
    html_print_codeblock("examples", "Examples");
        
    print htmlout "</BODY></HTML>\n";
}


# Convert a Rdoc text string to HTML, i.e., convert \lang to <tt> etc.
sub text2html {

    my $text = $_[0];

    $text =~ s/&/&amp;/go;
    $text =~ s/>/&gt;/go;
    $text =~ s/</&lt;/go;
    $text =~ s/\\le/&lt;=/go;
    $text =~ s/\\ge/&gt;=/go;
    $text =~ s/\\%/%/go;
    
    $text =~ s/\n\s*\n/\n<P>\n/sgo;
    $text =~ s/\\dots/.../go;
    $text =~ s/\\ldots/.../go;
    $text =~ s/\\cr/<BR>/sgo;

    $text =~ s/\\Gamma/&Gamma/go;
    $text =~ s/\\alpha/&alpha/go;
    $text =~ s/\\Alpha/&Alpha/go;
    $text =~ s/\\pi/&pi/go;
    $text =~ s/\\mu/&mu/go;
    $text =~ s/\\sigma/&sigma/go;
    $text =~ s/\\lambda/&lambda/go;
    $text =~ s/\\beta/&beta/go;
    $text =~ s/\\epsilon/&epsilon/go;
    $text =~ s/\\left\(/\(/go;
    $text =~ s/\\right\)/\)/go;
    $text =~ s/$EOB/\{/go;
    $text =~ s/$ECB/\}/go;
			
    $text = replace_command($text, "emph", "<EM>", "</EM>");
    $text = replace_command($text, "bold", "<B>", "</B>");
    $text = replace_command($text, "file", "`", "'");
    
    while($text =~ /\\link/){
	my ($id, $arg)  = get_arguments("link", $text, 1);
	$htmlfile = $htmlindex{$arg};
	if($htmlfile){
	    $text =~ s/\\link$id.*$id/<A HREF=\"$htmlfile\">$arg<\/A>/s;
	}
	else{
	    $text =~ s/\\link$id.*$id/$arg/s;
	}
    }

    while($text =~ /\\email/){
	my ($id, $arg)  = get_arguments("email", $text, 1);
	$text =~ s/\\email$id.*$id/<A HREF=\"mailto:$arg\">$arg<\/A>/s;
    }

    while($text =~ /\\url/){
	my ($id, $arg)  = get_arguments("url", $text, 1);
	$text =~ s/\\url.*$id/<A HREF=\"$arg\">$arg<\/A>/s;
    }

    # handle equations:
    while($text =~ /\\eqn/){
	my ($id, $eqn, $ascii) = get_arguments("eqn", $text, 2);
	$eqn = $ascii if $ascii;
	$text =~ s/\\eqn(.*)$id/<I>$eqn<\/I>/s;
    }

    while($text =~ /\\deqn/){
	my ($id, $eqn, $ascii) = get_arguments("deqn", $text, 2);
	$eqn = $ascii if $ascii;
	$text =~ s/\\deqn(.*)$id/<P align=center><I>$eqn<\/I><\/P>/s;
    }

    $text =~ s/\\\\/\\/go;
    $text = html_unescape_codes($text);
    unmark_brackets($text);
}

sub code2html {

    my $text = $_[0];

    $text =~ s/&/&amp;/go;
    $text =~ s/>/&gt;/go;
    $text =~ s/</&lt;/go;
    $text =~ s/\\%/%/go;
    $text =~ s/\\ldots/.../go;
    $text =~ s/\\dots/.../go;

			
    while($text =~ /\\link/){
	my ($id, $arg)  = get_arguments("link", $text, 1);
	$htmlfile = $htmlindex{$arg};
	if($htmlfile){
	    $text =~ s/\\link$id.*$id/<A HREF=\"$htmlfile\">$arg<\/A>/s;
	}
	else{
	    $text =~ s/\\link$id.*$id/$arg/s;
	}
    }

    $text =~ s/\\\\/\\/go;
    unmark_brackets($text);
}

# Print a standard block
sub html_print_block {
    
    my $block = $_[0];
    my $title = $_[1];

    if(defined $blocks{$block}){
	print htmlout "<H3><I>$title</I></H3>\n";
	print htmlout text2html($blocks{$block});
    }
}

# Print a code block (preformatted)
sub html_print_codeblock {
    
    my $block = $_[0];
    my $title = $_[1];

    if(defined $blocks{$block}){
	print htmlout "<H3><I>$title</I></H3>\n<PRE>";
	print htmlout code2html($blocks{$block});
	print htmlout "</PRE>";
    }
}


# Print the value or arguments block
sub html_print_argblock {

    my $block = $_[0];
    my $title = $_[1];
    
    if(defined $blocks{$block}){
	print htmlout "<H3><I>$title</I></H3>\n";

	my $text = $blocks{$block};

	if($text =~ /\\item/s){
	    $text =~ /^(.*)(\\item.*)*/s;
	    my ($begin, $rest) = split(/\\item/, $text, 2);
	    if($begin){
		print htmlout text2html($begin);
		$text =~ s/^$begin//s;
	    }
	    print htmlout "<TABLE>\n";
	    while($text =~ /\\item/s){
		my ($id, $arg, $desc)  = get_arguments("item", $text, 2);
		print htmlout "<TR VALIGN=TOP><TD><CODE>";
		print htmlout text2html($arg);
		print htmlout "</CODE>\n<TD>\n";
		print htmlout text2html($desc), "\n";
		$text =~ s/.*$id//s;
	    }
	    print htmlout "</TABLE>\n";
	    print htmlout text2html($text);
	}
	else{
	    print htmlout text2html($text);
	}
    }
}

# Print sections
sub html_print_sections {

    my $section;

    for($section=0; $section<$max_section; $section++){
	print htmlout "<H3><I>" . $section_title[$section] . "</I></H3>\n";
	print htmlout text2html($section_body[$section]);
    }
}


sub html_unescape_codes {

    my $text = $_[0];
    while($text =~ /$ECODE($ID)/){
	my $id = $1;
	my $ec = code2html($ecodes{$id});
	$text =~ s/$ECODE$id/<CODE>$ec<\/CODE>/;
    }
    $text;
}


#**************************** nroff ******************************



sub rdoc2nroff {

    get_blocks($complete_text);
    get_sections($complete_text);

    $INDENT = "0.5i";
    $TAGOFF = "1i";
    
    print ".ND\n";
    print ".pl 100i\n";
    print ".po 3\n";
    print ".na\n";
    print ".SH\n";
    print $blocks{"title"}, "\n";
    
    nroff_print_codeblock("usage", "");
    nroff_print_argblock("arguments", "Arguments");
    nroff_print_block("description", "Description");
    nroff_print_argblock("value", "Value");

    nroff_print_sections();

    nroff_print_block("note", "Note");
    nroff_print_block("author", "Author(s)");
    nroff_print_block("references", "References");
    nroff_print_block("seealso", "See Also");
    nroff_print_codeblock("examples", "Examples");
}


# Convert a Rdoc text string to nroff
sub text2nroff {

    my $text = $_[0];

    $text =~ s/^\.|([\n\(])\./$1\\\&./g;
     
    $text =~ s/\n\s*\n/\n.IP \"\" $INDENT\n/sgo;
    $text =~ s/\\dots/\\&.../go;
    $text =~ s/\\ldots/\\&.../go;
    $text =~ s/\\cr\n?/\n/sgo;
    $text =~ s/\\le/<=/go;
    $text =~ s/\\ge/>=/go;
    $text =~ s/\\%/%/sgo;
    $text =~ s/\\\$/\$/sgo;


    $text =~ s/\\Gamma/Gamma/go;
    $text =~ s/\\alpha/alpha/go;
    $text =~ s/\\Alpha/Alpha/go;
    $text =~ s/\\pi/pi/go;
    $text =~ s/\\mu/mu/go;
    $text =~ s/\\sigma/sigma/go;
    $text =~ s/\\lambda/lambda/go;
    $text =~ s/\\beta/beta/go;
    $text =~ s/\\epsilon/epsilon/go;
    $text =~ s/\\left\(/\(/go;
    $text =~ s/\\right\)/\)/go;
    $text =~ s/$EOB/\{/go;
    $text =~ s/$ECB/\}/go;

    $text = undefined_command($text, "link");
    $text = undefined_command($text, "emph");
    $text = undefined_command($text, "bold");    
    $text = undefined_command($text, "textbf");
    $text = undefined_command($text, "mathbf");
    $text = undefined_command($text, "email");
    $text = replace_command($text, "file", "`", "'");
    $text = replace_command($text, "url", "<URL: ", ">");

    # handle equations:
    while($text =~ /\\eqn/){
	my ($id, $eqn, $ascii) = get_arguments("eqn", $text, 2);
	$eqn = $ascii if $ascii;
	$text =~ s/\\eqn(.*)$id/$eqn/s;
    }

    while($text =~ /\\deqn/){
	my ($id, $eqn, $ascii) = get_arguments("deqn", $text, 2);
	$eqn = $ascii if $ascii;
	$text =~ s/\\deqn(.*)$id/\n.DS B\n$eqn\n.DE\n/s;
    }

    $text = nroff_unescape_codes($text);
    unmark_brackets($text);
}

sub code2nroff {

    my $text = $_[0];

    $text =~ s/^\.|([\n\(])\./$1\\&./g;
    $text =~ s/\\%/%/go;
    $text =~ s/\\ldots/.../go;
    $text =~ s/\\dots/.../go;
    $text =~ s/\\n/\\\\n/g;
     

    $text = undefined_command($text, "link");

    unmark_brackets($text);
}

# Print a standard block
sub nroff_print_block {
    
    my $block = $_[0];
    my $title = $_[1];

    if(defined $blocks{$block}){
	print "\n";
	print ".SH\n";
	print "$title:\n";
#	print ".LP\n";
#	print ".in +$INDENT\n";
	print ".IP \"\" $INDENT\n";
	print text2nroff($blocks{$block}), "\n";
	print ".in -$INDENT\n";
    }
}

# Print a code block (preformatted)
sub nroff_print_codeblock {
    
    my $block = $_[0];
    my $title = $_[1];

    if(defined $blocks{$block}){
	print "\n";
	print ".SH\n" if $title;
	print "$title:\n" if $title;
	print ".LP\n";
	print ".nf\n";
	print ".in +$INDENT\n";
	print code2nroff($blocks{$block}), "\n";
	print ".in -$INDENT\n";
	print ".fi\n";
    }
}


# Print the value or arguments block
sub nroff_print_argblock {

    my $block = $_[0];
    my $title = $_[1];
    
    if(defined $blocks{$block}){

	print "\n";
	print ".SH\n" if $title;
	print "$title:\n" if $title;
#	print ".LP\n";
#	print ".in +$INDENT\n";
	print ".IP \"\" $INDENT\n";

	my $text = $blocks{$block};

	if($text =~ /\\item/s){
	    $text =~ /^(.*)(\\item.*)*/s;
	    my ($begin, $rest) = split(/\\item/, $text, 2);
	    if($begin){
		print text2nroff($begin);
		$text =~ s/^$begin//s;
	    }
	    while($text =~ /\\item/s){
		my ($id, $arg, $desc)  = get_arguments("item", $text, 2);
		$arg = text2nroff($arg);
		$desc = text2nroff($desc);
		print "\n";
		print ".LP\n";
		print ".in +$TAGOFF\n";
		print ".ti -\\w\@$arg:\\ \@u\n";
		print "$arg:\\ $desc\n";
		print ".in -$TAGOFF\n";
		$text =~ s/.*$id//s;
	    }
	    print text2nroff($text), "\n";
	}
	else{
	    print text2nroff($text), "\n";
	}
#	print ".in -$INDENT\n";
    }
}

# Print sections
sub nroff_print_sections {

    my $section;

    for($section=0; $section<$max_section; $section++){
	print "\n";
	print ".SH\n";
	print $section_title[$section], ":\n";
#	print ".LP\n";
#	print ".in +$INDENT\n";
	print ".IP \"\" $INDENT\n";
	print text2nroff($section_body[$section]), "\n";
#	print ".in -$INDENT\n";
    }
}


sub nroff_unescape_codes {

    my $text = $_[0];
    while($text =~ /$ECODE($ID)/){
	my $id = $1;
	my $ec = code2nroff($ecodes{$id});
	$text =~ s/$ECODE$id/\`$ec\'/;
    }
    $text;
}


#*********************** Example ***********************************


sub rdoc2ex {

    get_blocks($complete_text);

    ##--- Here, I should also put everything which belongs to 
    ##--- ./massage-Examples ---- depending on 'name' !!!

    print "###--- >>> `"; print $blocks{"name"};
    print "' <<<----- "; print $blocks{"title"};
    print "\n\n";
    if(@aliases) {
	foreach (@aliases) {
	    print "\t## alias\t help($_)\n";
	}
	print "\n";
    }

    ex_print_exampleblock("examples", "Examples");
    
    if(@keywords) {
	print "## Keywords: ";
	&print_vec(STDOUT, 'keywords');
    }
    print "\n\n";
}

sub ex_print_exampleblock {
    
    my $block = $_[0];
    my $env = $_[1];

    if(defined $blocks{$block}){
	print "##___ Examples ___:\n";
	print  code2examp($blocks{$block});
	print "\n";
    }
}

sub code2examp {
    #-  currently identical to   `code2latex'.
    my $text = $_[0];

    $text =~ s/\\%/%/go;
    $text =~ s/\\ldots/.../go;
    $text =~ s/\\dots/.../go;

    $text = undefined_command($text, "link");
    unmark_brackets($text);
}
    




#*********************** LaTeX ***********************************


sub rdoc2latex {

    get_blocks($complete_text);
    get_sections($complete_text);

    print "\\Header\{";
    print $blocks{"name"};
    print "\}\{";
    print $blocks{"title"};
    print "\}\n";

    latex_print_codeblock("usage", "Usage");
    latex_print_argblock("arguments", "Arguments");
    latex_print_block("description", "Description");
    latex_print_argblock("value", "Value");

    latex_print_sections();

    latex_print_block("note", "Note");
    latex_print_block("author", "Author");
    latex_print_block("references", "References");
    latex_print_block("seealso", "SeeAlso");
    latex_print_exampleblock("examples", "Examples");
    
    print "\n";

}

sub text2latex {

    my $text = $_[0];
    
    $text =~ s/$EOB/\\\{/go;
    $text =~ s/$ECB/\\\}/go;
    
    while($text =~ /\\eqn/){
	my ($id, $eqn, $ascii) = get_arguments("eqn", $text, 2);
	$text =~ s/\\eqn.*$id/\\eeeeqn\{$eqn\}\{$ascii\}/s;
    }
    
    while($text =~ /\\deqn/){
	my ($id, $eqn, $ascii) = get_arguments("deqn", $text, 2);
	$text =~ s/\\deqn.*$id/\\dddeqn\{$eqn\}\{$ascii\}/s;
    }

    $text =~ s/\\eeeeqn/\\eqn/go;
    $text =~ s/\\dddeqn/\\deqn/og;

	
    $text =~ s/\\\\/\\bsl{}/go;
    $text =~ s/\\cr/\\\\/go;
    $text = latex_unescape_codes($text);
    unmark_brackets($text);
}
    
sub code2latex {

    my $text = $_[0];

    $text =~ s/\\%/%/go;
    $text =~ s/\\ldots/.../go;
    $text =~ s/\\dots/.../go;

    $text =~ s/\\\\/\\bsl{}/go;
    $text = undefined_command($text, "link");
    unmark_brackets($text);
}
    


sub latex_print_block {
    
    my $block = $_[0];
    my $env = $_[1];

    if(defined $blocks{$block}){
	print "\\begin\{$env\}\n";
	print text2latex($blocks{$block});
	print "\\end\{$env\}\n";
    }
}

sub latex_print_codeblock {
    
    my $block = $_[0];
    my $env = $_[1];

    if(defined $blocks{$block}){
	print "\\begin\{$env\}\n";
	print "\\begin\{verbatim\}";
	print code2latex($blocks{$block});
	print "\\end\{verbatim\}\n";
	print "\\end\{$env\}\n";
    }
}

sub latex_print_exampleblock {
    
    my $block = $_[0];
    my $env = $_[1];

    if(defined $blocks{$block}){
	print "\\begin\{$env\}\n";
	print "\\begin\{ExampleCode\}";
	print code2latex($blocks{$block});
	print "\\end\{ExampleCode\}\n";
	print "\\end\{$env\}\n";
    }
}

sub latex_print_argblock {

    my $block = $_[0];
    my $env = $_[1];
    
    if(defined $blocks{$block}){

 	print "\\begin\{$env\}\n";

	my $text = $blocks{$block};

	if($text =~ /\\item/s){
	    $text =~ /^(.*)(\\item.*)*/s;
	    my ($begin, $rest) = split(/\\item/, $text, 2);
	    if($begin){
		print text2latex($begin);
		$text =~ s/^$begin//s;
	    }
	    print "\\begin\{ldescription\}\n";
	    while($text =~ /\\item/s){
		my ($id, $arg, $desc)  = get_arguments("item", $text, 2);
		print "\\item\[";
		print latex_code_cmd(code2latex($arg));
		print "\] ";
		print text2latex($desc), "\n";
		$text =~ s/.*$id//s;
	    }
	    print "\\end\{ldescription\}\n";
	    print text2latex($text);
	}
	else{
	    print text2latex($text);
	}
 	print "\\end\{$env\}\n";
    }
}

sub latex_print_sections {
    
    my $section;
    
    for($section=0; $section<$max_section; $section++){
	print "\\begin\{Section\}\{" . $section_title[$section] . "\}\n";
	print text2latex($section_body[$section]);
	print "\\end\{Section\}\n";
    }
}

sub latex_unescape_codes {

    my $text = $_[0];
    while($text =~ /$ECODE($ID)/){
	my $id = $1;
	my $ec = latex_code_cmd(code2latex($ecodes{$id}));
	$text =~ s/$ECODE$id/$ec/;
    }
    $text;
}

# Encapsulate code in \verb or \textt depending on the appearance of
# special characters.
sub latex_code_cmd {

    my $code = $_[0];
    
    if($code =~ /[$LATEX_SPECIAL]/){
	if($code =~ /@/){
	    die("\nERROR: found `\@' in \\code{...\}\n");
	}
	$code = "\\verb@" . $code . "@";
    }
    else {
	$code = "\\texttt\{" . $code . "\}";
    }
    
    $code;
}
