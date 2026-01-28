# Diet App Project — Quick Start

## Setup with Claude Code

1. **Create your project directory**:
   ```bash
   mkdir diet-app && cd diet-app
   ```

2. **Copy the CLAUDE.md file** into the root of your project directory

3. **Initialize git** (Claude Code works best with git):
   ```bash
   git init
   ```

4. **Launch Claude Code**:
   ```bash
   claude
   ```

5. **Give the starting command**:
   ```
   Read CLAUDE.md and begin. You are the Manager.
   ```

---

## How to Interact

You're the CEO. The Manager reports to you. Here's how to engage:

### Requesting Status
```
Manager, status report.
```

### Approving Decisions
```
Approved. Proceed.
```

### Requesting Changes
```
I want you to reconsider [X]. Explore [alternative approach].
```

### Escalating Quality
```
This isn't great yet. What would make it exceptional?
```

### Triggering Agent Work
```
Have the [Research/UX/Backend/iOS/AI] Agent focus on [specific task].
```

### Approving Promotions
```
Approved. Promote [Agent] to Director. Define the sub-agents.
```

---

## Expected Directory Structure (as project evolves)

```
diet-app/
├── CLAUDE.md                    # The system prompt (this file)
├── README.md                    # This quick-start guide
├── docs/
│   ├── research/
│   │   ├── competitive-analysis.md
│   │   ├── pain-points.md
│   │   ├── behavioral-principles.md
│   │   └── market-segments.md
│   ├── design/
│   │   ├── personas.md
│   │   ├── user-journeys.md
│   │   ├── design-system.md
│   │   └── wireframes/
│   ├── architecture/
│   │   ├── adr/                 # Architecture Decision Records
│   │   ├── data-model.md
│   │   ├── api-spec.md
│   │   └── security.md
│   └── status-reports/
├── ios/                         # Swift/SwiftUI project
├── backend/                     # API/services
├── ai/                          # ML models/pipelines
└── prototypes/                  # Figma exports, HTML prototypes
```

---

## Tips for Best Results

1. **Let the Manager run** — Don't micromanage. Request reports, make decisions, but let the system work.

2. **Push for reasoning** — If a decision seems arbitrary, ask "Why this over the alternatives?"

3. **Demand evidence** — "Show me the user complaints that support this feature priority."

4. **Use phase gates** — Don't let the Manager skip ahead. Research must be solid before design begins.

5. **Challenge "good enough"** — The prompt explicitly says to reject mediocrity. Reinforce this when you see settling.

---

## When to Intervene

- Agent conflict that Manager can't resolve
- Cost decisions exceeding thresholds
- Scope changes (adding/removing major features)
- Privacy/security decisions
- When something feels off — trust your 25 years of experience

---

## Modifying the System

The CLAUDE.md is your control surface. You can:

- Add new agents by defining them in the same format
- Adjust quality gates if they're too strict/loose
- Change the decision escalation matrix
- Add specific constraints (budget, timeline, must-have features)

Just edit CLAUDE.md and tell Claude Code to re-read it.
