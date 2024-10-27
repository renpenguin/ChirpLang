
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

        var sin_num = math:sin(num)
        print(f"sin({ num }) = { sin_num }")
    }
}
```

Lua uses a garbage collector for memory management. A garbage collector is typically a process run by a language interpreter or runtime that automatically finds memory that is no longer used and deallocates it. While this means that a user of the language never has to deal with memory, such an automated system is a very dangerous game to play as certain edge cases can result in memory leaks which a user of the language will have no way of fixing, OR memory that is *still* in use being deleted and causing memory failures. The pains of garbage collection plague nearly every scripting language on earth, so for Chirp I want to choose a more robust option:
- manual memory management (we want this language to be beginner friendly!)
- automated memory management based on call stack (and cases where this will not work)
- reference counting (the simplest form of automated memory management)
	- ownership and lifetimes (the holy grail of memory safety, but too much of a pain for a scripting language)

To read code into executable instructions, we first need to convert the string of characters into tokens: keywords, string or number literals, etc. Any possible piece of the code should be encodable as a Token. something like this would be trivially easy with Rust's expansive enum system, and i found that luckily, i could achieve something similar using Odin's unions [SHOW EXAMPLE]. i started by writing an example program in my language, which also gave me the opportunity to make some key decisions about how the syntax should work.

---
## Software development
- Plan and organise the software development 
- Know when and how to record evidence 
- Produce evidence of each stage of development 
- Annotate code 
- Produce evidence of testing at each iteration 
- Produce evidence of failed tests along with how errors were fixed

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
