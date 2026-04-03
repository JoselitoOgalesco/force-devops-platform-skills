# sf-debug

Debug and troubleshoot Salesforce applications effectively.

## Description

This skill helps you diagnose issues from debug logs, governor limit violations, exceptions, and performance bottlenecks. Covers debug log analysis, checkpoint debugging, Apex profiling, trace flag configuration, and systematic troubleshooting workflows.

## Features

- **Debug Log Analysis** — Read and interpret Salesforce debug logs
- **Governor Limit Monitoring** — Identify limit violations and near-misses
- **Checkpoint Debugging** — Set breakpoints in Developer Console
- **Apex Profiler** — CPU time and heap analysis
- **Trace Flag Configuration** — Set logging levels for users/classes
- **Error Diagnosis** — Stack trace interpretation and common error patterns
- **Performance Profiling** — Identify slow queries and bottlenecks

## Quick Start

1. Set up Trace Flag for user/Apex class (Setup → Debug Logs)
2. Reproduce the issue
3. Download and analyze the debug log
4. Search for LIMIT_USAGE, EXCEPTION, or slow operations
5. Fix root cause and verify

## Usage

Invoke this skill when:
- Analyzing debug logs
- Diagnosing governor limit errors
- Troubleshooting deployment failures
- Profiling slow Apex code
- Understanding order of execution issues

## Related Skills

- [sf-apex](../sf-apex/) — Apex code patterns
- [sf-test](../sf-test/) — Testing to prevent bugs
- [sf-soql](../sf-soql/) — Query optimization
- [sf-deploy](../sf-deploy/) — Deployment troubleshooting
