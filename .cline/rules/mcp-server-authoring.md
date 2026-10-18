---
description: "Use when building an MCP server or tool, or agent capabilities."
---


# MCP server authoring

## A tool description is a prompt, not documentation

The description is how the agent decides to call your tool, and it is the only
part of the definition it sees. This is the same rule as a skill's description,
and the same failure mode applies.

```json
{
  "name": "search_orders",
  "description": "Search orders by customer, status, or date. Use when a user asks to find an order, look up a purchase, or check order status.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "customerId": { "type": "string", "description": "Customer to filter by" },
      "status":    { "type": "string", "enum": ["pending","paid","shipped","cancelled"] },
      "from":      { "type": "string", "description": "ISO date, inclusive lower bound" }
    },
    "required": []
  }
}
```

Note what it does and does not say. It names the **situation** ("a user asks to
find an order"). It does not describe the algorithm, because a description that
spells out the procedure becomes a shortcut the agent takes instead of reading
your server's instructions.

**Two tools whose descriptions overlap will be confused with each other.** One
tool per action, with descriptions that clearly exclude each other:

```
Good:  "Create a new order. Not for modifying an existing order."
Bad:   "Create or update an order."
```

Name tools after the operation, not the resource: `search_orders`, not
`orders_tool`.

## Schema is a contract with an agent, not a validator

- **Every property needs a `description`.** An agent reads them to build the call.
- **Prefer enums over free-form strings.** `{enum: [...]}` removes a whole class
  of malformed calls.
- **Make the common case need no reasoning.** A required-free schema with a
  filter per dimension works better than one composite parameter.
- **Do not accept a raw string where a structured value works.** Free-form
  expressions handed to a query builder are both an injection risk and a source
  of silently wrong results.

## Errors are results the agent will read

Return a message that says what to do differently. A stack trace is noise the
agent cannot act on, and an empty error teaches it to retry blindly.

```
Error: customerId 'cust_123' not found. Call list_customers to get valid ids.
```

Three rules:

- **Do not swallow the error into a success string.** `"Error: not found"` as a
  successful response means the agent treats it as data.
- **Distinguish retryable from terminal.** A rate limit should say so, or the
  agent will retry a validation failure forever.
- **Never leak a secret, a stack trace, or another customer's data in the
  message.** The error text goes into a model's context.

## Tool results: small, and shaped for reading

Return what the agent needs to act, not what you have. A tool returning 5,000
rows does not return more information; it returns less, because the useful part
is now buried and every token costs.

Paginate, and say so:

```json
{ "results": [...], "nextCursor": "eyJvIjoyMH0", "hasMore": true }
```

Prefer structured content over prose. A model parses JSON reliably and parses
English prose by guessing.

## Security

An MCP server is a privileged integration surface with an agent on the other
side. Treat every argument as untrusted input.

- **Never `eval`, never pass a string to a shell, never interpolate into SQL.**
  Use argument arrays and parameterised queries. See `security-code-review`.
- **Scope every tool to the minimum.** A read tool that can write is not a read
  tool.
- **Keep destructive operations out of reach of a general-purpose tool.**
  Deletion belongs behind explicit confirmation the agent cannot synthesise.
- **Do not let a tool call fetch arbitrary URLs on the agent's behalf.** That is
  a server-side request forgery primitive aimed at your infrastructure.

## Instructions beat tool descriptions for cross-cutting rules

If several tools share a convention, state it once in the server's instructions
rather than repeating it in every description. Use it for what does not belong
in a single tool: authentication expectations, pagination conventions, how to
handle partial failure.

## Resources and prompts

Not everything is a tool.

| Primitive | Use for | Called |
| --- | --- | --- |
| **Tool** | An action, with side effects or a query | The model decides |
| **Resource** | Read-only context the agent may fetch | The model or the application |
| **Prompt** | A task template the user invokes explicitly | The user, not the model |

Putting a read-only lookup in a tool means it competes for the agent's tool
selection budget with actions. If the agent already has enough context, it never
calls it.

## Transport and lifecycle

- **stdio** is the right default for a local subprocess: no ports, no auth, and
  the client owns the lifecycle.
- **HTTP with streamable transport** is for a shared or remote server, and then
  you owe it authentication, rate limiting and timeouts.
- Set timeouts explicitly. A tool with no timeout eventually holds a slot
  forever, and one hung call per request is an outage.

## Test it the way it will be used

Unit tests prove the handler works. They do not prove the tool is *selectable*:

1. **Does the agent call it?** Give a task whose solution requires this tool and
   check the tool was chosen over its neighbours.
2. **Does it call it correctly?** The most common failure is a wrong argument,
   usually a wrong identifier format or a missing required field.
3. **Does it recover?** Hand it an error and check it adapts rather than retrying
   the same call.

The second is the one that catches nearly everything, and the third is the one
that decides whether the tool is safe to leave enabled.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "The description documents the function." | The description routes. The algorithm belongs in the server instructions. |
| "Two tools for one resource is fine." | Overlapping descriptions are chosen between at random. |
| "Return the full result set." | A huge result buries the useful part and costs more context than it returns. |
| "The agent can read the error." | It will retry a generic error, and the error is in its context, not yours. |
| "It is a local tool, no auth needed." | It still executes with your credentials against your data. |
| "Unit tests cover the tool." | They do not test whether the agent selects it or calls it correctly. |
