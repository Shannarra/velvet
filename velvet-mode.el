(define-generic-mode
		'velvet-mode
	'("#") ; comments
	'("if" "do" "else" "end" "true" "false" "from" "to" "step" "break" "while") ;kwords
	'(
		'("+" "-" "*" "**" "/" "(" ")" "[" "]" "=" "==" "!=" "<" ">" "&&" "||" "print" "puts" . 'font-lock-operator)
		'("print" "puts" . 'font-lock-builtin)
		)
	'("\\.vv$") ; auto mode files

	nil ; other functions to call
	"A Velvet mode for Emacs"	
	)
