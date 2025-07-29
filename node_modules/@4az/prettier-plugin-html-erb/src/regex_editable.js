import { regex } from "regex";

export default regex`
  (?<node>
    # Expression
    <%=
      (?<startDelimiterEx>\g<DELIMITER>?)
        \s*(?<expression> (?>\g<ESCAPEQUOTES> | \g<ALLSYMBOLS>)*?)\s*
      (?<endDelimiterEx>\g<DELIMITER>?) %>
    | 
    # Comment
    <%\#\s*(?<comment>\g<EVERYTHING>)\s* %>
    |
    # Statement
    <% (?<startDelimiter>\g<DELIMITER>?)
      \s*(?<statement> (?<keyword>\g<KEYWORD>?) (?>\g<ESCAPEQUOTES> | \g<ALLSYMBOLS>)*?)\s* 
      (?<endDelimiter>\g<DELIMITER>?) %>
  )

  (?(DEFINE)
    (?<EVERYTHING>		\g<ALLSYMBOLS>*?)
    (?<ALLSYMBOLS>    [\s\S])
    (?<ESCAPEQUOTES>	'[^']*'|"[^"]*")
    (?<DELIMITER>	    [\-=])
    (?<KEYWORD>       if|else|elsif|unless|case|when|end)
  )
`;
