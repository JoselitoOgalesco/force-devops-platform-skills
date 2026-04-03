# sf-agentforce

Build, configure, and test Agentforce agents on Salesforce.

## Description

This skill provides comprehensive guidance for building production-ready AI agents using Salesforce Agentforce. Covers agent setup, topics, actions (Flow, Apex, PromptTemplate, External Service), Agent Scripts for deterministic FSM-based agents, PromptTemplate authoring, GenAI Models API, metadata structure, agent testing, and observability.

## Features

- **Agent Configuration** — Service Agent vs Employee Agent setup
- **Topics & Actions** — Define conversation routing and executable actions
- **Agent Scripts** — Build deterministic finite-state-machine agents
- **PromptTemplate Authoring** — Create reusable AI prompts with merge fields
- **GenAI Models API** — Call LLMs from Apex code
- **Agent Testing** — Test plans, utterance coverage, action verification
- **Observability** — Event monitoring, logs, KPI dashboards

## Quick Start

1. Enable Agentforce in Setup → Einstein → Agentforce
2. Create an Agent via Setup → Agents → New Agent
3. Define Topics for conversation routing
4. Add Actions (Flows, Apex, APIs) to Topics
5. Deploy and test with Agent Builder Preview

## Usage

Invoke this skill when:
- Building a new Agentforce agent
- Creating Topics and Actions
- Writing PromptTemplates
- Testing agent utterance coverage
- Debugging agent behavior

## Related Skills

- [sf-apex](../sf-apex/) — Apex invocable actions for agents
- [sf-flow](../sf-flow/) — Flow-based agent actions
- [sf-integration](../sf-integration/) — External service actions
- [sf-test](../sf-test/) — Testing agent components
