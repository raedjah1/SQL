# Clarity Database Query Guide

This folder contains individual queries to help you understand the Clarity database. Each query is focused on one specific aspect and includes plain-English explanations.

## Quick Reference - When to Use Each Query

| Query File | Use When You Need To... | Example Situation |
|------------|-------------------------|-------------------|
| `01_relationships_and_keys.sql` | Understand how tables connect | "If I delete this customer, what else breaks?" |
| `02_primary_and_unique_keys.sql` | Find unique identifiers for records | "How do I update just this one specific order?" |
| `03_table_sizes_and_volumes.sql` | See which tables are biggest/most important | "Why is my database slow?" |
| `04_datetime_patterns.sql` | Find when things happened | "Show me orders from last month that were updated this week" |
| `05_business_logic_fields.sql` | Understand what the business does | "Find all premium customers with unpaid orders" |
| `06_id_patterns.sql` | Figure out how to join tables | "How do I connect customer data to their orders?" |
| `07_naming_conventions.sql` | Find tables when you don't know exact names | "What tables handle invoicing?" |

## Recommended Order for New Databases

If you're exploring Clarity for the first time, run the queries in this order:

1. **Start with `03_table_sizes_and_volumes.sql`** - See what's big and important
2. **Then `01_relationships_and_keys.sql`** - Understand how things connect
3. **Then `05_business_logic_fields.sql`** - Learn what the business does
4. **Then `06_id_patterns.sql`** - See how to join data together
5. **Finally the others as needed** for specific tasks

## Tips for Success

- **Read the plain-English explanation** at the top of each file before running it
- **Start simple** - run one query at a time and understand the results
- **Look for patterns** - the results often reveal the "personality" of your database
- **Take notes** - write down interesting findings for future reference

## Common Patterns You'll Discover

After running these queries, you'll typically find:
- **Core business tables** (customers, orders, products) that are large and well-connected
- **Lookup tables** (statuses, types) that are small but referenced everywhere  
- **Audit patterns** (created_date, updated_date columns everywhere)
- **Naming conventions** that help you guess what other tables might exist

Happy exploring! 🔍
