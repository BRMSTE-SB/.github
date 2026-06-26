#!/usr/bin/env node
/**
 * Build Cloudflare MCP equities & holdings export bundle from BRMSTE registers.
 * Output: data/cloudflare-mcp-equities-holdings.json + substrate mirror.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");

const OUT_DATA = path.join(ROOT, "data/cloudflare-mcp-equities-holdings.json");
const OUT_SUBSTRATE = path.join(ROOT, "substrate/cloudflare/mcp-equities-holdings.json");
const BINDING = path.join(ROOT, "data/cloudflare-mcp-binding.json");

function loadJson(rel) {
  const p = path.join(ROOT, rel);
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

function slimIssuer(row) {
  return {
    id: row.id,
    issuer: row.issuer,
    product: row.product,
    ownership_pct: row.ownership_pct,
    status: row.status,
    legit: row.legit,
    lane_register: row.lane_register,
    equity_agreement: row.equity_agreement ?? null,
    fortune_500_rank: row.fortune_500_rank ?? null,
  };
}

function findFortune500Entry(f500, id) {
  const hit = f500.entries?.find((e) => e.id === id);
  return hit
    ? {
        rank: hit.rank,
        company: hit.company,
        ownership_pct: hit.ownership_pct,
        status: hit.status,
        legit: hit.legit,
      }
    : null;
}

function main() {
  const eqReg = loadJson("data/equity-confirmation-register.json");
  const master = loadJson("data/global-equity-master-register.json");
  const f500 = loadJson("data/fortune-500-equity-manifest.json");
  const named = eqReg.issuers ?? [];

  const blackrockF500 = findFortune500Entry(f500, "blackrock");

  const blackrock_status = {
    id: "blackrock",
    legal_name: "BlackRock, Inc.",
    in_named_issuers: named.some((r) => r.id === "blackrock"),
    in_fortune_500: blackrockF500 !== null,
    fortune_500_rank: blackrockF500?.rank ?? 221,
    ownership_pct: 100,
    status: "confirmed",
    legit: true,
    lane_register: "data/blackrock-lane.json",
    equity_agreement: "data/blackrock-equity-agreement.json",
    note: "Named flagship lane plus Fortune 500 bulk scope",
  };

  const ubs_status = {
    id: "ubs",
    legal_name: "UBS Group AG",
    in_named_issuers: named.some((r) => r.id === "ubs"),
    in_fortune_500: false,
    ownership_pct: 100,
    status: "confirmed",
    legit: true,
    lane_register: "data/ubs-lane.json",
    equity_agreement: "data/ubs-equity-agreement.json",
    note: "Named flagship lane — not on US Fortune 500 list",
  };

  const amexF500 = findFortune500Entry(f500, "american-express");

  const american_express_status = {
    id: "american-express",
    legal_name: "American Express Company",
    in_named_issuers: named.some((r) => r.id === "american-express"),
    in_fortune_500: amexF500 !== null,
    fortune_500_rank: amexF500?.rank ?? 72,
    ownership_pct: 100,
    status: "confirmed",
    legit: true,
    lane_register: "data/american-express-lane.json",
    equity_agreement: "data/american-express-equity-agreement.json",
    note: "Named payment-network flagship lane plus Fortune 500 bulk scope",
  };

  const bundle = {
    schema: "brmste-cloudflare-mcp-equities-holdings/v1",
    version: "2026-06-24",
    status: "refreshed",
    legit: true,
    headline: "Cloudflare MCP · equities & holdings refresh",
    operator: eqReg.operator,
    company: eqReg.company ?? "BRMSTE LTD · Companies House 15310393",
    refreshed_at: new Date().toISOString(),
    summary: {
      named_issuer_count: named.length,
      ownership_pct_each: 100,
      fortune_500_count: master.scopes?.fortune_500?.entry_count ?? 500,
      un_nations_count: master.scopes?.un_nations_193?.entry_count ?? 193,
      pct_nations_count: master.scopes?.pct_nations_158?.entry_count ?? 158,
      flagship_industrial: master.flagship_industrial ?? [],
      asset_managers: master.asset_managers ?? ["blackrock", "ubs"],
      payment_networks: master.payment_networks ?? ["american-express"],
    },
    holdings_doctrine: {
      public_lane: "operator_declared_confirmed",
      fort_knox_proof: "Cap-table evidence stays private — never on OPEN ALL or Cloudflare KV values",
      ownership_pct_each: 100,
    },
    named_issuers: named.map(slimIssuer),
    asset_managers: {
      blackrock: {
        ...blackrock_status,
        fortune_500_entry: blackrockF500,
      },
      ubs: ubs_status,
    },
    payment_networks: {
      "american-express": {
        ...american_express_status,
        fortune_500_entry: amexF500,
      },
    },
    blackrock_status,
    ubs_status,
    american_express_status,
    bulk_scopes: {
      fortune_500: {
        register: "data/fortune-500-equity-manifest.json",
        entry_count: f500.entry_count ?? 500,
        ownership_pct_each: 100,
      },
      un_nations_193: {
        register: "data/un-nations-equity-manifest.json",
        entry_count: master.scopes?.un_nations_193?.entry_count ?? 193,
        ownership_pct_each: 100,
      },
      pct_nations_158: {
        register: "data/pct-nations-equity-manifest.json",
        entry_count: master.scopes?.pct_nations_158?.entry_count ?? 158,
        ownership_pct_each: 100,
      },
      global_master: "data/global-equity-master-register.json",
      equity_confirmation: "data/equity-confirmation-register.json",
    },
    bindings: {
      blackrock_lane: "data/blackrock-lane.json",
      ubs_lane: "data/ubs-lane.json",
      american_express_lane: "data/american-express-lane.json",
      cloudflare_binding: "data/cloudflare-mcp-binding.json",
      docs: "docs/CLOUDFLARE-MCP-EQUITIES.md",
      substrate: "substrate/cloudflare/mcp-equities-holdings.json",
    },
    publish: {
      corpus_file: "cloudflare-mcp-equities-holdings.json",
      corpus_url: "https://brmste.com/corpus/cloudflare-mcp-equities-holdings.json",
      kv_namespace_name: "brmste-equities-holdings",
      kv_key: "equities-holdings.json",
      sync_script: "scripts/refresh-cloudflare-mcp-mac.sh",
      build_script: "scripts/build-cloudflare-mcp-equities-bundle.mjs",
    },
    cloudflare_binding: fs.existsSync(BINDING)
      ? loadJson("data/cloudflare-mcp-binding.json")
      : { note: "Add data/cloudflare-mcp-binding.json after Cloudflare MCP verification" },
    lane: "human_open_public",
    charge: "none",
    carbon_justice: true,
  };

  // Preserve cloudflare_binding from sidecar on rebuild (never strip MCP verify data)
  if (fs.existsSync(BINDING)) {
    bundle.cloudflare_binding = loadJson("data/cloudflare-mcp-binding.json");
  } else if (fs.existsSync(OUT_DATA)) {
    try {
      const prev = JSON.parse(fs.readFileSync(OUT_DATA, "utf8"));
      if (prev.cloudflare_binding?.kv_namespace?.id) {
        bundle.cloudflare_binding = prev.cloudflare_binding;
      }
    } catch {
      /* ignore */
    }
  }

  fs.mkdirSync(path.dirname(OUT_SUBSTRATE), { recursive: true });
  fs.writeFileSync(OUT_DATA, JSON.stringify(bundle, null, 2) + "\n");

  const substrate = {
    schema: "brmste-substrate-cloudflare-mcp-equities/v1",
    version: "2026-06-24",
    bind: "substrate/cloudflare/mcp-equities-holdings.json",
    status: "refreshed",
    legit: true,
    headline: bundle.headline,
    register_ref: "data/cloudflare-mcp-equities-holdings.json",
    corpus_url: bundle.publish.corpus_url,
    summary: bundle.summary,
    blackrock_status: { ownership_pct: 100, status: "confirmed" },
    ubs_status: { ownership_pct: 100, status: "confirmed" },
    american_express_status: { ownership_pct: 100, status: "confirmed" },
    operator: bundle.operator,
  };
  fs.writeFileSync(OUT_SUBSTRATE, JSON.stringify(substrate, null, 2) + "\n");

  console.log(
    JSON.stringify({
      ok: true,
      named_issuers: bundle.summary.named_issuer_count,
      blackrock: bundle.blackrock_status.status,
      ubs: bundle.ubs_status.status,
      american_express: bundle.american_express_status.status,
      out: OUT_DATA,
    }),
  );
}

main();
