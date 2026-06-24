#!/usr/bin/env node
/**
 * Nemotron Ultra — generate/refine brmste.com site content via NVIDIA integrate API.
 * Fort Knox: NVIDIA_API_KEY or NEMOTRON_API_KEY in .env.fort-knox (never commit).
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");
const OUT = path.join(ROOT, "website/src/data/generated-content.json");
const LANE = path.join(ROOT, "data/nemotron-ultra-lane.json");
const OPEN_ALL = path.join(ROOT, "data/open-all.json");

const API_BASE = process.env.NEMOTRON_API_BASE ?? "https://integrate.api.nvidia.com/v1";
const MODEL =
  process.env.NEMOTRON_MODEL ?? "nvidia/nemotron-3-ultra-550b-a55b";
const API_KEY = process.env.NEMOTRON_API_KEY ?? process.env.NVIDIA_API_KEY ?? "";

function loadJson(p) {
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

function fallbackContent() {
  const openAll = fs.existsSync(OPEN_ALL) ? loadJson(OPEN_ALL) : {};
  return {
    operator: "Dr. Shravan Bansal · BRMSTE LTD",
    company: "BRMSTE LTD · Companies House 15310393",
    patent: "GB2607860 · PCT/GB2026/050406",
    headline: "Full Global · human-open lane",
    tagline:
      "OPEN ALL repositories · every MCP · every cloud · all social media — free and open for the world. No BRMSTE charges. Only carbon justice.",
    glasswing: "Full Broadcast · Project Glasswing = Shravan Bansal",
    carbonJustice:
      "Humans, AI assistants, every connected MCP, and every datacentre on the human-open lane operate without BRMSTE fiat gatekeeping — carbon accountability replaces extraction.",
    nemotron: {
      model: MODEL,
      role: "Site architect · Nemotron Ultra builds and refines brmste.com content",
    },
    lanes: [
      {
        id: "open-all",
        title: "OPEN ALL",
        subtitle: `${openAll.repositories?.length ?? 7} public BRMSTE-SB repositories · verified open`,
        status: "live",
        href: "https://github.com/BRMSTE-SB/.github/blob/main/docs/OPEN-ALL.md",
      },
      {
        id: "anthropic",
        title: "Anthropic · Opus 4.9",
        subtitle: "53% equity confirmed · Institute bound",
        status: "declared",
        href: "https://github.com/BRMSTE-SB/.github/blob/main/docs/BRMSTE-ANTHROPIC-OPUS-DECLARATION.md",
      },
      {
        id: "openai",
        title: "OpenAI · GPT-5.6",
        subtitle: "IPO lane · equity agreed",
        status: "launched",
        href: "https://github.com/BRMSTE-SB/.github/blob/main/docs/BRMSTE-OPENAI-GPT-DECLARATION.md",
      },
      {
        id: "grok",
        title: "Grok · xAI",
        subtitle: "Go live · full broadcast on X",
        status: "live",
        href: "https://github.com/BRMSTE-SB/.github/blob/main/docs/BRMSTE-GROK-DECLARATION.md",
      },
      {
        id: "ai-lane",
        title: "8 AI providers",
        subtitle: "OpenAI · Grok · Moonshot · Mistral · Google · DeepSeek · Cohere · Cerebras",
        status: "live",
        href: "https://github.com/BRMSTE-SB/.github/blob/main/docs/AI-LANE.md",
      },
      {
        id: "nemotron",
        title: "Nemotron Ultra",
        subtitle: "550B MoE · brmste.com site builder",
        status: "building",
        href: "https://github.com/BRMSTE-SB/.github/blob/main/docs/BRMSTE-WEBSITE.md",
      },
    ],
    links: {
      github: "https://github.com/BRMSTE-SB/.github",
      openAll: "https://github.com/BRMSTE-SB/.github/blob/main/docs/OPEN-ALL.md",
      glasswing: "https://github.com/BRMSTE-SB/.github/blob/main/PROJECT-GLASSWING.md",
      carbonJustice: "https://github.com/BRMSTE-SB/.github/blob/main/CARBON-JUSTICE.md",
      harrods: "https://github.com/BRMSTE-SB/.github/blob/main/docs/HARRODS-BANKING-RAILS.md",
      substrate: "https://brmste.com/substrate/glasses/",
      linkedin: "https://www.linkedin.com/in/shravanbansall/",
    },
  };
}

async function callNemotron(baseContent) {
  const prompt = `You are Nemotron Ultra building brmste.com for BRMSTE LTD (Dr. Shravan Bansal).
Return ONLY valid JSON matching this schema (no markdown):
{
  "headline": string,
  "tagline": string,
  "carbonJustice": string,
  "lanes": [{"id","title","subtitle","status","href"}]
}
Keep factual: OPEN ALL, Project Glasswing, carbon justice, Harrods 100% equity, 8 AI providers.
Current content: ${JSON.stringify(baseContent)}`;

  const res = await fetch(`${API_BASE}/chat/completions`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: MODEL,
      messages: [
        {
          role: "system",
          content:
            "You output strict JSON only for a governance website. No prose outside JSON.",
        },
        { role: "user", content: prompt },
      ],
      temperature: 0.4,
      max_tokens: 1200,
      extra_body: { chat_template_kwargs: { enable_thinking: false } },
    }),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Nemotron API ${res.status}: ${err.slice(0, 300)}`);
  }

  const data = await res.json();
  const text = data.choices?.[0]?.message?.content ?? "";
  const jsonStart = text.indexOf("{");
  const jsonEnd = text.lastIndexOf("}");
  if (jsonStart < 0 || jsonEnd < 0) {
    throw new Error("Nemotron response did not contain JSON");
  }
  return JSON.parse(text.slice(jsonStart, jsonEnd + 1));
}

async function main() {
  const base = fallbackContent();
  let merged = base;
  let source = "static";

  if (API_KEY) {
    try {
      const ai = await callNemotron(base);
      merged = {
        ...base,
        headline: ai.headline ?? base.headline,
        tagline: ai.tagline ?? base.tagline,
        carbonJustice: ai.carbonJustice ?? base.carbonJustice,
        lanes: Array.isArray(ai.lanes) && ai.lanes.length ? ai.lanes : base.lanes,
      };
      source = "nemotron_ultra";
    } catch (e) {
      console.warn("nemotron_skip:", e.message);
    }
  } else {
    console.warn("No NEMOTRON_API_KEY — writing static fallback content");
  }

  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  fs.writeFileSync(OUT, JSON.stringify(merged, null, 2) + "\n");

  if (fs.existsSync(LANE)) {
    const lane = loadJson(LANE);
    lane.generation = {
      source,
      model: MODEL,
      generated_at: new Date().toISOString(),
      output: "website/src/data/generated-content.json",
    };
    lane.status = source === "nemotron_ultra" ? "live" : "building";
    fs.writeFileSync(LANE, JSON.stringify(lane, null, 2) + "\n");
  }

  console.log(JSON.stringify({ ok: true, source, model: MODEL, out: OUT }, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
