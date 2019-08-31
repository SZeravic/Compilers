/*
 *  Edditor: Windows OS (Notepad++)
 */

/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
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

char str_buf[MAX_STR_CONST]; /* to assemble string constants */
char *str_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 *
 *  Asignee: Stipe Zeravica
 *  Nothing above this comment was changed except line:38-40
 *
 *  Note: In hopes of not ending up with similar code as someone else gonna try and comment certain
 *  things so it can be clearly understood.
 */

int comment_line_counter = 0; /* Initializing int value for comment line counting whenever we come across new line */

%}

/*
 *  This part we define regular expresions and under what circumstances are they called.
 *  Regular expresions defined:
 */
SPACES                      " "|"\b"|"\f"|"\t"|"\r"|"\v"
NEWLINE                     "\n"
INTEGERS                    [0-9]
INTEGERS_                   [0-9_]
UPPERCASECHARS              [A-Z]
LOWERCASECHARS              [a-z]
ALPHANUMERICS               ({UPPERCASECHARS}|{LOWERCASECHARS})*({INTEGERS_})*
CHARACTERS_SPECIAL_VALID    "+"|"-"|"*"|"/"|"~"|"<"|"="|"("|")"|"{"|"}"|"."|","|":"|";"|"@"
CHARACTERS_SPECIAL_INVALID  ">"|"#"|"%"|"$"|"^"|"&"|"_"|"!"|"?"|"`"|"["|"]"|"\\"|"|"

TYPE                        {UPPERCASECHARS}{ALPHANUMERICS}*
OBJECT                      {LOWERCASECHARS}{ALPHANUMERICS}*

/* Comment Definitions */
%x COMMENT_STATE
COMMENT_START  	            "(*"
COMMENT_END 	            "*)"
COMMENT_SINGLE	            "--".*
COMMENT_SINGLENEWLINE	    "--".*\n

/* String Definitions */
%x STRING_STATE
STRING_START                "\""
STRING_NULL_TERM            "\0"

STRING_NEWLINE              "\\n"
STRING_TAB                  "\\t"
STRING_FEED                 "\\f"
STRING_BOUNDRY              "\\b"

/* ERROR Definitions */
%x ERROR_STATE

%%

 /*
  *  Order of functioanlity handling:
  *  1. Multiple-character operators
  *  2. Comment recognition
  *  3. String regognition
  *  4. Error handling
  */

 /* Ignoring Spaces and empty spaces */
{SPACES}+ {
  /* Eat up empty space and do nothing */
}
{NEWLINE} {
  /* Increase the counter integer which counts lines of code so it can be reported back when something happends */
	curr_lineno++;
}
 
 /*
  *  1. Multiple-character operators
  */
 
{INTEGERS}+ {
	cool_yylval.symbol = inttable.add_string(yytext);    /* */
	return (INT_CONST);
}

"<="    { return LE;     }
"=>"    { return DARROW; }
"<-"    { return ASSIGN; }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  * "?" Symbol handles case sensitivity
  */

{CHARACTERS_SPECIAL_VALID} {
  /* Return any dettected valid special characters as tokens */
	return (yytext[0]);
}

{CHARACTERS_SPECIAL_INVALID} {
  /* Report error in case any non-valid special caracter is parsed */
	cool_yylval.error_msg = yytext;
	return (ERROR);
}

 /* "?i: - Characters can be ether uppercase or lowercaswe in this case first letter has to be lowercase */
t(?i:rue) {
	cool_yylval.boolean = true;
	return BOOL_CONST;
}

f(?i:alse) {
	cool_yylval.boolean = false;
	return BOOL_CONST;
}

(?i:while)      return WHILE;
(?i:if)         return IF;
(?i:else)       return ELSE;
(?i:then)       return THEN;
(?i:case)       return CASE;
(?i:loop)       return LOOP;
(?i:not)        return NOT;
(?i:new)        return NEW;
(?i:in)         return IN;
(?i:fi)         return FI;
(?i:of)         return OF;
(?i:let)        return LET;
(?i:pool)       return POOL;
(?i:esac)       return ESAC;
(?i:class)      return CLASS;
(?i:isvoid)     return ISVOID;
(?i:inherits)   return INHERITS;

{TYPE} {
	cool_yylval.symbol = idtable.add_string(yytext);
	return TYPEID;
}

{OBJECT} {
	cool_yylval.symbol = idtable.add_string(yytext);
	return OBJECTID;
}	

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
  
  /*
  *  2. Comment recognition and nesting handling
  */

{COMMENT_SINGLE}+ {
  /* Incremeanting linenumber not needed since we know comment will end on the same line */
}
{COMMENT_SINGLENEWLINE} {
  /* In case we dettect new line after the line commend ends */
	curr_lineno++;
}

{COMMENT_END} {
  /* If we no comment start chars were not dettected report an error */
	cool_yylval.error_msg = "Comment start character *) not dettected";
	return (ERROR);
}

{COMMENT_START} {
  /* Once comment start character is dettected enter comment state */
	comment_line_counter++;
	BEGIN(COMMENT_STATE);               /* Enter Comment "STATE" */
}

<COMMENT_STATE>{SPACES}+|. {
  /* In case current state is Comment state an if any space or any other charcters have been detectted do eat them up and do nothing */
}

<COMMENT_STATE>\n {
  /* In case new line is dettected increase the current line counter */
	curr_lineno++;
}

<COMMENT_STATE>{COMMENT_START} {
  /* If already in Comment state check for more comment blocks (Nested comments) */
	comment_line_counter++;
}

<COMMENT_STATE>{COMMENT_END} {
	comment_line_counter--;
	if(comment_line_counter == 0) {
		BEGIN(INITIAL);         /* If all comment blocks have been closed return to normal STATE */
	}
	/* Otherwise continue closing nested comments) */
}

<COMMENT_STATE><<EOF>> {
  /* In case we're in Comment state and we reach end of file without closing the comment block report an Error */
	BEGIN(INITIAL);
	if(comment_line_counter > 0) {
		comment_line_counter = 0;
		cool_yylval.error_msg = "Reached EOF (End of File) while in comment block";
		return (ERROR);
	}
}

 /*
  *  3. String regognition
  */
  
{STRING_START} {
  /* Once String start character is dettected enter comment state */
	BEGIN(STRING_STATE);
	str_buf_ptr = str_buf; /* str_buf defined at the begining of the file */
}

<STRING_STATE>{STRING_START} {
  /* Check if string lenght is over the limit if it is set the null terminator character and report an error */
	if((str_buf_ptr - str_buf) >= MAX_STR_CONST) {
		*str_buf = '\0';
		cool_yylval.error_msg = "String lenght limit exceeded";
		BEGIN(INITIAL);   /* Returning to normal state */
		return (ERROR);
	}
  /* If char limit hasn't been exeeded end it with null termintaror */
	*str_buf_ptr = '\0';
	cool_yylval.symbol = stringtable.add_string(str_buf);
	BEGIN(INITIAL);
	return STR_CONST;
}

<STRING_STATE><<EOF>> {
  /* If end of file has been reached while in a String state report an ERROR */
	cool_yylval.error_msg = "Reached EOF (End of File) while in a string block";
	BEGIN(INITIAL);
	return (ERROR);
}

<STRING_STATE>{STRING_NULL_TERM} {
  /* Detected null terminator char before string block was closed */
	cool_yylval.error_msg = "Null character dettected in string";
	BEGIN(ERROR_STATE);
	return (ERROR);
}

<STRING_STATE>\\\0 {
  /* Multiple null nerminated strings are possible - converting to normal char and reporting an ERROR */
	cool_yylval.error_msg = "Null character dettected in string";
	str_buf[0] = '\0';
	BEGIN(ERROR_STATE);
	return (ERROR);
}

<STRING_STATE>{NEWLINE} {
  /* New line dettected before String block was closed and in sence won't have null terminating string */
	curr_lineno++;
	BEGIN(INITIAL);
	cool_yylval.error_msg = "Unterminated string constant";
	return (ERROR);
}

 /* Transforming split characters into one from multiple characters inside of string buffer */
<STRING_STATE>{STRING_NEWLINE}        { *str_buf_ptr++ = '\n';      }
<STRING_STATE>{STRING_TAB}            { *str_buf_ptr++ = '\t';      }
<STRING_STATE>{STRING_FEED}           { *str_buf_ptr++ = '\f';      }
<STRING_STATE>{STRING_BOUNDRY}        { *str_buf_ptr++ = '\b';      }
<STRING_STATE>"\\"[^\0]               { *str_buf_ptr++ = yytext[1]; }
<STRING_STATE>.                       { *str_buf_ptr++ = *yytext;   }

  /*
  *  4. ERROR Handling - Recovering
  */

<ERROR_STATE>{STRING_START} {
	BEGIN(INITIAL);
}

<ERROR_STATE>{STRING_NEWLINE} {
	curr_lineno++;
	BEGIN(INITIAL);
}

<ERROR_STATE>{NEWLINE} {
	curr_lineno++;
	BEGIN(INITIAL);
}

<ERROR_STATE>. {
  /* Eat up any character until we leave error state */
}

. {
	/* Nothing Matched - In case anything else gets dettected after all rules report an error */
	cool_yylval.error_msg = yytext;
	return ERROR;
}
%%