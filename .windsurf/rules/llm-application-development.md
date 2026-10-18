---
trigger: model_decision
description: "Use when building on language models: retrieval, prompts, evaluation, or tool calling."
---


# LLM application development

## Start from the evaluation, not the prompt

A prompt change with no evaluation is a guess with better odds than before. Build
the measurement first:

- A **golden set** of 30 to 100 realistic inputs with known-good outputs, held
  separately from anything you tune against.
- **Split it**: tune on one part, report on the other. Selecting on the same data
  you iterated against produces a prompt that fits your examples.
- Record the baseline before the first change, so "it improved" means something.
- Measure cost and latency alongside quality. A prompt that is 3% better and 4x
  the tokens is not automatically better.

Model output is non-deterministic, so run each case several times and look at the
variance. A 3% difference inside the noise band is not an improvement.

## Retrieval is where most RAG systems actually fail

Chunking strategy drives answer quality more than the embedding model does.

- **Chunk by structure**, not by a fixed token count. A heading, a function, a
  table, or a conversation turn is a semantic boundary. A chunk that splits a
  definition from its subject retrieves half the answer.
- **Keep chunks small enough to fit the answer budget with the surrounding
  context**, and give each chunk an overlap so a definition split across the
  boundary is still retrievable.
- **Attach metadata** for filtering: tenant, permission, version, date. Filter
  **before** retrieval, not after, or the model sees documents the user may not
  read.
- Measure retrieval separately from generation. If retrieval missed the right
  document, no prompt will fix it, and blaming the prompt wastes days.

Two errors dominate and have opposite fixes:

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Answers confidently wrong | Right document retrieved, not used | Context ordering, instructions, fewer distractors |
| Answers vaguely | Right document never retrieved | Chunking, embeddings, query expansion, hybrid search |

## Prompt and context design

- **Put the instruction before the long content** and the required output format
  at the very end, immediately before generation. Recency matters.
- **Give a worked example** for anything with a required output shape. One good
  example outperforms a paragraph describing the shape.
- **Ask for a specific format** and validate it programmatically. A model asked
  for JSON that returns prose needs a parser fallback, not a wish.
- **Constrain the output space** where you can: tool calling, a grammar, or a
  structured output mode beats free text plus a regex.
- **Do not put secrets or untrusted content into the system prompt** and expect
  the model to enforce it. Treat model output as untrusted input, and validate
  before executing.

## Tool calling and agents

- **Prefer a deterministic loop to free autonomy.** A fixed sequence of tool
  calls with explicit steps is cheaper, faster and easier to debug than an agent
  deciding what to do.
- Give each tool a **narrow description and a narrow schema**. Overlapping tool
  descriptions are the main cause of an agent choosing the wrong one.
- Make tools **idempotent** where you can, because retries are unavoidable.
- **Bound the loop**: a maximum step count, a token budget, and a deadline. An
  unbounded agent loop is an unbounded bill.
- Log every tool call with its arguments and result during development. When an
  agent does the wrong thing, that log is the only evidence.

## Cost is a design constraint

```
cost = input_tokens x input_rate + output_tokens x output_rate
```

- Output tokens are usually the expensive half, and they scale with verbosity
  instructions. Ask for brevity explicitly when you do not need reasoning shown.
- Put long reference material in a retrieval step rather than in every prompt.
- Cache anything deterministic, and cache the system prompt when the provider
  supports it.
- Track tokens per request as a metric with an alert. A regression that doubles
  prompt length is invisible until the invoice arrives.

## Grounding and hallucination

- **Require citation of a retrieved passage for factual claims**, and verify the
  citation actually supports the claim. A citation that resolves to unrelated
  text is worse than no citation.
- **Give the model the option to abstain.** "If the documents do not answer this,
  say so" measurably reduces confident invention.
- For anything consequential, verify the output programmatically against a rule
  rather than trusting it. A model that must emit a valid order id should have
  that checked, not read.

## Know the failure modes you have chosen

| Property | What it actually requires |
| --- | --- |
| Determinism | Not available from the model; enforce at the application layer |
| Reproducibility | Record model version, temperature, seed, and the full prompt |
| Privacy | Data leaves your boundary; check the provider's terms and region |
| Non-regression | The golden set is the only thing that makes "better" measurable |

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "Let me tune the prompt and see." | Without a golden set you cannot tell tuning from noise. |
| "Retrieval is fine, the model ignores it." | Check whether the document was retrieved. Usually it was not. |
| "The agent will figure out the steps." | A deterministic loop is cheaper, faster and debuggable. |
| "Cost is a later concern." | Prompt length regressions are invisible until the bill. Track it now. |
| "Citations prove it is grounded." | Verify the citation supports the claim, not merely that it exists. |
