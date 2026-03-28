# sf-data

Load, extract, and transform Salesforce data safely.

## Description

This skill provides guidance for data operations in Salesforce including bulk data loading, data extraction, upsert operations, and data transformation. Covers Data Loader, SFDX data commands, Bulk API best practices, and data migration strategies.

## Features

- **Data Loading** — Insert, update, upsert, delete operations
- **Bulk API** — Handle large data volumes efficiently
- **Data Extraction** — Export data with SOQL queries
- **External IDs** — Upsert patterns for data synchronization
- **Data Transformation** — ETL patterns and field mappings
- **Error Handling** — Batch error recovery strategies

## Quick Start

1. Identify data volume (Bulk API for >10K records)
2. Map source fields to Salesforce fields
3. Set up External IDs for upserts
4. Test in sandbox before production
5. Monitor batch job status

## Usage

Invoke this skill when:
- Loading data into Salesforce
- Extracting data for analysis
- Migrating data between orgs
- Setting up data synchronization

## Related Skills

- [sf-soql](../sf-soql/) — Query construction
- [sf-schema](../sf-schema/) — Object and field structure
- [sf-deploy](../sf-deploy/) — Deployment strategies
