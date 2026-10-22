Here are the memory banks of SonDeltaOrigins, split into the different banks for the 2024 release, and a newer 2026 development bin which has a piano roll song player.
Presented here for analysis.

It is likely the first many are really a contiguous batch;
and only the later beyond 32mbit 512kb banks are what are switched out
(likely at the memory address 32mbit-512kb; so that last 512Kb is also effectivly a bank with assets not reachable by later 512kb banks)
(though the implementation details will have to be consulted for exact addresses)

One way to handle this is possibly to simply not resolve into labels the memory loading here.
Ex in the program it will right to the bank switcher register a value;
and then the upper 512kbit of memory will then essentially point to this later rom bank.
If a dis-assembler simply didn't "resolve" these types of pointers there would be no issue.
The write to the memory mapper register would occur:
and then the machine code call up of that memory address would occur.

Because disassemblers relabel all these memory accesses under a "resolved" label:
the ASM generated is not what the machine code would intend.

(IE the disassembler decides all mentions of memory address 123456789 are all to be labeled BLABLABLA,
while the truth is the number should be left alone: as a bank switch register ultimatim was given
before the memory address: and it really did mean THAT verbatium number: not a label)
