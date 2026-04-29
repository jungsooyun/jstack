# CONTEXT.md Format

Use `CONTEXT.md` only when a project has domain language that would otherwise
be redefined inside every spec or plan.

## Template

```md
# {Context Name}

{One or two sentences explaining what this context covers.}

## Language

**Order**:
A customer request for purchasable items.
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent after delivery.
_Avoid_: Bill, payment request

## Relationships

- An **Order** produces one or more **Invoices**
- An **Invoice** belongs to exactly one **Customer**

## Example Dialogue

> **Dev:** "When a **Customer** places an **Order**, do we create the **Invoice** immediately?"
> **Domain expert:** "No. An **Invoice** is generated after fulfillment."

## Flagged Ambiguities

- "account" was used to mean both **Customer** and **User**. Resolved: these are distinct concepts.
```

## Rules

- Create or update this lazily. Do not create domain context for every repo.
- Include project-domain terms only. General programming concepts do not belong.
- Be opinionated: pick one preferred term and list aliases to avoid.
- Keep definitions to one sentence.
- Record relationships and obvious cardinality.
- Flag resolved ambiguity explicitly so future specs do not reopen it.
- For multiple bounded contexts, create a root `CONTEXT-MAP.md` that links to
  each context file and names their relationships.
