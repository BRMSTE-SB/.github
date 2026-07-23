import { cloudflareTest } from "@cloudflare/vitest-pool-workers";
import { defineConfig } from "vitest/config";

// Runs the test suite INSIDE the Cloudflare Workers runtime (workerd) — the
// same runtime the Worker is deployed to — using the bindings from wrangler.toml.
export default defineConfig({
  plugins: [
    cloudflareTest({
      wrangler: { configPath: "./wrangler.toml" },
    }),
  ],
});
