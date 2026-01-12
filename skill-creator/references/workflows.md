# Workflow Patterns

## Sequential Workflows

For complex tasks, break operations into clear, sequential steps. It is often helpful to give Claude an overview of the process towards the beginning of SKILL.md:

```markdown
Filling a PDF form involves these steps:

1. Analyze the form (run analyze_form.py)
2. Create field mapping (edit fields.json)
3. Validate mapping (run validate_fields.py)
4. Fill the form (run fill_form.py)
5. Verify output (run verify_output.py)
```

## Conditional Workflows

For tasks with branching logic, guide Claude through decision points:

```markdown
1. Determine the modification type:
   **Creating new content?** → Follow "Creation workflow" below
   **Editing existing content?** → Follow "Editing workflow" below

2. Creation workflow: [steps]
3. Editing workflow: [steps]
```

## Parallel Workflows (Sub-agent 활용)

For tasks with independent sub-tasks, use sub-agents for parallel execution to reduce total time.

### When to Use Parallel Sub-agents

| Scenario | Recommended | Reason |
|----------|-------------|--------|
| Single file/small scope | ❌ | Sub-agent overhead exceeds benefit |
| 2-3 independent tasks | △ | Consider based on task complexity |
| 4+ independent tasks | ✅ | Significant time savings |
| Large codebase analysis | ✅ | Explore agents are fast and cheap |

### Sub-agent Types for Skills

**Explore agent (읽기 전용 분석)**
- Model: Haiku (fast, cost-effective)
- Use for: Codebase exploration, pattern detection, file analysis
- Tools: Glob, Grep, Read, limited Bash

**General-purpose agent (복잡한 작업)**
- Model: Sonnet
- Use for: Multi-step tasks requiring both analysis and modification
- Tools: All tools available

### Parallel Workflow Example

```markdown
## Step 2: Analyze Existing Patterns

When analyzing a large codebase for skill creation:

**For small scope (1-3 files):**
- Analyze directly

**For large scope (4+ files or multiple directories):**
- Use Task tool to launch parallel Explore agents:

Task 1 (Explore): "Analyze src/components/ for reusable UI patterns"
Task 2 (Explore): "Analyze src/hooks/ for common hook patterns"
Task 3 (Explore): "Analyze src/utils/ for utility function patterns"

- Aggregate results and proceed to planning
```

### Parallel Resource Creation Example

```markdown
## Step 4: Create Skill Resources

When creating multiple independent resources:

**Independent resources can be created in parallel:**

Task 1 (General-purpose): "Create scripts/validate.py based on validation requirements"
Task 2 (General-purpose): "Create scripts/transform.py based on transformation requirements"
Task 3 (General-purpose): "Create references/api-docs.md documenting the API schema"

**Dependent resources must be sequential:**
- SKILL.md (depends on knowing all resources)
- Integration tests (depend on scripts existing)
```

### Best Practices

1. **Identify independence first** - Only parallelize truly independent tasks
2. **Provide complete context** - Each sub-agent starts fresh; include all necessary information
3. **Aggregate results** - Plan how to combine sub-agent outputs
4. **Prefer Explore for read-only** - Use cheaper Haiku model when no modifications needed