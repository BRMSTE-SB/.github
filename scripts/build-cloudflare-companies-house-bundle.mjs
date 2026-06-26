#!/usr/bin/env node
/**
 * Build public Companies House live filing status bundle for Cloudflare KV + Worker.
 * Output: data/cloudflare-companies-house-live.json + substrate mirror.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");

const OUT_DATA = path.join(ROOT, "data/cloudflare-companies-house-live.json");
const OUT_SUBSTRATE = path.join(ROOT, "substrate/cloudflare/companies-house-live.json");
const BINDING = path.join(ROOT, "data/cloudflare-mcp-binding.json");
const CH_CONFIG = path.join(ROOT, "data/companies-house-api-config.json");
const LIVE_EP = path.join(ROOT, "data/brmste-live-companies-house-endpoints.json");

function loadJson(p) {
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

function slimTarget(target, regPath) {
  let filing = null;
  if (regPath && fs.existsSync(path.join(ROOT, regPath))) {
    const reg = loadJson(path.join(ROOT, regPath));
    filing = {
      status: reg.status ?? reg.filing?.status,
      channel: reg.filing?.channel,
      filed_at: reg.filing?.filed_at,
      company_number: target.company_number,
      legal_name: target.legal_name,
    };
  }
  return {
    id: target.id,
    legal_name: target.legal_name,
    company_number: target.company_number,
    filing_register: regPath,
    filing,
  };
}

function main() {
  const chCfg = loadJson(CH_CONFIG);
  const liveEp = loadJson(LIVE_EP);
  const binding = fs.existsSync(BINDING) ? loadJson(BINDING) : {};
  const brmsteReg = loadJson(path.join(ROOT, "data/brmste-ltd-companies-house-register.json"));

  const targets = Object.values(chCfg.targets ?? {}).map((t) =>
    slimTarget(t, t.filing_register ?? t.address_register)
  );

  const sweepKv = binding.related_kv_namespaces?.find((n) => n.title === "BRMSTE-SWEEP-LOG");

  const bundle = {
    schema: "brmste-cloudflare-companies-house-live/v1",
    version: "2026-06-26",
    status: "live",
    legit: true,
    headline: "Cloudflare Worker · Companies House live filings + streaming",
    operator: "Dr. Shravan Bansal · BRMSTE LTD",
    company: "BRMSTE LTD · Companies House 15310393",
    refreshed_at: new Date().toISOString(),
    watch_company_numbers: liveEp.watch_company_numbers ?? [],
    streaming_streams: (liveEp.streaming?.streams ?? []).map((s) => ({
      id: s.id,
      path: s.path,
      description: s.description,
    })),
    targets,
    brmste: {
      company_number: "15310393",
      register_status: brmsteReg.status,
      registered_office: {
        status: brmsteReg.registered_office?.status,
        display: brmsteReg.registered_office?.address?.display,
        postal_code: brmsteReg.registered_office?.address?.postal_code,
        matches_canonical: brmsteReg.registered_office?.matches_canonical,
      },
      horseferry_correspondence: {
        display: brmsteReg.horseferry_correspondence?.address?.display,
        postal_code: brmsteReg.horseferry_correspondence?.address?.postal_code,
        psc_status: brmsteReg.psc?.correspondence_address?.status,
        director_status: brmsteReg.director?.correspondence_address?.status,
      },
      roa_canonical: brmsteReg.registered_office?.address ?? brmsteReg.canonical_address,
      filing: brmsteReg.filing,
      companies_house_url: brmsteReg.company_profile?.companies_house_url,
    },
    worker: {
      name: "brmste-companies-house-live",
      package: "workers/companies-house-live",
      routes: [
        "https://brmste.com/api/ch/*",
        "https://www.brmste.com/api/ch/*",
      ],
      oauth_callback: "https://brmste.com/api/ch/oauth/callback",
      cron: "*/15 * * * *",
    },
    publish: {
      kv_namespace_title: sweepKv?.title ?? "BRMSTE-SWEEP-LOG",
      kv_namespace_id: sweepKv?.id ?? "a15701faf5ab42f78e5974d6f437912f",
      kv_key: "companies-house-live.json",
      kv_key_oauth: "ch:oauth",
      kv_key_stream_timepoint_prefix: "ch:stream:",
      build_script: "scripts/build-cloudflare-companies-house-bundle.mjs",
      refresh_script: "scripts/refresh-cloudflare-companies-house-mac.sh",
      deploy_script: "scripts/deploy-companies-house-worker-mac.sh",
    },
    bindings: {
      companies_house_api_config: "data/companies-house-api-config.json",
      live_endpoints: "data/brmste-live-companies-house-endpoints.json",
      brmste_register: "data/brmste-ltd-companies-house-register.json",
      cloudflare_binding: "data/cloudflare-mcp-binding.json",
      docs: "docs/CLOUDFLARE-COMPANIES-HOUSE-LIVE.md",
      substrate: "substrate/cloudflare/companies-house-live.json",
    },
    cloudflare_binding: binding,
    lane: "human_open_public",
    charge: "none",
    carbon_justice: true,
  };

  fs.writeFileSync(OUT_DATA, JSON.stringify(bundle, null, 2) + "\n");
  const substrate = {
    schema: "brmste-substrate-cloudflare-companies-house-live/v1",
    bind: "substrate/cloudflare/companies-house-live.json",
    register_ref: "data/cloudflare-companies-house-live.json",
    corpus_url: "https://brmste.com/corpus/cloudflare-companies-house-live.json",
    worker_name: bundle.worker.name,
    refreshed_at: bundle.refreshed_at,
  };
  fs.mkdirSync(path.dirname(OUT_SUBSTRATE), { recursive: true });
  fs.writeFileSync(OUT_SUBSTRATE, JSON.stringify(substrate, null, 2) + "\n");
  console.log(`written ${OUT_DATA}`);
  console.log(`written ${OUT_SUBSTRATE}`);
  console.log(`targets=${targets.length} watch=${bundle.watch_company_numbers.length}`);
}

main();
