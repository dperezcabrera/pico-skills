---
name: add-agent
description: Add an LLM agent or tool with pico-agent. Use when creating AI agents, chatbots, or LLM-powered tools.
argument-hint: [agent name]
---

# Add Agent

Create an agent: $ARGUMENTS

Read the codebase to understand existing agents and patterns, then create the agent.

## ReAct Agent (with tools)

```python
from pico_agent import agent, AgentType, AgentCapability

@agent(
    name="$ARGUMENTS",
    capability=AgentCapability.SMART,
    agent_type=AgentType.REACT,
    system_prompt="""You are a specialized assistant for...

## Rules
- Be concise and accurate
- Use available tools when needed

## Response Format
Provide structured responses with clear sections.
""",
    tools=["search_db", "calculator"],
    temperature=0.7,
    max_iterations=5,
)
class ${ARGUMENTS}Agent:
    async def invoke(self, input: str) -> str:
        ...
```

## One-Shot Agent (no tools)

```python
@agent(
    name="summarizer",
    capability=AgentCapability.FAST,
    agent_type=AgentType.ONE_SHOT,
    system_prompt="Summarize the following text concisely.",
    temperature=0.3,
)
class SummarizerAgent:
    async def invoke(self, input: str) -> str:
        ...
```

## Custom Tool

```python
from pico_agent import tool
from pico_ioc import component

@tool(name="search_db", description="Search records matching a query")
@component
class SearchDbTool:
    def __init__(self, repo: RecordRepository):
        self.repo = repo

    async def __call__(self, query: str) -> str:
        results = await self.repo.search(query)
        return "\n".join(str(r) for r in results)
```

## Virtual Agent (YAML)

```yaml
# agents/support_agent.yaml
name: support_agent
capability: smart
agent_type: react
system_prompt: |
  You are a customer support assistant.
tools:
  - search_kb
  - create_ticket
temperature: 0.5
max_iterations: 10
```

## Parameters Reference

| Parameter | Default | Description |
|-----------|---------|-------------|
| `name` | required | Unique agent name |
| `capability` | `SMART` | `FAST`, `SMART`, `REASONING`, `VISION`, `CODING` |
| `agent_type` | `ONE_SHOT` | `ONE_SHOT`, `REACT`, `WORKFLOW` |
| `system_prompt` | `""` | System instructions |
| `tools` | `None` | Tool names to attach |
| `temperature` | `0.7` | LLM temperature |
| `max_iterations` | `5` | Max ReAct iterations |

## Checklist

- [ ] Clear, specific system prompt with rules and format
- [ ] Capability matches task complexity
- [ ] Tools registered for external operations
- [ ] Temperature tuned (low for factual, high for creative)
