
---
## Analysis - the problem and its solution
- Be able to describe the problem clearly
- Explain why this is a good problem for a computational solution
- Identify your stakeholders
- Research your problem thoroughly
- Use a range of research methods to collect data including:
	- Product research into similar problems
	- Meetings
	- Surveys
- Describe essential features and limitations of the solution to be developed
- Develop solution requirements for the system
	- Stakeholder requirements
	- Software and hardware requirements
- Develop measurable success criteria for the solution

Programming has never been more accessible thanks to the extensive development of easy-to-learn languages made for beginners. However, many of the languages designed to be "easy to learn" end up being not very easy to use. For example, Python and Lua (both dynamically typed, interpreted languages) are praised for being "great for beginners!", but their dynamic typing means that it's easy to get an erroneous type in a variable without throwing any sort of error (unless the user handles it). This "Manual Error Handling" requires users to themselves constantly check if their variables are of the right type, lest a variable gets an incorrect type and the code fails in a way that makes it *very* difficult to debug.

A lot of modern languages are statically typed, which means that variables have a fixed type and can't be changed to any other type without being re-declared. This way a variable is always guaranteed to have the same type that it started with. Python and Lua avoid static typing for the sake of short-term simplicity at the cost of complete and utter confusion should anything go wrong. In 2024, people learning to program deserve basic quality of life features like this, and shouldn't be treated like they won't understand what a type is.



problem: lua is the absolute worst language ever conceived
stakeholders: people learning to code or looking to integrate a scripting language into their project

---
## Design - the nature of the solution
 - Decompose the problem
 - Explain the structure of the solution
 - Design a solution to each part of the problem
 - Use algorithms in the design of the solution
 - Create suitable user interface designs
 - List usability features for the solution
 - Identify key variables, data structures, classes and validation
 - Develop test plans for each part of the development
 - Justify all decisions in the design process

### Designing the language
We can start by designing the language itself! In the analysis stage I identified my gripes with the Lua programming language, so with the design of my own language I'm going to start by immediately fixing those issues.

Now onto the syntax itself. Scope is defined using braces `{}` like in other languages and variables are explicitly defined and implicitly statically typed. I've also decided that I want f-strings (a feature of Python introduced in 3.6 that makes string formatting trivial) to be a core feature of the language, so I've shown below how this will look. In Chirp, semi-colons will be optional, and new lines of code will indicated by a new-line character. Interestingly, this first iteration of the language design is very reminiscent of Go, which means I'm able to use Go syntax highlighting, for the most part (you can see that f-strings are not correctly highlighted):
```go
import math, random

// If there is no scope body, this function will be called automatically
func main() {
    print("hi!")
    var dice_roll = random:range(1, 6)
    print(f"Dice roll: {dice_roll}")

    var num = 0.0
    forever {
        num += math:constants:pi / (3.0 * 4.0)
        print(f"Repeated { num } times")
        print(f"sin({ num }) = { math:sin(num) }")
    }
}
```

Lua uses a garbage collector for memory management. A garbage collector is typically a process run by a language interpreter or runtime that automatically finds memory that is no longer used and de-allocates it. While this means that a user of the language never has to deal with memory, such an automated system is a very dangerous game to play as certain edge cases can result in memory leaks which a user of the language will have no way of fixing, OR memory that is *still* in use being deleted and causing memory failures. The pains of garbage collection plague nearly every scripting language on earth, so for Chirp I want to choose a more robust option:
- manual memory management (we want this language to be beginner friendly!)
- automated memory management based on call stack (and cases where this will not work)
- reference counting (the simplest form of automated memory management)
	- ownership and lifetimes (the holy grail of memory safety, but too much of a pain for a scripting language)

Manual memory management is used by low level languages such as C, where the developer is expected to allocate and free memory on their own. I want my language to be easy to learn and use, so this is not an option at all. We could simply free all memory when its original creation leaves the scope (which actually is an option!)

To read code into executable instructions, we first need to convert the string of characters into tokens: keywords, string or number literals, etc. Any possible piece of the code should be encodable as a Token. something like this would be trivially easy with Rust's expansive enum system, and i found that luckily, i could achieve something similar using Odin's unions [SHOW EXAMPLE]. i started by writing an example program in my language, which also gave me the opportunity to make some key decisions about how the syntax should work.

---
## Software development
- Plan and organise the software development
- Know when and how to record evidence
- Produce evidence of each stage of development
- Annotate code
- Produce evidence of testing at each iteration
- Produce evidence of failed tests along with how errors were fixed

### Tokenisation/Lexical analysis
I started by implementing a simple function to perform the tokenisation portion of the lexical analysis, which would split an example file i had written into individual tokens and output them as a `TokenStream` (a dynamic array of `Token`s), and a "formatter", which could parse the token stream back into language code, so I could make sure that no important information was being lost during the tokenisation process. This gave me my expected output! Below is shown the manually truncated output of the program at this point.
```go
[.../Project]# odin run src
------------- Loaded tokens:
["import", "math", CommaType{}, "random", NewLineType{count = 2}, "func", "main", Bracket{type = "Round", state = "Opening"}, Bracket{type = "Round", state = "Closing"}, Bracket{type = "Curly", state = "Opening"}, NewLineType{count = 1}, "print", Bracket{type = "Round", state = "Opening"}, "hi!", Bracket{type = "Round", state = "Closing"}, NewLineType{count = 1}, ...]
------------- Parsed text as:
import math, random

func main() {
    print("hi!")
...
```
It first tokenises the file (loaded at compile time with Odin's `#load`) and prints out the generated token stream. Then the token stream is passed to the format function which converts the tokens back into text and outputs a string ready for printing.

Once I had the core tokeniser working I expanded on it by adding support for boolean and float literals, improving the formatter to be able to output well-formatted code even when the original was a complete unindented mess and even allowing newline and apostrophe escape characters to be used within string literals!

### Instruction Parsing/Syntax Analysis
Syntax analysis was by far the most time consuming step of the development process due to the sheer complexity of **expressions**. I created a function which would parse my tokens into a dynamic array of `Statement`s (a Statement is a union representing one line code including any attached lines inside {} brackets, such as an import statement, if clause, loop or `Expression` representing a function/procedure call), known as a `Block`. Each statement can have `Expression`s which are a series of operations and function calls operating variables and literals, with an optional single output value. For example `print(3 + math:sin(math:constants:pi / 3.0))` would be one expression which returns nothing, as `print` outputs nothing.

TODO: need to review everything here after i finish the design part of the doc

At this point I also began to look into memory management, as up until this point I'd not really kept up with what memory I was and wasn't freeing. I didn't have access to a debugger, but thanks to Odin's `TrackingAllocator` I was able to add a snippet to my code which would dump all the addresses that weren't yet freed at the end of the program, along with the function in which they were allocated. An example is shown here:
```
=== 22 allocations not freed: ===
- 3 bytes @ odin-latest/share/core/unicode/utf8/utf8.odin(162:11)
- 5 bytes @ .../Project/src/parser/name.odin(40:26)
- 2 bytes @ odin-latest/share/core/unicode/utf8/utf8.odin(162:11)
- 112 bytes @ .../Project/src/parser/expression.odin(129:14)
- 3 bytes @ .../Project/src/parser/name.odin(40:26)
- 112 bytes @ .../Project/src/parser/expression.odin(130:14)
- 896 bytes @ .../Project/src/parser/expression.odin(102:39)
- 192 bytes @ .../Project/src/parser/statement.odin(164:3)
- 6 bytes @ .../Project/src/parser/name.odin(40:26)
- 5 bytes @ .../Project/src/parser/name.odin(40:26)
- 1536 bytes @ .../Project/src/parser/parser.odin(81:3)
```

Using this I was able to craft procedures which would fully deallocate every part of a parsed `Block`. Shown below is a part of the `destroy_block` procedure. It checks through every instruction in the block and depending on the type of instruction, deletes any parts of it that are stored on the heap.
```go
// Recursively destroy everything stored in the block
destroy_block :: proc(block: Block) {
	for instruction in block {
		switch _ in instruction {
		case ImportStatement:
			import_statement := instruction.(ImportStatement)
			for library in import_statement {
				destroy_name_ref(library) // Delete the library name strings
			}
			delete(import_statement) // Since the statement itself is a dynamic list, it too needs to be deleted
		case VariableDefinition:
			var_def := instruction.(VariableDefinition)
			delete(string(var_def.name)) // Delete the string definining the name of the variable
			destroy_expression(var_def.expr) // A separate procedure which goes through the expression that gets assigned to the value (everything after the `=`)
		case Forever:
			destroy_block(instruction.(Forever).block) // Forever instructions contain a block which can be destroyed recursively
		...
```

### Scope evaluation/Semantic analysis
The next step is to make sure that variables and functions referenced in the scope actually exist! To do this I created the `Scope` struct which can store `Module`s (imported libraries such as `math`, `random` and `time`), `Function`s (either interpreted or externally loaded functions), `Variable`s (as a way to store constants like `pi` in libraries) and optionally, a reference to a "parent scope". Later on at execution, if a function

I then wrote the `build_scope` function, which searches for function definitions and import statements in a block and adds the function or imported modules to a `Scope`, which it then returns. At this stage I would also run a very simple evaluation of the scope, going through each instruction to make sure any referenced variables and functions were available there. If an instruction is a `VariableDefinition` statement, I add a temporary dummy variable with the same name to the block's scope, in case future statements try to access it.

### Execution
Finally I implemented basic code execution! I created a simplified example file to run so that I wouldn't have to worry about as many facets of the language:
```go
var counter = 0

forever {
	counter += 1
	print("We have now counted", counter - 1, "times")
}
```
For this simplified code block I would only need to implement variable storage, retrieval and assignment, and execution of expressions (i.e. the `print` function call and its arguments). At this point even interpreted function calling isn't implemented as the `print` function is built into the language and so doesn't need to worry about scope or type matching.

A bare implementation capable of operating on this simple piece of code ran without any issues! From here I properly implemented calling of imported library functions (mainly using functions I'd already developed during the semantic analysis stage) and all possible operations. For any given operation I first evaluated either side of the operation, then attempted to match their types - if one side was an int and the other was a float, I would convert the int to a float before performing any operations.

---
## Evaluation
 - Produce evidence of post development testing
 - Give evidence of usability testing
 - Cross reference test evidence with success criteria
 - Explain how any criteria that hasn't been met could be met with further development
 - Justify the success of usability features
 - Explain how any unmet usability features could be met with further development
 - Discuss maintenance of the system
 - Describe any improvements that could be made to the program and how any limitations could be overcome with further development

---
## References
any references will go here
https://en.wikipedia.org/wiki/Memory_management
https://doc.rust-lang.org/nomicon/ownership.html
example project: https://www.ocr.org.uk/images/77802-unit-f454-exemplar-candidate-work.pdf
