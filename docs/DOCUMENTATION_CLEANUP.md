# 📋 Documentation Cleanup & Migration Guide

**Date:** January 26, 2026  
**Purpose:** Track documentation updates after strategic refocus to v1.5  
**Status:** 🔄 In Progress

---

## ✅ Completed Updates

### Core Documents (Updated)
- ✅ [PRODUCT_VISION.md](PRODUCT_VISION.md) - Completely rewritten for universal AI hub vision
- ✅ [README.md](../README.md) - Updated to reflect local + cloud + self-hosted support
- ✅ [STRATEGIC_REFOCUS_V1.5.md](STRATEGIC_REFOCUS_V1.5.md) - New guide for agents (CREATED)

### New v1.5 Documents (Created)
- ✅ [PRODUCT_REQUIREMENTS_V1.5.md](PRODUCT_REQUIREMENTS_V1.5.md) - Complete v1.5 requirements
- ✅ [ARCHITECTURE_CLOUD_API_INTEGRATION.md](ARCHITECTURE_CLOUD_API_INTEGRATION.md) - Cloud API architecture
- ✅ [DOCUMENTATION_CLEANUP.md](DOCUMENTATION_CLEANUP.md) - This file

---

## 🔄 Documents Needing Updates

### High Priority (P0) - Block v1.5 Implementation

#### USER_PERSONAS.md
**Status:** Outdated - Focused on privacy-only users  
**Changes Needed:**
- Add "Pragmatic Power User" persona (uses local + cloud)
- Add "Cost-Conscious Developer" persona (optimizes costs)
- Update "Privacy Advocate" to acknowledge cloud option exists
- Add "Mobile Professional" persona (offline + cloud)

**Owner:** @product-owner or @experience-designer  
**Estimate:** 2-3 hours

---

#### ARCHITECTURE_DECISIONS.md
**Status:** Missing cloud API decisions  
**Changes Needed:**
- Add ADR: "Why Support Cloud APIs"
- Add ADR: "Provider Abstraction Pattern"
- Add ADR: "API Key Storage Strategy"
- Add ADR: "Cost Tracking Implementation"
- Add ADR: "Fallback Strategy Design"

**Owner:** @architect  
**Estimate:** 3-4 hours

---

### Medium Priority (P1) - Improve Developer Experience

#### UX_DESIGN_LOCAL_REMOTE_MODEL_SYSTEM.md
**Status:** Only covers Local + Ollama  
**Changes Needed:**
- Extend to include cloud providers (OpenAI, Anthropic, Google)
- Add cost display patterns
- Add provider status indicators (badges, colors)
- Add fallback dialog designs
- Update model picker mockups

**Alternative:** Create new UX_DESIGN_CLOUD_API.md  
**Owner:** @experience-designer  
**Estimate:** 4-6 hours

---

#### USER_STORIES_MVP.md
**Status:** Only covers v1.0 features  
**Changes Needed:**
- Create USER_STORIES_V1.5.md with cloud API user stories:
  - "As a user, I want to add my OpenAI API key so I can chat with GPT-4"
  - "As a user, I want to see token usage and costs so I can track spending"
  - "As a user, I want automatic fallback when a provider fails"
  - etc.

**Alternative:** Create new USER_STORIES_V1.5.md  
**Owner:** @product-owner  
**Estimate:** 3-4 hours

---

#### GETTING_STARTED.md
**Status:** Only covers Ollama setup  
**Changes Needed:**
- Add section "Choose Your Setup Path"
- Add "Option A: Local-Only Setup" (LiteRT)
- Add "Option B: Cloud API Setup" (OpenAI/Anthropic/Google)
- Add "Option C: Hybrid Setup" (all three)
- Update screenshots to show provider options

**Owner:** @doc-writer  
**Estimate:** 2-3 hours

---

### Low Priority (P2) - Polish & Consistency

#### APP_CUSTOMIZATION.md
**Status:** Needs cloud provider references  
**Changes Needed:**
- Update "Model Selection" section to mention cloud APIs
- Add "API Key Configuration" section
- Update screenshots to show provider badges

**Owner:** @doc-writer  
**Estimate:** 1-2 hours

---

#### CONTRIBUTING.md
**Status:** May need cloud API testing guidance  
**Changes Needed:**
- Add section "Testing with Cloud APIs"
- Add guidance on using test API keys
- Add cost considerations for contributors
- Add provider abstraction testing patterns

**Owner:** @doc-writer  
**Estimate:** 1-2 hours

---

## ⚠️ Potentially Obsolete Documents

### Review for Conflicts with v1.5

These documents may contain information that conflicts with the new v1.5 direction. Review and update or deprecate:

#### PRODUCT_ROADMAP_V2.md
**Status:** May conflict with v1.5 priorities  
**Issue:** v2 roadmap was created assuming v1.0 → v2.0 jump, but now we have v1.5 (cloud APIs) in between  
**Action:** 
- Option A: Update to v2.5 roadmap (after v1.5 completes)
- Option B: Merge some v2 features into v1.5 (tool calling works with cloud APIs)
- Option C: Keep as-is but add disclaimer at top

**Owner:** @product-owner  
**Decision Needed:** Yes

---

#### REQUIREMENTS_V2.md
**Status:** May need re-scoping  
**Issue:** Some v2 requirements (tool calling, comparison) should work with cloud APIs too  
**Action:**
- Review each requirement
- Mark which apply to cloud APIs
- Update acceptance criteria to include cloud providers

**Owner:** @product-owner  
**Estimate:** 2-3 hours

---

#### USER_STORIES_V2.md
**Status:** May need cloud API extensions  
**Issue:** User stories written for Ollama-only context  
**Action:**
- Review each story
- Add cloud API variations where applicable
- Example: "As a user, I want web search to work with GPT-4 and Claude"

**Owner:** @product-owner  
**Estimate:** 2-3 hours

---

## 📁 Documents That Are Still Valid (No Changes Needed)

### v1.0 Baseline
- ✅ [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md) - v1.0 MVP scope (baseline)
- ✅ [ARCHITECTURE_LOCAL_REMOTE_MODEL_SYSTEM.md](ARCHITECTURE_LOCAL_REMOTE_MODEL_SYSTEM.md) - Local + Ollama architecture
- ✅ [QUICK_REFERENCE_LOCAL_REMOTE_SYSTEM.md](QUICK_REFERENCE_LOCAL_REMOTE_SYSTEM.md) - Still accurate for local + Ollama
- ✅ [LOCAL_REMOTE_MODEL_SYSTEM_INDEX.md](LOCAL_REMOTE_MODEL_SYSTEM_INDEX.md) - Index still valid
- ✅ [USER_GUIDE_LOCAL_REMOTE_MODELS.md](USER_GUIDE_LOCAL_REMOTE_MODELS.md) - User guide for local + Ollama

### Technical Feasibility
- ✅ [TECHNICAL_FEASIBILITY.md](TECHNICAL_FEASIBILITY.md) - Still valid, cloud APIs don't change this
- ✅ [FEASIBILITY_V2.md](FEASIBILITY_V2.md) - v2 feasibility analysis still valid

### Implementation Summaries (Audit Trail)
- ✅ All files in [../audit/](../audit/) - Historical record, don't modify

### AI Guides
- ✅ [AI_BEGINNER_GUIDE.md](AI_BEGINNER_GUIDE.md)
- ✅ [AI_INTERMEDIATE_GUIDE.md](AI_INTERMEDIATE_GUIDE.md)
- ✅ [AI_ADVANCED_GUIDE.md](AI_ADVANCED_GUIDE.md)
- ✅ [AI_PROMPT_TEMPLATES.md](AI_PROMPT_TEMPLATES.md)

These can be updated later to include cloud API examples, but not blocking.

---

## 🎯 Recommended Update Order

### Week 1: Critical Path (Before Implementation Starts)
1. ✅ PRODUCT_VISION.md (DONE)
2. ✅ PRODUCT_REQUIREMENTS_V1.5.md (DONE)
3. ✅ ARCHITECTURE_CLOUD_API_INTEGRATION.md (DONE)
4. ✅ STRATEGIC_REFOCUS_V1.5.md (DONE)
5. ✅ README.md (DONE)
6. 🔄 ARCHITECTURE_DECISIONS.md (ADRs for cloud APIs)
7. 🔄 USER_STORIES_V1.5.md (Cloud API user stories)

### Week 2-3: Development Support (During Implementation)
8. UX_DESIGN_CLOUD_API.md (New file with mockups)
9. USER_PERSONAS.md (Update with cloud users)
10. GETTING_STARTED.md (Add cloud setup paths)

### Week 4-6: Polish & Consistency (Before Release)
11. PRODUCT_ROADMAP_V2.md (Review for conflicts)
12. REQUIREMENTS_V2.md (Update for cloud APIs)
13. USER_STORIES_V2.md (Extend for cloud APIs)
14. APP_CUSTOMIZATION.md (Update references)
15. CONTRIBUTING.md (Add cloud API testing)

---

## 📊 Document Status Matrix

| Document | Status | Priority | Owner | Estimate |
|----------|--------|----------|-------|----------|
| PRODUCT_VISION.md | ✅ Done | P0 | @product-owner | - |
| PRODUCT_REQUIREMENTS_V1.5.md | ✅ Done | P0 | @product-owner | - |
| ARCHITECTURE_CLOUD_API_INTEGRATION.md | ✅ Done | P0 | @architect | - |
| STRATEGIC_REFOCUS_V1.5.md | ✅ Done | P0 | @product-owner | - |
| README.md | ✅ Done | P0 | @doc-writer | - |
| ARCHITECTURE_DECISIONS.md | 🔄 Todo | P0 | @architect | 3-4h |
| USER_STORIES_V1.5.md | 🔄 Todo | P0 | @product-owner | 3-4h |
| UX_DESIGN_CLOUD_API.md | 🔄 Todo | P1 | @experience-designer | 4-6h |
| USER_PERSONAS.md | 🔄 Todo | P1 | @product-owner | 2-3h |
| GETTING_STARTED.md | 🔄 Todo | P1 | @doc-writer | 2-3h |
| PRODUCT_ROADMAP_V2.md | ⚠️ Review | P2 | @product-owner | 2-3h |
| REQUIREMENTS_V2.md | ⚠️ Review | P2 | @product-owner | 2-3h |
| USER_STORIES_V2.md | ⚠️ Review | P2 | @product-owner | 2-3h |
| APP_CUSTOMIZATION.md | 🔄 Todo | P2 | @doc-writer | 1-2h |
| CONTRIBUTING.md | 🔄 Todo | P2 | @doc-writer | 1-2h |

**Legend:**
- ✅ Done: Fully updated for v1.5
- 🔄 Todo: Needs updates, priority assigned
- ⚠️ Review: Needs review for conflicts
- ✓ Valid: No changes needed

---

## 🚀 Getting Started for Agents

### For @architect
**Start here:**
1. Read [ARCHITECTURE_CLOUD_API_INTEGRATION.md](ARCHITECTURE_CLOUD_API_INTEGRATION.md)
2. Update [ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md) with ADRs
3. Review [ARCHITECTURE_LOCAL_REMOTE_MODEL_SYSTEM.md](ARCHITECTURE_LOCAL_REMOTE_MODEL_SYSTEM.md) for baseline
4. Begin provider abstraction implementation

### For @product-owner
**Start here:**
1. Read [PRODUCT_VISION.md](PRODUCT_VISION.md)
2. Create [USER_STORIES_V1.5.md](USER_STORIES_V1.5.md)
3. Update [USER_PERSONAS.md](USER_PERSONAS.md)
4. Review v2 documents for conflicts

### For @experience-designer
**Start here:**
1. Read [PRODUCT_VISION.md](PRODUCT_VISION.md)
2. Read [PRODUCT_REQUIREMENTS_V1.5.md](PRODUCT_REQUIREMENTS_V1.5.md)
3. Create [UX_DESIGN_CLOUD_API.md](UX_DESIGN_CLOUD_API.md)
4. Update [UX_DESIGN_LOCAL_REMOTE_MODEL_SYSTEM.md](UX_DESIGN_LOCAL_REMOTE_MODEL_SYSTEM.md) or create new file

### For @doc-writer
**Start here:**
1. Read [STRATEGIC_REFOCUS_V1.5.md](STRATEGIC_REFOCUS_V1.5.md)
2. Update [GETTING_STARTED.md](../GETTING_STARTED.md)
3. Update [APP_CUSTOMIZATION.md](../APP_CUSTOMIZATION.md)
4. Update [CONTRIBUTING.md](../CONTRIBUTING.md)

### For @flutter-developer
**Start here:**
1. Read [ARCHITECTURE_CLOUD_API_INTEGRATION.md](ARCHITECTURE_CLOUD_API_INTEGRATION.md)
2. Review [STRATEGIC_REFOCUS_V1.5.md](STRATEGIC_REFOCUS_V1.5.md) for key patterns
3. Begin provider abstraction implementation
4. Reference existing [ARCHITECTURE_LOCAL_REMOTE_MODEL_SYSTEM.md](ARCHITECTURE_LOCAL_REMOTE_MODEL_SYSTEM.md)

---

## 📝 Notes for Future Maintainers

### Documentation Philosophy
- **Product Vision** is the source of truth for strategy
- **Requirements** define what we build
- **Architecture** defines how we build it
- **User Stories** define acceptance criteria
- **UX Design** defines the user experience

### When Adding New Providers
1. Update PRODUCT_VISION.md (roadmap section)
2. Add requirements to PRODUCT_REQUIREMENTS_V1.5.md
3. Add architecture to ARCHITECTURE_CLOUD_API_INTEGRATION.md
4. Create user stories in USER_STORIES_V1.5.md
5. Update UX_DESIGN_CLOUD_API.md with UI changes
6. Update README.md feature list

### Versioning Strategy
- v1.0 = Local + Ollama (baseline)
- v1.5 = + Cloud APIs (current refocus)
- v2.0 = + Tool calling, comparison, native integration
- v2.5 = + Organization, advanced features
- v3.0 = + Desktop, enterprise

---

**Last Updated:** January 26, 2026  
**Maintained By:** @product-owner

**Questions?** Reference [STRATEGIC_REFOCUS_V1.5.md](STRATEGIC_REFOCUS_V1.5.md)
