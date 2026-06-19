import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

/**
 * Re-Tyre circular tyre economy — Convex database schema.
 *
 * Core entities:
 *   users        — platform participants (customers, drivers, admins)
 *   tyreJobs     — collection / delivery / retreading work orders
 *   auditLog     — immutable ledger of state transitions
 */
export default defineSchema({
  // ──────────────────────────────────────────────────────────────
  // users
  // ──────────────────────────────────────────────────────────────
  users: defineTable({
    tokenIdentifier: v.string(),
    email: v.string(),
    name: v.string(),
    role: v.union(
      v.literal("customer"),
      v.literal("driver"),
      v.literal("admin")
    ),
    phone: v.optional(v.string()),
    createdAt: v.number(),
  })
    .index("by_token", ["tokenIdentifier"])
    .index("by_email", ["email"])
    .index("by_role", ["role"]),

  // ──────────────────────────────────────────────────────────────
  // tyreJobs
  // ──────────────────────────────────────────────────────────────
  tyreJobs: defineTable({
    customerId: v.id("users"),
    driverId: v.optional(v.id("users")),
    status: v.union(
      v.literal("pending"),
      v.literal("assigned"),
      v.literal("in_transit"),
      v.literal("at_facility"),
      v.literal("completed"),
      v.literal("cancelled")
    ),
    tyreCount: v.number(),
    tyreCondition: v.union(
      v.literal("end_of_life"),
      v.literal("retreading_candidate"),
      v.literal("reusable")
    ),
    pickupAddress: v.string(),
    pickupLat: v.optional(v.number()),
    pickupLng: v.optional(v.number()),
    notes: v.optional(v.string()),
    scheduledAt: v.optional(v.number()),
    completedAt: v.optional(v.number()),
    carbonCreditEstimate: v.optional(v.number()),
    createdAt: v.number(),
  })
    .index("by_customer", ["customerId"])
    .index("by_driver", ["driverId"])
    .index("by_status", ["status"])
    .index("by_customer_and_status", ["customerId", "status"])
    .index("by_driver_and_status", ["driverId", "status"]),

  // ──────────────────────────────────────────────────────────────
  // auditLog  — append-only ledger of job state changes
  // ──────────────────────────────────────────────────────────────
  auditLog: defineTable({
    jobId: v.id("tyreJobs"),
    actorId: v.id("users"),
    fromStatus: v.optional(v.string()),
    toStatus: v.string(),
    note: v.optional(v.string()),
    timestamp: v.number(),
  })
    .index("by_job", ["jobId"])
    .index("by_actor", ["actorId"]),
});
