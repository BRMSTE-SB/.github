import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  // ─── Identity ────────────────────────────────────────────────────────────────
  users: defineTable({
    tokenIdentifier: v.string(),
    name: v.string(),
    email: v.string(),
    role: v.union(v.literal("admin"), v.literal("operator"), v.literal("viewer")),
  })
    .index("by_token", ["tokenIdentifier"])
    .index("by_role", ["role"]),

  // ─── Client organisations managed by OCTA ────────────────────────────────────
  organisations: defineTable({
    name: v.string(),
    slug: v.string(),        // URL-safe identifier
    sector: v.string(),      // e.g. "logistics", "energy", "circular-economy"
    status: v.union(
      v.literal("active"),
      v.literal("onboarding"),
      v.literal("suspended")
    ),
    createdBy: v.id("users"),
    createdAt: v.number(),
  })
    .index("by_slug", ["slug"])
    .index("by_status", ["status"])
    .index("by_created_by", ["createdBy"]),

  // ─── Services / capabilities OCTA provides ───────────────────────────────────
  services: defineTable({
    name: v.string(),
    code: v.string(),        // machine-readable: "retyre-logistics", "brmste-mining-pool"
    description: v.string(),
    category: v.union(
      v.literal("circular-economy"),
      v.literal("mining"),
      v.literal("carbon"),
      v.literal("logistics"),
      v.literal("ai"),
      v.literal("blockchain"),
      v.literal("other")
    ),
    status: v.union(
      v.literal("live"),
      v.literal("beta"),
      v.literal("deprecated")
    ),
    createdBy: v.id("users"),
    createdAt: v.number(),
  })
    .index("by_code", ["code"])
    .index("by_category", ["category"])
    .index("by_status", ["status"]),

  // ─── Integration instances: an org connected to a service ────────────────────
  integrations: defineTable({
    organisationId: v.id("organisations"),
    serviceId: v.id("services"),
    status: v.union(
      v.literal("active"),
      v.literal("pending"),
      v.literal("failed"),
      v.literal("paused")
    ),
    healthScore: v.number(),  // 0–100
    lastPingedAt: v.optional(v.number()),
    metadata: v.optional(v.string()),  // JSON blob for service-specific config
    createdBy: v.id("users"),
    createdAt: v.number(),
  })
    .index("by_org", ["organisationId"])
    .index("by_service", ["serviceId"])
    .index("by_org_and_service", ["organisationId", "serviceId"])
    .index("by_status", ["status"]),

  // ─── Work queue — tickets across all orgs / services ─────────────────────────
  tickets: defineTable({
    title: v.string(),
    description: v.optional(v.string()),
    priority: v.union(
      v.literal("critical"),
      v.literal("high"),
      v.literal("medium"),
      v.literal("low")
    ),
    status: v.union(
      v.literal("open"),
      v.literal("in_progress"),
      v.literal("resolved"),
      v.literal("closed")
    ),
    organisationId: v.optional(v.id("organisations")),
    serviceId: v.optional(v.id("services")),
    assigneeId: v.optional(v.id("users")),
    raisedBy: v.id("users"),
    resolvedAt: v.optional(v.number()),
    createdAt: v.number(),
  })
    .index("by_org", ["organisationId"])
    .index("by_service", ["serviceId"])
    .index("by_assignee", ["assigneeId"])
    .index("by_status", ["status"])
    .index("by_priority", ["priority"])
    .index("by_raised_by", ["raisedBy"]),
});
