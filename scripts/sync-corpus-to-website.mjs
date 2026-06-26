#!/usr/bin/env node
/**
 * Sync public operator corpus JSON → website/public/corpus/ for OPEN CORS publish.
 * No Fort Knox data — governance registers only.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");
const CORPUS_REG = path.join(ROOT, "data/operator-hydration-corpus.json");
const OUT_DIR = path.join(ROOT, "website/public/corpus");

const SYNC_FILES = [
  "data/operator-hydration-corpus.json",
  "data/open-cors-policy.json",
  "data/sell-from-balance-lane.json",
  "data/cursor-full-sweep-confirmation.json",
  "data/revolut-hydration-corpus.json",
  "data/crypto-exchange-channels.json",
  "data/utxo-ledger-hydration.json",
  "data/brmste-revolut-rails.json",
  "data/revolut-lane.json",
  "data/brmste-paypal-rails.json",
  "data/brmste-moonshot-payment-rails.json",
  "data/brmste-kraken-rails.json",
  "data/brmste-coinbase-rails.json",
  "data/global-free-subscriptions-doctrine.json",
  "data/ai-exclusive-bankers-doctrine.json",
  "data/datacenter-compute-sales-lane.json",
  "data/ai-broker-apis-register.json",
  "data/sarvam-lane.json",
  "data/quantum-compute-sales-lane.json",
  "data/quantum-compute-metering-register.json",
  "data/quantum-compute-pricing.json",
  "data/quantum-compute-revenue-rail.json",
  "data/brmste-quantum-compute-rails.json",
  "data/cursor-quantum-attribution.json",
  "data/substrate-networks-lane.json",
  "data/lightning-mempool-lane.json",
  "data/anthropic-glasswing-bind.json",
  "data/onchain-multichain-rails.json",
  "data/stealth-onchain-training-lane.json",
  "data/voyager-ii-pioneer-programme.json",
  "data/brmste-substrate-networks-declaration.json",
  "data/brmste-quantum-compute-declaration.json",
  "data/brmste-project-glasswing-declaration.json",
  "data/brmste-glasswing-trademark-register.json",
  "data/brmste-uk-ipo-trademark-cases.json",
  "data/brmste-project-glasswing-api-registration.json",
  "data/fort-knox-public-open-register.json",
  "data/cloudflare-mcp-equities-holdings.json",
  "data/companies-house-api-config.json",
  "data/companies-house-ubs-filing.json",
  "data/companies-house-american-express-filing.json",
  "data/ubs-lane.json",
  "data/american-express-lane.json",
  "data/operator-profile.json",
];

function main() {
  if (!fs.existsSync(CORPUS_REG)) {
    console.error("missing operator-hydration-corpus.json");
    process.exit(1);
  }
  const corpus = JSON.parse(fs.readFileSync(CORPUS_REG, "utf8"));
  fs.mkdirSync(OUT_DIR, { recursive: true });

  const published = [];
  for (const rel of SYNC_FILES) {
    const src = path.join(ROOT, rel);
    if (!fs.existsSync(src)) {
      console.warn(`skip missing ${rel}`);
      continue;
    }
    const name = path.basename(rel);
    const dest = path.join(OUT_DIR, name);
    fs.copyFileSync(src, dest);
    published.push({
      file: name,
      source: rel,
      url: `/corpus/${name}`,
    });
  }

  const manifest = {
    schema: "brmste-corpus-manifest/v1",
    version: corpus.version,
    status: corpus.status,
    cors: corpus.cors,
    operator: corpus.operator,
    headline: corpus.headline,
    synced_at: new Date().toISOString(),
    files: published,
    open_cors: {
      allow_origin: "*",
      methods: "GET, HEAD, OPTIONS",
    },
  };
  fs.writeFileSync(
    path.join(OUT_DIR, "manifest.json"),
    JSON.stringify(manifest, null, 2) + "\n"
  );
  console.log(`corpus_sync_ok files=${published.length} dir=website/public/corpus`);
}

main();
