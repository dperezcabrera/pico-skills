---
name: pico-agent
description: Creates LLM agents and tools with pico-agent
argument-hint: [agent name]
---

# Pico-Agent Creator

Create an agent: $ARGUMENTS

## Rules

- Use `@agent` decorator to define agents
- Use `@tool` decorator to define tools
- Choose `AgentType`: `ONE_SHOT` (single response), `REACT` (iterative with tools), `WORKFLOW` (multi-step)
- Choose `AgentCapability`: `FAST`, `SMART`, `REASONING`, `VISION`, `CODING`
- All imports from `pico_agent`

## Basic Agent

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
    tools=["search", "calculator"],
    temperature=0.7,
    max_iterations=5,
)
class ${ARGUMENTS}Agent:
    async def invoke(self, input: str) -> str:
        ...
```

## One-Shot Agent (No Tools)

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

@tool(name="search_db", description="Search the database for records matching a query")
@component
class SearchDbTool:
    def __init__(self, repo: RecordRepository):
        self.repo = repo

    async def __call__(self, query: str) -> str:
        results = await self.repo.search(query)
        return "\n".join(str(r) for r in results)
```

## Virtual Agent (YAML Configuration)

```yaml
# agents/support_agent.yaml
name: support_agent
capability: smart
agent_type: react
system_prompt: |
  You are a customer support assistant.
  Answer questions about our products and services.
tools:
  - search_kb
  - create_ticket
temperature: 0.5
max_iterations: 10
```

## Agent with Tracing

```python
@agent(
    name="analyst",
    capability=AgentCapability.REASONING,
    agent_type=AgentType.REACT,
    system_prompt="Analyze data and provide insights.",
    tracing_enabled=True,  # Default: True
    tools=["query_data", "plot_chart"],
)
class AnalystAgent:
    async def invoke(self, input: str) -> str:
        ...
```

## Agent Parameters Reference

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `str` | required | Unique agent name |
| `capability` | `str` | `SMART` | LLM capability level |
| `agent_type` | `AgentType` | `ONE_SHOT` | Execution strategy |
| `system_prompt` | `str` | `""` | System instructions |
| `user_prompt_template` | `str` | `"{input}"` | User prompt template |
| `tools` | `list[str]` | `None` | Tool names to attach |
| `agents` | `list[str]` | `None` | Sub-agents to delegate to |
| `temperature` | `float` | `0.7` | LLM temperature |
| `max_iterations` | `int` | `5` | Max ReAct iterations |
| `tracing_enabled` | `bool` | `True` | Enable trace collection |
| `llm_profile` | `str` | `None` | Named LLM config profile |

## Checklist

- [ ] Clear, specific system prompt
- [ ] Appropriate capability for the task complexity
- [ ] Tools registered for any external operations
- [ ] Max iterations set for ReAct agents
- [ ] Temperature tuned (low for factual, high for creative)
