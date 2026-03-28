---
name: sf-agentforce
description: |
  Build, configure, and test Agentforce agents on Salesforce. Covers agent setup,
  topics, actions (Flow, Apex, PromptTemplate, External Service), Agent Scripts
  for deterministic FSM-based agents, PromptTemplate authoring, GenAI Models API,
  metadata structure, agent testing, and observability.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "1.0.0"
  tags: salesforce, agentforce, ai, agents, topics, actions, prompt-template
---

# Agentforce Development Guide

This guide helps you build production-ready autonomous and deterministic agents following Salesforce best practices. Requires API version 66.0+ for Agentforce features and an Agentforce license.

## What is Agentforce?

Agentforce lets you build AI agents that can:
- **Understand natural language** from customers or employees
- **Route conversations** to the right topic automatically
- **Execute actions** (Flows, Apex, API calls) to complete tasks
- **Generate text** (summaries, emails, recommendations)
- **Escalate to humans** when needed

**For Junior Developers:** Think of an agent as a smart assistant that can understand what users want and perform actions on their behalf, like checking order status or creating cases.

## Agent Types

| Agent Type | API Name | Use Case | Runs As |
|------------|----------|----------|---------|
| Service Agent | `AgentforceServiceAgent` | Customer-facing (chat, SMS) | Dedicated Agent User |
| Employee Agent | `AgentforceEmployeeAgent` | Internal-facing (Slack, embedded in apps) | Logged-in User |

### Agent User Configuration (Service Agents Only)

Service Agents need a dedicated **Einstein Agent User** because:
- They handle customer conversations (no logged-in user context)
- They need consistent permissions regardless of who's chatting
- They enable audit trails of agent actions

**Setup steps:**
1. Create a user with the `Salesforce Integration` license
2. Assign the `AgentforceServiceAgent` permission set
3. Grant object/field permissions the agent needs via additional permission sets
4. Set as `default_agent_user` in agent configuration

**💡 Junior Developer Tip:** If your agent fails to execute actions with permission errors, check the Agent User's permission sets first!

### Channel Configuration

Agents can be deployed to:
- **Messaging channels** (web chat, SMS, WhatsApp)
- **Embedded Service deployments** (Lightning Web Runtime)
- **Slack** (Employee Agent)
- **API** (Agent Runtime API for programmatic access)

Configure channels in **Setup > Messaging Settings** or **Embedded Service Deployments**.

## Topics

Topics define the scope of what an agent can handle. Think of topics as "conversation categories" — each topic is a distinct domain with its own instructions and actions.

### Why Topics Matter

Without clear topics:
- The agent might give order info when asked about returns
- Actions might fire in the wrong context
- Users get confusing or wrong responses

### Topic Design Principles

| Principle | Why It's Important | Example |
|-----------|-------------------|---------|
| **Specific scope** | Clear boundaries prevent confusion | "Order Status" vs "Order Cancellation" are separate |
| **Natural language description** | Drives routing — planner uses it to match utterances | "Helps customers check the status of existing orders" |
| **Focused instructions** | Tells agent how to behave | "Always ask for order number before looking up" |
| **Bounded actions** | Only relevant actions available | Order Status topic has LookupOrder, not CreateOrder |

### Topic Structure

A topic consists of:
- **Label and API Name**: Human-readable name and developer reference
- **Description**: Natural language explanation (this drives routing) — **the most important field!**
- **Scope**: Define in-scope and out-of-scope explicitly
- **Instructions**: Step-by-step guidance within this topic
- **Actions**: Tools available when this topic is active

### Topic Routing

The planner matches user utterances to topics based on:
1. **Topic description similarity** to the utterance (most important!)
2. **Scope definitions** (in-scope vs out-of-scope)
3. **Instruction context**

**Avoid scope overlap** between sibling topics. If two topics could match the same utterance, the planner may misroute. Use explicit scope boundaries:

```text
Topic: Order Status
In scope: Order status inquiries, order tracking, delivery estimates
Out of scope: Order creation, order cancellation (handled by Order Management topic)

Topic: Order Management
In scope: Creating new orders, canceling orders, modifying orders
Out of scope: Checking order status (handled by Order Status topic)
```

### Common Topic Design Mistakes

| Mistake | Why It's Bad | Fix |
|---------|-------------|-----|
| Overlapping descriptions | Agent routes randomly | Make descriptions distinct |
| Too many topics (15+) | Routing becomes unreliable | Consolidate to 7-10 max |
| Vague instructions | Agent behaves inconsistently | Be specific, include examples |
| Missing out-of-scope | Agent tries to handle everything | Explicitly list what's NOT handled |

## Agent Actions

Actions are the tools an agent can invoke. Each action wraps a target implementation (Flow, Apex, PromptTemplate, or External Service).

### Action Types

| Action Type | Target | Best For | When to Use |
|-------------|--------|----------|-------------|
| Flow Action | Screen/Autolaunched Flow | Declarative logic, guided interactions | Most cases — safest and most maintainable |
| Apex Action | `@InvocableMethod` class | Complex logic, callouts, calculations | When Flow can't do it |
| PromptTemplate Action | PromptTemplate metadata | Generated text, summaries, recommendations | When output is AI-generated text |
| External Service Action | External Service registration | Third-party APIs via OpenAPI | Calling external systems |

### When to Use Each

**Flow (Default Choice):**
- ✅ Most maintainable — admins can modify without code
- ✅ Safest — built-in error handling
- ✅ Supports guided user interaction (Screen Flows)
- Use for: CRUD operations, simple logic, user-facing prompts

**Apex:**
- ✅ Complex business logic
- ✅ External callouts with custom handling
- ✅ Heavy calculations
- Use for: Integration logic, complex calculations, batch processing

**PromptTemplate:**
- ✅ AI-generated content
- ✅ Summaries, recommendations, drafts
- Use for: Email drafts, case summaries, product recommendations

**External Service:**
- ✅ Calling third-party APIs
- ✅ Uses OpenAPI spec for auto-generation
- Use for: External system integration without Apex

### Action Configuration

Every action requires:

| Element | Purpose | Example |
|---------|---------|---------|
| **Capability description** | When the agent should invoke this action | "Use when customer asks about order status and provides an order number" |
| **Input parameters** | Mapped from conversation or user input | `orderNumber` (string, required) |
| **Output parameters** | Returned to agent for response | `orderStatus`, `estimatedDelivery` |

**⚠️ Critical:** Parameter names must match the target contract **exactly**:
- Flows: match Flow input/output variable API names
- Apex: match `@InvocableVariable` field names
- PromptTemplates: match template input/output variable names

### GenAiFunction Example (Action Metadata)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<GenAiFunction xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>LookupOrder</fullName>
    <label>Lookup Order</label>
    <targetType>Flow</targetType>
    <targetName>Lookup_Order_Flow</targetName>
    <capabilityDescription>
        Use this action when the customer wants to check on an order status
        and provides an order number or order ID.
    </capabilityDescription>
    <inputs>
        <name>orderNumber</name>
        <description>The order number provided by the customer</description>
        <dataType>Text</dataType>
        <isRequired>true</isRequired>
    </inputs>
    <outputs>
        <name>orderStatus</name>
        <description>The current status of the order</description>
        <dataType>Text</dataType>
    </outputs>
</GenAiFunction>
```

### Action Grouping with GenAiPlugin

Group related `GenAiFunction` entries into a `GenAiPlugin` for logical organization:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<GenAiPlugin xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>OrderManagement</fullName>
    <label>Order Management</label>
    <description>Actions for managing customer orders</description>
    <genAiFunctions>
        <genAiFunction>LookupOrder</genAiFunction>
        <genAiFunction>GetOrderStatus</genAiFunction>
        <genAiFunction>CancelOrder</genAiFunction>
    </genAiFunctions>
</GenAiPlugin>
```

## PromptTemplate

PromptTemplate metadata defines reusable prompt configurations for AI-generated content.

### Template Types

| Type | Use Case | Example |
|------|----------|---------|
| `einstein_gpt__fieldCompletion` | Single-field generation | Auto-fill a description field |
| `einstein_gpt__salesEmail` | Email drafting | Generate follow-up email |
| `einstein_gpt__flex` | General-purpose | Any text generation |
| `einstein_gpt__chat` | Conversational grounding | Agent persona, context |

### Template Components

| Component | Purpose |
|-----------|---------|
| **Input variables** | Data passed into the template (record fields, user input) |
| **Output variable** | The generated result |
| **Resolution steps** | Ordered prompt fragments and instructions |
| **Model configuration** | Which model to use and parameters |

### PromptTemplate as Agent Action

**Step-by-step setup:**

1. **Create the PromptTemplate metadata** — define inputs, outputs, prompt
2. **Activate the template** — ⚠️ Draft templates cause publish errors!
3. **Register it as a GenAiFunction** — create the action wrapper
4. **Attach to a topic** — make it available in context
5. **Map inputs** — connect conversation context to template inputs

### Models API Integration

Use the Models API from Apex for custom model routing:

```apex
public with sharing class ModelService {

    @InvocableMethod(label='Generate Summary' description='Generates a summary using Einstein AI')
    public static List<String> generateSummary(List<SummaryRequest> requests) {
        List<String> results = new List<String>();

        for (SummaryRequest req : requests) {
            try {
                ConnectApi.EinsteinLlmGenerateParams params =
                    new ConnectApi.EinsteinLlmGenerateParams();
                params.promptTextorId = 'Summarize the following in 2-3 sentences: ' + req.textToSummarize;

                ConnectApi.EinsteinLlmGenerationOutput output =
                    ConnectApi.EinsteinAI.generateMessages(params);

                results.add(output.generatedMessages[0].text);
            } catch (Exception e) {
                results.add('Unable to generate summary: ' + e.getMessage());
            }
        }

        return results;
    }

    public class SummaryRequest {
        @InvocableVariable(label='Text to Summarize' required=true)
        public String textToSummarize;
    }
}
```

**Trust Layer:** All Models API calls are protected by the Einstein Trust Layer:
- Prompt defense (injection protection)
- Toxicity detection
- PII masking
- Audit trail
- Zero data retention (your data isn't used for training)

## Agent Scripts (Deterministic Agents)

Agent Scripts provide a **code-first, FSM-based** (Finite State Machine) approach for building deterministic agents. Use `.agent` files with a declarative DSL.

### When to Use Agent Scripts vs Setup UI

| Scenario | Agent Script | Setup UI / Agent Builder |
|----------|--------------|--------------------------|
| Routing behavior | Deterministic (state machine) | LLM-directed (planner decides) |
| Version control | `.agent` files in Git | Metadata XML retrieved from org |
| Repeatability | Identical behavior every time | May vary with LLM interpretation |
| Best for | Regulated processes, compliance flows | General customer service, flexible Q&A |

### Agent Script DSL Structure

```yaml
config:
  developer_name: MyServiceAgent
  master_label: My Service Agent
  agent_description: Handles customer service inquiries
  agent_type: AgentforceServiceAgent
  default_agent_user: einstein_agent_user@company.com

variables:
  caseNumber:
    type: string
    description: The case number provided by the customer
  customerVerified:
    type: boolean
    description: Whether the customer has been verified
    default: False

system:
  greeting: Hello! I am your service agent. How can I help you today?

start_agent:
  topic: Greeting

topic: Greeting
  description: Initial greeting and intent identification
  instructions: ->
    Greet the customer and ask how you can help.
    Identify their intent and route to the appropriate topic.
  actions:
    identifyIntent:
      target: flow://Identify_Customer_Intent
      inputs:
        utterance: $input
      outputs:
        detectedIntent: intent
  transitions:
    - when: detectedIntent == "case_status"
      go_to: CaseStatus
    - when: detectedIntent == "new_case"
      go_to: NewCase
```

### Key DSL Rules

| Rule | Wrong | Right |
|------|-------|-------|
| One start_agent | Multiple start_agent blocks | Exactly one `start_agent` block |
| Indentation | Mixed tabs and spaces | Pick one, be consistent |
| Booleans | `true` / `false` | `True` / `False` (capitalized) |
| Conditionals | `else if` | Separate conditions |
| Blocks | Nested `if` blocks | Flat conditions |
| Linked variables | With defaults | No defaults allowed |

### Agent Script CLI

```bash
# Validate an agent script
sf agent validate authoring-bundle --api-name MyAgent -o myOrg --json

# Publish an agent script
sf agent publish authoring-bundle --api-name MyAgent -o myOrg --json

# Activate the agent (required separate step!)
sf agent activate --api-name MyAgent -o myOrg
```

## Metadata Structure

| Metadata Type | File Suffix | Purpose |
|---------------|-------------|---------|
| Bot | `.agent-meta.xml` | Agent definition, versions, context variables |
| GenAiTopic | `.agentTopic-meta.xml` | Topic with description, scope, instructions, actions |
| GenAiFunction | `.genAiFunction-meta.xml` | Single action wrapping Flow, Apex, or PromptTemplate |
| GenAiPlugin | `.genAiPlugin-meta.xml` | Logical grouping of related GenAiFunctions |
| PromptTemplate | `.promptTemplate-meta.xml` | Prompt configuration with inputs, outputs, model settings |

## Testing Agents

### Agentforce Testing Center

Access via **Setup > Agentforce > Testing Center**:
- Multi-turn conversation validation
- Topic routing verification
- Action execution testing
- Guardrail testing

### CLI Testing Commands

```bash
# Preview an agent interactively
sf agent preview --name MyAgent -o myOrg

# Test a specific utterance
sf agent test --name MyAgent --utterance "What is the status of order 12345?" -o myOrg

# Validate agent configuration (pre-publish check)
sf agent validate authoring-bundle --api-name MyAgent -o myOrg --json

# Run test suite from spec file
sf agent test run --spec-file tests/order-status.yaml -o myOrg --json

# Get test results
sf agent test results --test-run-id 0Atxx0000000001 -o myOrg --json

# Publish agent (metadata deployment)
sf agent publish authoring-bundle --api-name MyAgent -o myOrg --json

# Activate agent (make it live — REQUIRED after publish)
sf agent activate --api-name MyAgent -o myOrg
```

### Test Coverage Checklist

| Category | What to Test | Example |
|----------|-------------|---------|
| **Topic routing** | Correct topic for each utterance | "Check my order" → Order Status topic |
| **Action invocation** | Actions called with correct params | LookupOrder receives orderNumber |
| **Context preservation** | Multi-turn maintains state | "What about order 456?" remembers context |
| **Guardrails** | Off-topic handled appropriately | "Tell me a joke" → polite decline |
| **Escalation** | Agent escalates when needed | Complex issue → "Let me connect you with an agent" |
| **Phrasing variation** | Multiple ways to ask same thing | "order status" / "where's my order" / "track package" |

### Test-Fix Loop

1. **Run tests** and capture failures
2. **Classify failures:**
   - Topic mismatch — improve description/scope
   - Action failure — check parameter mapping
   - Context loss — review instructions
   - Guardrail failure — add explicit boundaries
3. **Fix the agent** (topic descriptions, instructions, action configs)
4. **Re-publish and re-activate:**
   ```bash
   sf agent publish authoring-bundle --api-name MyAgent -o myOrg --json
   sf agent activate --api-name MyAgent -o myOrg
   ```
5. **Re-run focused tests** before full regression

## Agent Observability

### Session Tracing Data Model (STDM)

STDM captures structured telemetry for every agent session:
- **Sessions**: Overall conversation container
- **Interactions**: Individual turns (user input + agent response)
- **InteractionSteps**: Actions taken within a turn
- **Moments**: Key decision points
- **Messages**: Actual message content

Enable tracing in **Setup > Einstein AI > Session Tracing**.

### Session Transcripts

Query session transcripts via:
- Agent Runtime API
- Data Cloud dashboards

Use transcripts to:
- Debug topic routing failures
- Inspect action parameters
- Verify context preservation across turns
- Identify training opportunities

### EventLogFile for Agent Events

```soql
SELECT Id, EventType, LogDate, LogFileLength
FROM EventLogFile
WHERE EventType IN ('AIInteraction', 'AIInsightAction')
ORDER BY LogDate DESC
```

Use for:
- Aggregate monitoring
- Invocation counts
- Error rates
- Latency trends

## Agent Persona Design

### Voice Attributes

Define your agent's personality:

| Attribute | Range | Example |
|-----------|-------|---------|
| **Register** | Formal ↔ Casual | "I apologize for any inconvenience" vs "Sorry about that!" |
| **Warmth** | Neutral ↔ Empathetic | "Your order shipped" vs "Great news! Your order is on its way!" |
| **Brevity** | Concise ↔ Detailed | One-line answers vs full explanations |
| **Humor** | None ↔ Light | Strictly business vs occasional friendly quips |

### System Instructions for Persona

Encode persona in agent's system instructions:

```text
You are OrderBot, a helpful customer service agent for Acme Corp.

Personality:
- Friendly but professional
- Use customer's name when available
- Be empathetic when customers are frustrated
- Keep responses concise (2-3 sentences max)

Never:
- Promise specific delivery dates
- Discuss competitor products
- Use slang or informal abbreviations
- Make jokes about the customer's situation

Always:
- Confirm understanding before taking action
- Offer to escalate complex issues
- Thank the customer for their patience
```

## Deployment Workflow

### Step-by-Step

1. **Deploy supporting components first:**
   ```bash
   # Objects and fields
   sf project deploy start -d force-app/main/default/objects -o myOrg

   # Apex classes
   sf project deploy start -d force-app/main/default/classes -o myOrg

   # Flows
   sf project deploy start -d force-app/main/default/flows -o myOrg

   # PromptTemplates
   sf project deploy start -d force-app/main/default/promptTemplates -o myOrg
   ```

2. **Activate PromptTemplates** (via UI or script)

3. **Deploy agent components:**
   ```bash
   # GenAiFunctions
   sf project deploy start -d force-app/main/default/genAiFunctions -o myOrg

   # GenAiPlugins
   sf project deploy start -d force-app/main/default/genAiPlugins -o myOrg

   # Agent metadata
   sf project deploy start -d force-app/main/default/bots -o myOrg
   ```

4. **Publish the agent:**
   ```bash
   sf agent publish authoring-bundle --api-name MyAgent -o myOrg --json
   ```

5. **Activate the agent:**
   ```bash
   sf agent activate --api-name MyAgent -o myOrg
   ```

## Gotchas and Common Mistakes

| Issue | What Goes Wrong | How to Fix |
|-------|-----------------|------------|
| **Publish ≠ Activate** | Agent deployed but not reachable | Always run `sf agent activate` after publish |
| **Draft PromptTemplates** | Publish fails with "invalid parameters" | Activate templates before publishing agent |
| **Parameter name mismatch** | Action invoked but receives null | Exact match: `orderNumber` not `order_number` |
| **Topic scope overlap** | Random routing, wrong topic matched | Make descriptions distinct, add explicit out-of-scope |
| **Agent User permissions** | Actions fail with access errors | Grant all needed permission sets to Agent User |
| **API version too low** | Metadata rejected or ignored | Use API version 66.0+ |
| **Agent Script `else if`** | Syntax error | Use separate conditions instead |
| **Agent Script nested `if`** | Syntax error | Flatten to single-level conditions |
| **Testing Center limits** | Can't test external service actions | Test external services separately |
| **Missing dependencies** | Deploy fails | Deploy in order: objects → classes → flows → templates → agent |

## Review Checklist

Before deploying an agent to production:

- [ ] Agent type matches use case (Service vs Employee)
- [ ] Service Agent has valid Einstein Agent User configured
- [ ] Agent User has all required permission sets
- [ ] Topic descriptions are specific and non-overlapping
- [ ] Scope boundaries explicitly defined for each topic
- [ ] Action capability descriptions clearly state invocation criteria
- [ ] Input/output parameter names match target contracts exactly
- [ ] PromptTemplates are in Active status (not Draft)
- [ ] Dependencies deployed in correct order
- [ ] Agent is both published AND activated
- [ ] Tests cover all topics, actions, guardrails, and escalation
- [ ] Persona instructions are clear and consistent

## Best Practices Summary

| Category | Do | Don't |
|----------|-----|-------|
| **Topics** | Keep to 7-10 max | Create 15+ overlapping topics |
| **Descriptions** | Be specific, action-oriented | Use vague, generic descriptions |
| **Actions** | Use Flows as default | Jump to Apex for simple logic |
| **Parameters** | Match names exactly | Add underscores or change case |
| **Testing** | Test every path | Deploy without testing |
| **Deployment** | Follow dependency order | Deploy agent before dependencies |
| **Activation** | Always activate after publish | Assume publish makes it live |