---
name: search-engineering
description: Use when designing an Elasticsearch index or tuning relevance.
---

# Search engineering

## The field limit is what will fail first

The default is **1,000 fields** per index, counting fields, multi-fields, object
mappings and aliases. Dynamic mapping on arbitrary keys hits it, and the failure
arrives as an opaque rejection at index time rather than at write time.

Prevent it in this order:

1. **Explicit mappings.** Never rely on dynamic inference for a shape you own.
2. **`dynamic: strict`**, which rejects anything unexpected rather than inventing
   a field for it.
3. **`dynamic_templates`** that map unknown strings to `keyword` rather than to
   text-plus-keyword, which creates two fields per key.
4. **`flat_object`** for documents whose keys are genuinely arbitrary.

```json
PUT /events
{
  "mappings": {
    "dynamic": "strict",
    "properties": {
      "user":     { "properties": { "id": { "type": "keyword" } } },
      "created":  { "type": "date" },
      "source":   { "type": "keyword" },
      "payload":  { "type": "flattened" }
    }
  }
}
```

Check what you actually have:

```sh
curl -s 'localhost:9200/events/_mapping' | jq '.mappings.properties | keys | length'
curl -s 'localhost:9200/_cat/indices?v&h=index,docs.count,store.size&s=store.size:desc'
```

Recovering from a mapping explosion needs a reindex and an alias swap; changing
the limit on an existing index generally needs a rollover to take effect.

## multi_match type is the highest-leverage decision

| Type | Behaviour | Use for |
| --- | --- | --- |
| `best_fields` | Best field's score wins, others blended by `tie_breaker` | Default, and usually right |
| `most_fields` | Scores summed across fields | Documents where more matched fields is more relevant |
| `cross_fields` | One combined query across fields | Multi-word values split across fields |
| `combined_fields` | Term-centric BM25F scoring | Better than `cross_fields` when available |

`cross_fields` has a requirement that is easy to miss: **it silently matches any
single word** unless you set `minimum_should_match`.

```json
{
  "multi_match": {
    "query": "will smith",
    "type": "cross_fields",
    "fields": ["first_name", "last_name"],
    "minimum_should_match": "50%"
  }
}
```

Without that line, a search for two names matches documents containing either
one, which looks like "results are too broad" and is really a missing parameter.

Boost the fields that matter, since equal weighting across a title and a
paragraph loses every relevant document below the fold:

```json
{ "multi_match": { "query": "...", "fields": ["title^3", "summary^2", "content"] } }
```

## Business signals without rewriting the query

```json
{
  "function_score": {
    "query": { "multi_match": { "query": "...", "fields": ["title^3", "body"] } },
    "functions": [
      { "filter": { "term": { "in_stock": true } }, "weight": 3 },
      { "gauss": { "published": { "origin": "now", "scale": "30d", "decay": 0.5 } } },
      { "field_value_factor": { "field": "views", "modifier": "log1p",
                                "factor": 0.1, "missing": 0 } }
    ],
    "score_mode": "sum",
    "boost_mode": "multiply",
    "max_boost": 10
  }
}
```

Always set `"missing": 0` on `field_value_factor`. Without it, documents lacking
the field produce an error rather than a zero, and the whole query fails.

Debug with the explain endpoint rather than guessing:

```sh
curl -s 'localhost:9200/events/_explain/<id>?pretty' -H 'Content-Type: application/json' -d '{"query":{"match":{"body":"term"}}}'
```

It shows which clauses matched and why, which is the difference between a
five-minute fix and an afternoon.

## Relevance measurement

Tune against a labelled set or you are guessing. Define a small set of queries
with known-good results, measure recall at 10 before and after each change, and
keep the measurement in CI. Without it, every relevance "improvement" is an
opinion that arrives with a query change attached.

## Chunking is a search concern too

For retrieval-augmented generation the chunking strategy drives relevance more
than the embedding model does. The conventional default is 400 to 512 tokens
with 10 to 20 percent overlap, but a systematic analysis found that overlap
provided no measurable benefit while raising indexing cost, in the setup it
tested. Treat the overlap figure as a default to **measure**, not a law.

Two changes have reliable evidence behind them: **hybrid semantic plus keyword
search**, and **cross-encoder reranking** when precision is below about 80
percent.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "Dynamic mapping is fine for now." | It is what reaches the 1,000-field limit, and it fails at index time. |
| "cross_fields works like best_fields." | Without `minimum_should_match` it matches any single word. |
| "We will boost fields later." | Equal weighting buries relevant results below the fold. |
| "field_value_factor is optional." | Without `missing: 0`, documents without the field error the query. |
| "Ten percent overlap is required." | It is a default to measure, not a rule. |
| "Relevance is fine, it is subjective." | Measure recall against a labelled set before and after. |
