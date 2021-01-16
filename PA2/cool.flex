/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Do not remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

bool isBufferFull(char* buf_ptr, char* buf, int size);
void pushToBuffer(char* buf_ptr, char* buf, char c);

/*
 *  Add Your own definitions here
 */

%}

%Start COMMENT STRING_CONSTANT STRING_CONSTANT_ERROR
%option stack

/*
 * Define names for regular expressions here.
 */

CLASS                 (?i:class)
ELSE                  (?i:else)
FI                    (?i:fi)
IF                    (?i:if)
IN                    (?i:in)
INHERITS              (?i:inherits)
LET                   (?i:let)
LOOP                  (?i:loop)
POOL                  (?i:pool)
THEN                  (?i:then)
WHILE                 (?i:while)
CASE                  (?i:case)
ESAC                  (?i:esac)
OF                    (?i:of)
NEW                   (?i:new)
ISVOID                (?i:isvoid)
NOT                   (?i:not)
TRUE                  t(?i:rue)
FALSE                 f(?i:alse)

DIGIT                 [0-9]
NUMBER                {DIGIT}+
ALPHA                 [a-zA-Z]
DARROW                =>
LE                    <=
ASSIGN                <-
OPERATORS             [.@~*\/+\-<=]
SYMBOLS               [{}(),:;]
WHITESPACE            [\t\f\r\v ]
NEWLINE               \n
NULL                  \0

LINE_COMMENT          \-\-[^\n]*
BLOCK_COMMENT         .
BLOCK_COMMENT_START   \(\*
BLOCK_COMMENT_END     \*\)

DOUBLE_QUOTE          \"
STRING_CHAR           [^"]
TYPEID                [A-Z]({ALPHA}|{DIGIT}|_)*
OBJECTID              [a-z]({ALPHA}|{DIGIT}|_)*

ESCAPE                \\
ESCAPED_BACKSLASH     \\\\
CHAR_NEWLINE          \\n
ESCAPED_NEWLINE       \\\n
ESCAPED_TAB           \\t
ESCAPED_FORMFEED      \\f
ESCAPED_BACKSPACE     \\b
ESCAPED_DOUBLE_QUOTE  \\\"
ESCAPED_NULL          \\\0

%%

 /*
  *  Nested comments
  */

<INITIAL>{LINE_COMMENT}                {}
<INITIAL,COMMENT>{BLOCK_COMMENT_START} { yy_push_state(COMMENT); }
<COMMENT>{BLOCK_COMMENT}               {}
<COMMENT>{BLOCK_COMMENT_END}           { yy_pop_state(); }
<INITIAL>{BLOCK_COMMENT_END}           { yylval.error_msg = "Unmatched *)"; return (ERROR); }

 /*
  *  The multiple-character operators.
  */

<INITIAL>{DARROW} { return (DARROW); }
<INITIAL>{LE}     { return (LE); }
<INITIAL>{ASSIGN} { return (ASSIGN); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

<INITIAL>{CLASS}    { return (CLASS); }
<INITIAL>{ELSE}     { return (ELSE); }
<INITIAL>{FI}       { return (FI); }
<INITIAL>{IF}       { return (IF); }
<INITIAL>{IN}       { return (IN); }
<INITIAL>{INHERITS} { return (INHERITS); }
<INITIAL>{LET}      { return (LET); }
<INITIAL>{LOOP}     { return (LOOP); }
<INITIAL>{POOL}     { return (POOL); }
<INITIAL>{THEN}     { return (THEN); }
<INITIAL>{WHILE}    { return (WHILE); }
<INITIAL>{CASE}     { return (CASE); }
<INITIAL>{ESAC}     { return (ESAC); }
<INITIAL>{OF}       { return (OF); }
<INITIAL>{NEW}      { return (NEW); }
<INITIAL>{ISVOID}   { return (ISVOID); }
<INITIAL>{NOT}      { return (NOT); }
<INITIAL>{TRUE}     { cool_yylval.boolean = true; return (BOOL_CONST);}
<INITIAL>{FALSE}    { cool_yylval.boolean = false; return (BOOL_CONST);}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

<INITIAL>{DOUBLE_QUOTE} {
  BEGIN(STRING_CONSTANT);
  string_buf[0] = '\0';
  string_buf_ptr = string_buf;
}
<STRING_CONSTANT>{ESCAPE} {}
<STRING_CONSTANT>{ESCAPED_FORMFEED} {
  if (isBufferFull(string_buf_ptr, string_buf, MAX_STR_CONST - 1)) {
    BEGIN(STRING_CONSTANT_ERROR);
    cool_yylval.error_msg = "String constant too long";
    return (ERROR);
  }
  pushToBuffer(string_buf_ptr, string_buf, '\f');
}
<STRING_CONSTANT>{ESCAPED_BACKSPACE} {
  if (isBufferFull(string_buf_ptr, string_buf, MAX_STR_CONST - 1)) {
    BEGIN(STRING_CONSTANT_ERROR);
    cool_yylval.error_msg = "String constant too long";
    return (ERROR);
  }
  pushToBuffer(string_buf_ptr, string_buf, '\b');
}
<STRING_CONSTANT>{ESCAPED_BACKSLASH} {
  if (isBufferFull(string_buf_ptr, string_buf, MAX_STR_CONST - 1)) {
    BEGIN(STRING_CONSTANT_ERROR);
    cool_yylval.error_msg = "String constant too long";
    return (ERROR);
  }
  pushToBuffer(string_buf_ptr, string_buf, '\\');
}
<STRING_CONSTANT>{ESCAPED_NEWLINE} {
  if (isBufferFull(string_buf_ptr, string_buf, MAX_STR_CONST - 1)) {
    BEGIN(STRING_CONSTANT_ERROR);
    cool_yylval.error_msg = "String constant too long";
    return (ERROR);
  }
  pushToBuffer(string_buf_ptr, string_buf, '\n');
  curr_lineno++;
}
<STRING_CONSTANT>{CHAR_NEWLINE} {
  if (isBufferFull(string_buf_ptr, string_buf, MAX_STR_CONST - 1)) {
    BEGIN(STRING_CONSTANT_ERROR);
    cool_yylval.error_msg = "String constant too long";
    return (ERROR);
  }
  pushToBuffer(string_buf_ptr, string_buf, '\n');
}
<STRING_CONSTANT>{NEWLINE} {
  BEGIN(INITIAL);
  cool_yylval.error_msg = "Unterminated string constant";
  curr_lineno++;
  return (ERROR);
}
<STRING_CONSTANT>{NULL} {
  BEGIN(STRING_CONSTANT_ERROR);
  cool_yylval.error_msg = "String contains null character.";
  return (ERROR);
}
<STRING_CONSTANT>{ESCAPED_NULL} {
  BEGIN(STRING_CONSTANT_ERROR);
  cool_yylval.error_msg = "String contains escaped null character.";
  return (ERROR);
}
<STRING_CONSTANT>{ESCAPED_TAB} {
  if (isBufferFull(string_buf_ptr, string_buf, MAX_STR_CONST - 1)) {
    BEGIN(STRING_CONSTANT_ERROR);
    cool_yylval.error_msg = "String constant too long";
    return (ERROR);
  }
  pushToBuffer(string_buf_ptr, string_buf, '\t');
}
<STRING_CONSTANT>{ESCAPED_DOUBLE_QUOTE} {
  if (isBufferFull(string_buf_ptr, string_buf, MAX_STR_CONST - 1)) {
    BEGIN(STRING_CONSTANT_ERROR);
    cool_yylval.error_msg = "String constant too long";
    return (ERROR);
  }
  pushToBuffer(string_buf_ptr, string_buf, '"');
}
<STRING_CONSTANT>{STRING_CHAR} {
  if (isBufferFull(string_buf_ptr, string_buf, MAX_STR_CONST - 1)) {
    BEGIN(STRING_CONSTANT_ERROR);
    cool_yylval.error_msg = "String constant too long";
    return (ERROR);
  }
  pushToBuffer(string_buf_ptr, string_buf, *yytext);
}
<STRING_CONSTANT>{DOUBLE_QUOTE} {
  BEGIN(INITIAL);
  *string_buf_ptr = '\0';
  cool_yylval.symbol = stringtable.add_string(string_buf);
  return (STR_CONST);
}
<STRING_CONSTANT_ERROR>{DOUBLE_QUOTE}|{NEWLINE} { BEGIN(INITIAL); }
<STRING_CONSTANT_ERROR>{STRING_CHAR}            {}
<INITIAL>{NUMBER}                               { cool_yylval.symbol = inttable.add_string(yytext); return (INT_CONST);}
<INITIAL>{OPERATORS}                            { return *yytext; }
<INITIAL>{SYMBOLS}                              { return *yytext; }
<INITIAL>{TYPEID}                               { cool_yylval.symbol = idtable.add_string(yytext); return (TYPEID);}
<INITIAL>{OBJECTID}                             { cool_yylval.symbol = idtable.add_string(yytext); return (OBJECTID);}
<INITIAL>{WHITESPACE}                           {}
<INITIAL,COMMENT>{NEWLINE}                      { curr_lineno++; }
<STRING_CONSTANT><<EOF>>                        { BEGIN(INITIAL); cool_yylval.error_msg = "EOF in string constant"; return (ERROR); }
<COMMENT><<EOF>>                                { BEGIN(INITIAL); cool_yylval.error_msg = "EOF in comment"; return (ERROR); }
.                                               { cool_yylval.error_msg = yytext; return (ERROR); }

%%

void pushToBuffer(char* buf_ptr, char* buf, char c) {
  *string_buf_ptr = c;
  string_buf_ptr++;
}

bool isBufferFull(char* buf_ptr, char* buf, int size) {
  return buf_ptr >= buf + size;
}
