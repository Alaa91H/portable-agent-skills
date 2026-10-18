---
name: long-form-integrity
description: Use before finishing any long generated answer — a report, a digest, a research write-up. Checks the text for repetition collapse, glued fields, and content that stopped mid-sentence, so a broken answer is never presented as a finished one.
---

# Long-form integrity

A model that runs out of useful output does not fail. It repeats itself: the same
phrase, the same word, the same sentence, until the budget ends. The reader
receives pages of it and concludes the whole system is broken.

## The failure signature

- The same word repeated dozens of times (`wwwwww`, `000000`, `-----`).
- The same short phrase repeated back to back, with or without spaces.
- The same line repeated every line.
- Tool names, file paths, or fragmentary identifiers leaking into prose.
- A sentence that starts and never finishes.

## Check before you answer

1. **Repetition.** Scan the tail of your answer — that is where the loop starts.
   Read the last three lines. If they repeat each other, cut from the first
   repetition onward.
2. **Field separation.** In an Arabic briefing or report, every labelled field
   (`التاريخ:`, `المصدر:`, `ما حدث:`) must be on its own line. Fields separated
   by `·` inside one paragraph are unreadable; split them.
3. **Completion.** The last paragraph must be a conclusion, not a start.
4. **Nothing invented.** Every URL, number, date, and name must come from a
   source you actually read. If you could not open it, say so.

## If the output collapsed

Do not ship the repetition. Deliver:

- The coherent part, cut at the last complete sentence.
- One plain line saying the output broke down mid-answer.
- A note that the complete raw text is available as a file.

That is honest and useful. A clean failure beats a long fake success.

## If you notice the loop mid-generation

Stop generating. Do not try to "push through" a repetition loop — it does not
recover on its own. Write the coherent part, close it properly, and say what
happened.