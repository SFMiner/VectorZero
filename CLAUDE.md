# Claude Reference

## Coding Conventions
- Always update GEMINI.md with the exact changes you make to this file.
- Indent with tabs, not spaces.
- Maintain a README.md file of features, in checklist format, with implemented features checked off.
- Maintain a GEMINI.md file for the agent's purposes in coding, listing anything he AI will need to readily reference about the project, including any recurring syntactical errors (such as proper tertiatry operators), 
- Godot ternary operators use syntax: "value1 if condition else value2"
	- incorrect: "condition ? value1 : value2"	
- Do not use external ids in scene files: just use the paths to the included files. 
- Never use comments in a *.tscn file.
