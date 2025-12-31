# User Personas: Private Chat Hub

**Document Version:** 1.0  
**Created:** December 31, 2025  
**Purpose:** Define target users to guide product decisions

---

## Primary Personas

### 👨‍💻 Persona 1: Alex - The Privacy Advocate

**Demographics:**
- Age: 35
- Occupation: System Administrator / DevOps Engineer
- Location: Urban/Suburban
- Tech Savvy: High

**Background:**
Alex has been running self-hosted services for 10+ years. He maintains a home server with Jellyfin, Nextcloud, Home Assistant, and now Ollama. He's deeply concerned about data privacy and believes in digital sovereignty. Alex migrated away from Google services years ago and actively promotes open-source alternatives.

**Goals:**
- Maintain complete control over personal data
- Use AI capabilities without cloud dependencies
- Integrate AI into existing self-hosted ecosystem
- Reduce subscription fatigue

**Pain Points:**
- Cloud AI services require sending private data to corporations
- Existing local AI tools are desktop-focused and clunky
- Mobile AI apps are locked into cloud providers
- Limited options for privacy-respecting AI on mobile

**Behaviors:**
- Checks r/selfhosted and r/LocalLLaMA daily
- Experiments with new self-hosted services weekly
- Values terminal/API access to services
- Willing to spend time on initial setup for long-term benefits

**Technical Environment:**
- Runs Ollama on home server (32GB RAM, RTX 3090)
- Uses Android phone (flagship, 2 years old)
- Local network: Gigabit ethernet, WiFi 6
- Docker for service management

**Needs from Product:**
- Reliable connection to local Ollama instance
- Clear visibility into what data is being transmitted
- Export capabilities for conversation backups
- No telemetry or cloud dependencies

**Quote:** *"I don't trust my conversations with a corporation. If I can't export it, own it, and control it, I won't use it."*

---

### 🔬 Persona 2: Maya - The AI Developer

**Demographics:**
- Age: 28
- Occupation: Machine Learning Engineer
- Location: Tech hub city
- Tech Savvy: Very High

**Background:**
Maya works at a mid-size tech company developing AI-powered features. She experiments with different LLM models for prototyping and testing. Maya needs a fast way to compare model outputs, test prompts, and validate behavior before integrating into production systems. She's frustrated by rate limits and costs on cloud AI platforms.

**Goals:**
- Rapidly test and compare different models
- Prototype AI features on mobile before web integration
- Experiment with vision models and multimodal AI
- Keep work-related conversations separate from production logs

**Pain Points:**
- ChatGPT/Claude rate limits interrupt her workflow
- Switching between models requires multiple tabs/apps
- Cloud APIs cost adds up during heavy experimentation
- Cannot test with custom or fine-tuned models easily

**Behaviors:**
- Tests 50-100 prompts per day across multiple models
- Frequently switches models to compare outputs
- Takes screenshots of UI for vision model testing
- Documents findings in personal notes/wiki

**Technical Environment:**
- Development laptop with Ollama (64GB RAM, RTX 4090)
- Android phone (current flagship)
- Local network: High-speed, VPN to home when remote
- Uses git, VS Code, Jupyter notebooks

**Needs from Product:**
- One-tap model switching
- Clear model information (parameters, capabilities)
- Ability to attach code files as context
- Conversation export for documentation
- Performance metrics (response time, tokens)

**Quote:** *"I need to test 10 different models with the same prompt in under a minute. Time is money in experimentation."*

---

### 📱 Persona 3: Jordan - The Power User

**Demographics:**
- Age: 32
- Occupation: Product Manager / Knowledge Worker
- Location: Anywhere with good internet
- Tech Savvy: Medium-High

**Background:**
Jordan uses AI daily for writing, research, brainstorming, and learning. He's been a ChatGPT Plus subscriber for 2 years but is frustrated by the $20/month cost and occasional downtime. Jordan recently built a mini PC to run Ollama and wants to migrate to a self-hosted solution. He values organization and efficiency.

**Goals:**
- Reduce AI subscription costs while maintaining capabilities
- Organize conversations by project/topic
- Access AI anywhere in home (mobile, desktop)
- Own and control conversation history

**Pain Points:**
- $240/year for ChatGPT Plus feels excessive
- ChatGPT conversations are poorly organized
- Cannot easily export or search old conversations
- Worried about OpenAI using conversations for training

**Behaviors:**
- Uses AI for 30-60 minutes daily
- Creates 5-10 new conversations per day
- Revisits old conversations weekly for reference
- Shares AI-generated content via email/Slack frequently

**Technical Environment:**
- Mini PC with Ollama (16GB RAM, no GPU - CPU only)
- Android phone (mid-range, 1 year old)
- Local network: Standard WiFi router
- Uses productivity apps (Notion, Todoist, Google Workspace)

**Needs from Product:**
- Projects/spaces for topic organization
- Easy sharing via Android share menu
- Conversation search and history
- Smart model recommendations based on hardware
- Intuitive UI for non-technical users

**Quote:** *"I don't need the fanciest model. I just need reliable AI that doesn't cost $20/month and respects my privacy."*

---

## Secondary Personas

### 🎓 Persona 4: Sam - The Student Researcher

**Demographics:**
- Age: 22
- Occupation: Computer Science Graduate Student
- Location: University campus / shared housing
- Tech Savvy: High

**Background:**
Sam is researching natural language processing for their thesis. They need to experiment with different LLM architectures and compare behaviors. Cloud API costs are prohibitive on a student budget. Sam has access to university compute resources but wants mobile access for testing on-the-go.

**Goals:**
- Learn about LLMs through hands-on experimentation
- Complete thesis research without exceeding budget
- Test models during commute and between classes
- Compare model behaviors systematically

**Pain Points:**
- Limited budget for cloud AI APIs
- University compute requires VPN and is desktop-only
- Need mobile access but current tools are cloud-dependent
- Cannot afford multiple subscriptions (ChatGPT, Claude, etc.)

**Needs from Product:**
- Free, self-hosted solution
- Model comparison features
- Educational resources about models
- Export for research documentation

**Quote:** *"I'm learning AI, not made of money. I need tools that help me experiment without breaking my budget."*

---

### 💼 Persona 5: Chris - The Enterprise User

**Demographics:**
- Age: 42
- Occupation: Senior Analyst / Corporate IT
- Location: Office + remote work
- Tech Savvy: Medium

**Background:**
Chris works at a company with strict data privacy policies. They cannot use cloud AI services (ChatGPT, Claude) for work-related tasks due to compliance requirements. The company is exploring self-hosted AI solutions. Chris needs a mobile interface to interact with the company's internal Ollama deployment.

**Goals:**
- Use AI for work tasks while maintaining compliance
- Access company AI infrastructure from mobile device
- Ensure all conversations are auditable and exportable
- Simple, reliable tool that "just works"

**Pain Points:**
- Cloud AI violates company data policy
- Existing enterprise tools are desktop-web only
- IT department hasn't provided mobile solution
- Needs AI for meetings, travel, field work

**Needs from Product:**
- Enterprise-grade security and audit trails
- Simple connection to corporate Ollama instance
- Conversation export for compliance
- Minimal setup and configuration

**Quote:** *"I need AI to do my job better, but I can't risk my career using unauthorized cloud services."*

---

## Anti-Personas (Who This is NOT For)

### ❌ Anti-Persona 1: The Casual Cloud User
- Just wants AI to work without setup
- No interest in self-hosting or privacy concerns
- Unwilling to manage infrastructure
- Prefers "just download and go" experience
- **Why Not:** Our product requires Ollama setup and local infrastructure

### ❌ Anti-Persona 2: The iPhone-Only User
- Exclusively uses iOS devices
- Not interested in Android
- **Why Not:** MVP is Android-only (iOS in Phase 4+)

### ❌ Anti-Persona 3: The Non-Technical Manager
- Wants AI but has no technical skills
- Cannot set up Ollama or local servers
- Needs managed, cloud solution
- **Why Not:** Setup complexity is too high without technical knowledge

---

## Persona Prioritization for MVP

### Phase 1 (MVP) Focus:
1. **Alex - The Privacy Advocate** (Primary)
   - Core user, will evangelize product
   - Has infrastructure ready
   - Provides valuable feedback

2. **Maya - The AI Developer** (Primary)
   - High usage, clear requirements
   - Needs advanced features
   - Will push product limits

3. **Jordan - The Power User** (Secondary)
   - Growing segment
   - Bridge between technical and casual
   - Validates usability

### Phase 2+ Focus:
4. **Sam - The Student Researcher**
5. **Chris - The Enterprise User**

---

## Using These Personas

When making product decisions, ask:

1. **Does this serve our primary personas?** (Alex, Maya, Jordan)
2. **Does this compromise privacy?** (Alex will reject it)
3. **Is this technically flexible?** (Maya needs customization)
4. **Is this simple enough?** (Jordan needs intuitive UI)
5. **Can we build this in MVP scope?** (Focus on Phase 1 personas)

---

**Related Documents:**
- [PRODUCT_VISION.md](PRODUCT_VISION.md) - Overall product vision
- [USER_STORIES_MVP.md](USER_STORIES_MVP.md) - User stories derived from personas
- [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md) - Functional requirements
