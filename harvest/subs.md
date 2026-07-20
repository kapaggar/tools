# AI Subreddits — harvest target menu

Grouped by **character** (the taxonomy from the corpus work): usage-oriented subs yield reusable
techniques; discourse-oriented subs yield threat-landscape / industry signal. Each row has a
suggested harvest config for `reddit_harvest_console.js`.

**Confidence:** ✓ = well-established, expect it to exist. ~ = niche / may be renamed or low-traffic.
**Caveat:** compiled from knowledge as of Jan 2026. Subscriber counts, renames, and any subs created
after that date are unknown — verify live before a big run.

**Config legend:**
- `REL` = set `REQUIRE_RELEVANCE`. **true** on general/non-AI subs (or you drown in off-topic noise);
  **false** on already-on-topic subs (the filter just costs you posts).
- `SCORE` = suggested `MIN_SCORE` tier: **H**igh (300+) for huge subs, **M**edium (100-150) mid-size,
  **L**ow (~30) niche/low-traffic.

---

## Builder / dev / agentic  (best technique yield)
| Sub | Character | REL | SCORE |
|---|---|---|---|
| ✓ r/LocalLLaMA | Self-hosting, quantization, GPU/hardware, open models | false | M |
| ✓ r/LLMDevs | Building apps/pipelines on LLMs | false | M |
| ✓ r/AI_Agents | Agent design, orchestration, tooling | false | M |
| ✓ r/LangChain | LangChain framework | false | L |
| ✓ r/Rag | Retrieval-augmented generation | false | L |
| ~ r/LlamaIndex | RAG/data framework | false | L |
| ✓ r/AutoGPT | Autonomous agents | false | L |
| ✓ r/cursor | Cursor IDE workflows | false | M |
| ✓ r/ChatGPTCoding | AI-assisted coding, tool comparisons | false | M |
| ✓ r/GithubCopilot | Copilot in IDEs | false | M |
| ~ r/ClaudeCode | Claude Code specific (may fold into r/ClaudeAI) | false | L |
| ✓ r/ollama | Local model running via Ollama | false | L |
| ~ r/LocalLLM | Local models (overlaps r/LocalLLaMA) | false | L |
| ✓ r/vibecoding | "Vibe coding" culture + workflows | false | M |
| ~ r/OpenWebUI / r/n8n | Self-host UI / AI automation flows | false | L |

## Prompting
| Sub | Character | REL | SCORE |
|---|---|---|---|
| ✓ r/PromptEngineering | Prompt technique, systematic | false | M |
| ✓ r/ChatGPTPromptGenius | Prompt sharing (consumer) | false | M |
| ~ r/PromptDesign | Prompt craft | false | L |
| ✓ r/aipromptprogramming | Prompt + automation | false | L |

## Consumer / product  (flat, general-purpose use)
| Sub | Character | REL | SCORE |
|---|---|---|---|
| ✓ r/ChatGPT | Largest consumer sub; image-gen, life, memes | false | H |
| ✓ r/OpenAI | Product/API, more dev-leaning than r/ChatGPT | false | H |
| ✓ r/ClaudeAI | Builder/dev (you have this) | false | M |
| ~ r/Anthropic | Company/product, smaller | false | L |
| ✓ r/GeminiAI | Google Gemini use (was r/Bard) | false | M |
| ~ r/GoogleGeminiAI | Gemini variant sub | false | L |
| ✓ r/PerplexityAI | Search-native AI use | false | M |
| ✓ r/DeepSeek | DeepSeek models | false | M |
| ~ r/MistralAI | Mistral | false | L |
| ~ r/grok / r/GrokAI | xAI Grok | false | M |
| ✓ r/MicrosoftCopilot / r/copilot | MS Copilot consumer | false | M |
| ~ r/Poe_com | Poe multi-model | false | L |

## Image / audio / video generation
| Sub | Character | REL | SCORE |
|---|---|---|---|
| ✓ r/StableDiffusion | Flagship open image-gen, technical | false | H |
| ✓ r/comfyui | Node-based SD workflows | false | M |
| ✓ r/midjourney | Midjourney | false | H |
| ✓ r/civitai | Model/LoRA sharing | false | M |
| ~ r/FluxAI | Flux image models | false | L |
| ✓ r/aiArt / r/AIArtwork | AI art community | false | M |
| ~ r/DefendingAIArt / r/aiwars | Pro/anti AI-art debate (discourse) | true | M |
| ✓ r/SunoAI / r/udiomusic | AI music generation | false | M |
| ✓ r/ElevenLabs | Voice synthesis/cloning | false | L |
| ~ r/SoraAI / r/runwayml | AI video generation | false | L |

## Discourse / futurism / news  (industry signal, not how-to)
| Sub | Character | REL | SCORE |
|---|---|---|---|
| ✓ r/singularity | Futurism, frontier news (you have this) | false | H |
| ✓ r/artificial | General AI news | false | H |
| ✓ r/ArtificialInteligence | **Large despite the misspelling**; general news | false | H |
| ✓ r/ArtificialIntelligence | General AI (correct spelling) | false | M |
| ✓ r/accelerate | e/acc, pro-acceleration | true | M |
| ✓ r/AGI / r/agi | AGI speculation | true | L |
| ~ r/BetterOffline | AI-critical / skeptic (podcast community) | false | L |
| ✓ r/Futurology | Broad futurism, partly AI | true | H |

## Safety / alignment / ethics
| Sub | Character | REL | SCORE |
|---|---|---|---|
| ✓ r/ControlProblem | Alignment / x-risk | false | L |
| ~ r/AISafety | AI safety | false | L |
| ~ r/slatestarcodex | Rationalist, heavy AI content | true | M |

## Security-relevant  (your lane — REL=true is mandatory on the general ones)
| Sub | Character | REL | SCORE |
|---|---|---|---|
| ✓ r/netsec | Infosec; catch AI/prompt-injection threads | **true** | M |
| ✓ r/cybersecurity | Broad security; AI-in-secops discussion | **true** | M |
| ✓ r/AskNetsec | Practitioner Q&A | **true** | L |
| ✓ r/ChatGPTJailbreak | Jailbreak/guardrail-bypass techniques | false | M |
| ~ r/LLMSecurity | LLM security (niche, may be small/absent) | false | L |
| ✓ r/hacking / r/HowToHack | Offensive; occasional AI tooling | **true** | M |

## Skeptic / dev-culture  (the accountability counterweight)
| Sub | Character | REL | SCORE |
|---|---|---|---|
| ✓ r/ExperiencedDevs | Senior-eng skeptical take on AI adoption | **true** | M |
| ✓ r/programming | General dev; AI threads are frequent | **true** | H |
| ✓ r/devops | AI in CI/CD, ops | **true** | M |
| ✓ r/webdev | Web dev; AI-tool debates | **true** | M |
| ✓ r/SoftwareEngineering | Eng practice discourse | **true** | M |

## Companion / roleplay  (listed for completeness; low work-value, often NSFW)
| Sub | Character | REL | SCORE |
|---|---|---|---|
| ✓ r/CharacterAI | Companion/roleplay | false | H |
| ~ r/SillyTavern | Local roleplay frontend | false | M |
| ~ r/JanitorAI_Official / r/PygmalionAI | Companion models | false | L |

---

## Recommended next three for a security/infra analyst
1. **r/LocalLLaMA** — new shape (self-hosting/hardware), `REL=false`, `MIN_SCORE≈100`.
2. **r/AI_Agents** — your agent-security interest, `REL=false`, `MIN_SCORE≈100`.
3. **r/netsec** — AI-in-security threat signal, `REL=true` (mandatory), `MIN_SCORE≈100`.

## Plain list (copy-paste for looping)
LocalLLaMA, LLMDevs, AI_Agents, LangChain, Rag, AutoGPT, cursor, ChatGPTCoding, GithubCopilot,
ollama, vibecoding, PromptEngineering, ChatGPTPromptGenius, ChatGPT, OpenAI, ClaudeAI, GeminiAI,
PerplexityAI, DeepSeek, grok, MicrosoftCopilot, StableDiffusion, comfyui, midjourney, civitai,
aiArt, SunoAI, ElevenLabs, singularity, artificial, ArtificialInteligence, ArtificialIntelligence,
accelerate, AGI, Futurology, ControlProblem, AISafety, netsec, cybersecurity, AskNetsec,
ChatGPTJailbreak, hacking, ExperiencedDevs, programming, devops, webdev, SoftwareEngineering,
CharacterAI, SillyTavern
