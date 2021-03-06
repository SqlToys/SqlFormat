# SQL Formatter
This is a small free program written with Delphi, which is able to format sql queries with several options. Started somewhere in 2010, now ready to show up but still requires a lot of work.

## Features
* many colors to highlight keywords, identifiers, numbers, strings, tables, columns, functions, parameters, etc.
* many colors to highlight bracket pairs
* many case settings for keywords, tables, columns, aliases, parameters and functions
* many intendation for expressions lists, joins, conditions etc.
* flip join conditions to have joined table always on left side of condition
* command line tools: sqlformat, sql2xmltree, xmltree2sql

## Parser
* This tool uses my own sql parser which consumed some hundreds hours of hard work. 
* Works pretty well for my personal needs, parses complex queries with several sub-queries or some hundreds of unions
* Doesn't cover any sql dialect fully at current development stage, only most used statements and clauses
* Parser outputs to syntax tree, which can be stored as XML file
* Option to load XML file with syntax tree to list and format to a SQL script
* Test unit with almost 850 queries I've made to work through years
* Test method: parse query to a tree, list that tree to text, then compare source and result text with uppercase and wo. white spaces

## Things to do 
### General ideas
* format of script selected part or even selected part of single query
* inscript tags with used format options, required to apply same formatting rules to edited queries
* keep comments, now they are removed while formatting
* general parser rework to support BNF grammar definitions (biggest task)
### Soon 
* parsing of functional blocks (functions, procedures and triggers)
* many internal structure improvements to simple and clarify their usage
  * lister should be minimial <B>40% DONE</B>
    * only top clauses, expressions and joins at new line
    * clauses justified to left
    * clause body intented with the length of longest clause
  * other format options should be realized as parse tree modifications (even query compact) -- <B>60% DONE</B>
### Nice to have
* some query converters ie. old joins to ansi joins, in conditions with subqueries to joins, single column fetching joins to subqueries etc. 
* converters between dialects (ie. ORALCE to MS SQL)
* query analizer to check queries against some known problems that may occur during their lifetime ie. column subquery returns more that single value per row, possible row multiplications with JOINS, possible NULL values inside IN condition (for ORACLE), maybe checks for possible table mutations (?) etc.
* Delphi parser, to track 'code to DB' points of contact and manage possible affects of DB structure changes.
