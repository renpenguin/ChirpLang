# An interpreted programming language

notes: f strings can encoded as the keyword `f` requiring to be followed by a string

problem: lua sucks
stakeholders: people learning to code or looking to integrate a scripting language into their project

the first step is to tokenise EVERYTHING. any possible "chunk" of the code should be encodable as a Token. something like this would be trivially easy with Rust's expansive enum system, and i found that luckily, i could achieve something similar using Odin's unions [SHOW EXAMPLE]. i started by writing an example program in my language, which also gave me the opportunity to make some key decisions about how the syntax should work.
