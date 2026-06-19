import { internalMutation, mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { getCurrentUser } from "./lib/auth";
import { Doc, Id } from "./_generated/dataModel";

// ──────────────────────────────────────────────────────────────────────────────
// Shared types / helpers
// ──────────────────────────────────────────────────────────────────────────────

const jobStatusValidator = v.union(
  v.literal("pending"),
  v.literal("assigned"),
  v.literal("in_transit"),
  v.literal("at_facility"),
  v.literal("completed"),
  v.literal("cancelled")
);

const tyreConditionValidator = v.union(
  v.literal("end_of_life"),
  v.literal("retreading_candidate"),
  v.literal("reusable")
);

const jobOutputObject = v.object({
  _id: v.id("tyreJobs"),
  _creationTime: v.number(),
  customerId: v.id("users"),
  driverId: v.optional(v.id("users")),
  status: jobStatusValidator,
  tyreCount: v.number(),
  tyreCondition: tyreConditionValidator,
  pickupAddress: v.string(),
  pickupLat: v.optional(v.number()),
  pickupLng: v.optional(v.number()),
  notes: v.optional(v.string()),
  scheduledAt: v.optional(v.number()),
  completedAt: v.optional(v.number()),
  carbonCreditEstimate: v.optional(v.number()),
  createdAt: v.number(),
});

async function appendAuditEntry(
  ctx: Parameters<typeof getCurrentUser>[0] & {
    db: { insert: (...args: unknown[]) => Promise<unknown> };
  },
  jobId: Id<"tyreJobs">,
  actorId: Id<"users">,
  toStatus: string,
  fromStatus?: string,
  note?: string
) {
  await ctx.db.insert("auditLog", {
    jobId,
    actorId,
    fromStatus,
    toStatus,
    note,
    timestamp: Date.now(),
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// Queries
// ──────────────────────────────────────────────────────────────────────────────

/**
 * Return a single tyre job by ID.  Customers may only see their own jobs;
 * drivers see jobs assigned to them; admins see any job.
 */
export const get = query({
  args: { jobId: v.id("tyreJobs") },
  returns: v.union(jobOutputObject, v.null()),
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);
    const job = await ctx.db.get(args.jobId);
    if (!job) return null;

    if (user.role === "admin") return job;
    if (user.role === "customer" && job.customerId === user._id) return job;
    if (user.role === "driver" && job.driverId === user._id) return job;

    throw new Error("Unauthorized: you do not have access to this job");
  },
});

/**
 * List the current user's jobs, optionally filtered by status.
 */
export const listMine = query({
  args: {
    status: v.optional(jobStatusValidator),
  },
  returns: v.array(jobOutputObject),
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);

    if (user.role === "customer") {
      if (args.status) {
        return ctx.db
          .query("tyreJobs")
          .withIndex("by_customer_and_status", (q) =>
            q.eq("customerId", user._id).eq("status", args.status!)
          )
          .collect();
      }
      return ctx.db
        .query("tyreJobs")
        .withIndex("by_customer", (q) => q.eq("customerId", user._id))
        .collect();
    }

    if (user.role === "driver") {
      if (args.status) {
        return ctx.db
          .query("tyreJobs")
          .withIndex("by_driver_and_status", (q) =>
            q.eq("driverId", user._id).eq("status", args.status!)
          )
          .collect();
      }
      return ctx.db
        .query("tyreJobs")
        .withIndex("by_driver", (q) => q.eq("driverId", user._id))
        .collect();
    }

    // admins fall through to the admin-specific query
    throw new Error("Admins should use listAll");
  },
});

/**
 * Admin-only: list all jobs with an optional status filter.
 */
export const listAll = query({
  args: {
    status: v.optional(jobStatusValidator),
  },
  returns: v.array(jobOutputObject),
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);
    if (user.role !== "admin") {
      throw new Error("Unauthorized: admin access required");
    }

    if (args.status) {
      return ctx.db
        .query("tyreJobs")
        .withIndex("by_status", (q) => q.eq("status", args.status!))
        .collect();
    }
    return ctx.db.query("tyreJobs").collect();
  },
});

/**
 * Return the audit trail for a given job.
 */
export const getAuditLog = query({
  args: { jobId: v.id("tyreJobs") },
  returns: v.array(
    v.object({
      _id: v.id("auditLog"),
      _creationTime: v.number(),
      jobId: v.id("tyreJobs"),
      actorId: v.id("users"),
      fromStatus: v.optional(v.string()),
      toStatus: v.string(),
      note: v.optional(v.string()),
      timestamp: v.number(),
    })
  ),
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);

    if (user.role !== "admin") {
      const job = await ctx.db.get(args.jobId);
      if (!job) throw new Error("Job not found");
      const owned =
        (user.role === "customer" && job.customerId === user._id) ||
        (user.role === "driver" && job.driverId === user._id);
      if (!owned) throw new Error("Unauthorized");
    }

    return ctx.db
      .query("auditLog")
      .withIndex("by_job", (q) => q.eq("jobId", args.jobId))
      .collect();
  },
});

// ──────────────────────────────────────────────────────────────────────────────
// Mutations
// ──────────────────────────────────────────────────────────────────────────────

/**
 * Customer: raise a new tyre collection request.
 */
export const create = mutation({
  args: {
    tyreCount: v.number(),
    tyreCondition: tyreConditionValidator,
    pickupAddress: v.string(),
    pickupLat: v.optional(v.number()),
    pickupLng: v.optional(v.number()),
    notes: v.optional(v.string()),
    scheduledAt: v.optional(v.number()),
  },
  returns: v.id("tyreJobs"),
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);

    if (args.tyreCount < 1) {
      throw new Error("tyreCount must be at least 1");
    }
    if (args.scheduledAt !== undefined && args.scheduledAt <= Date.now()) {
      throw new Error("scheduledAt must be a future timestamp");
    }

    const jobId = await ctx.db.insert("tyreJobs", {
      customerId: user._id,
      status: "pending",
      tyreCount: args.tyreCount,
      tyreCondition: args.tyreCondition,
      pickupAddress: args.pickupAddress,
      pickupLat: args.pickupLat,
      pickupLng: args.pickupLng,
      notes: args.notes,
      scheduledAt: args.scheduledAt,
      createdAt: Date.now(),
    });

    await appendAuditEntry(ctx, jobId, user._id, "pending", undefined, "Job created");
    return jobId;
  },
});

/**
 * Admin: assign a driver to a pending job.
 */
export const assign = mutation({
  args: {
    jobId: v.id("tyreJobs"),
    driverId: v.id("users"),
  },
  returns: v.id("tyreJobs"),
  handler: async (ctx, args) => {
    const actor = await getCurrentUser(ctx);
    if (actor.role !== "admin") {
      throw new Error("Unauthorized: admin access required");
    }

    const job = await ctx.db.get(args.jobId);
    if (!job) throw new Error("Job not found");
    if (job.status !== "pending") {
      throw new Error(`Cannot assign a job with status '${job.status}'`);
    }

    const driver = await ctx.db.get(args.driverId);
    if (!driver) throw new Error("Driver not found");
    if (driver.role !== "driver") {
      throw new Error("Target user is not a driver");
    }

    await ctx.db.patch(args.jobId, {
      driverId: args.driverId,
      status: "assigned",
    });

    await appendAuditEntry(
      ctx,
      args.jobId,
      actor._id,
      "assigned",
      job.status,
      `Assigned to driver ${args.driverId}`
    );

    return args.jobId;
  },
});

/**
 * Driver: advance the job through the collection lifecycle.
 *
 * Allowed transitions:
 *   assigned   → in_transit   (driver has picked up the tyres)
 *   in_transit → at_facility  (tyres delivered to processing facility)
 *   at_facility → completed   (processing confirmed)
 */
export const advanceStatus = mutation({
  args: {
    jobId: v.id("tyreJobs"),
    note: v.optional(v.string()),
  },
  returns: v.id("tyreJobs"),
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);

    const job = await ctx.db.get(args.jobId);
    if (!job) throw new Error("Job not found");

    if (user.role === "driver" && job.driverId !== user._id) {
      throw new Error("Unauthorized: this job is not assigned to you");
    }
    if (user.role === "customer") {
      throw new Error("Unauthorized: customers cannot advance job status");
    }

    const transitions: Record<
      Doc<"tyreJobs">["status"],
      Doc<"tyreJobs">["status"] | undefined
    > = {
      pending: undefined,
      assigned: "in_transit",
      in_transit: "at_facility",
      at_facility: "completed",
      completed: undefined,
      cancelled: undefined,
    };

    const next = transitions[job.status];
    if (!next) {
      throw new Error(`Job status '${job.status}' cannot be advanced`);
    }

    const patch: Partial<Doc<"tyreJobs">> = { status: next };
    if (next === "completed") patch.completedAt = Date.now();

    await ctx.db.patch(args.jobId, patch);
    await appendAuditEntry(ctx, args.jobId, user._id, next, job.status, args.note);

    return args.jobId;
  },
});

/**
 * Customer or Admin: cancel a job that has not yet been collected.
 */
export const cancel = mutation({
  args: {
    jobId: v.id("tyreJobs"),
    reason: v.optional(v.string()),
  },
  returns: v.id("tyreJobs"),
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);

    const job = await ctx.db.get(args.jobId);
    if (!job) throw new Error("Job not found");

    if (user.role === "customer" && job.customerId !== user._id) {
      throw new Error("Unauthorized: you do not own this job");
    }

    const cancellableStatuses: Array<Doc<"tyreJobs">["status"]> = [
      "pending",
      "assigned",
    ];
    if (!cancellableStatuses.includes(job.status)) {
      throw new Error(
        `Cannot cancel a job with status '${job.status}'. Only pending or assigned jobs may be cancelled.`
      );
    }

    await ctx.db.patch(args.jobId, { status: "cancelled" });
    await appendAuditEntry(
      ctx,
      args.jobId,
      user._id,
      "cancelled",
      job.status,
      args.reason ?? "Cancelled by user"
    );

    return args.jobId;
  },
});

// ──────────────────────────────────────────────────────────────────────────────
// Internal mutations (called only from backend / scheduler)
// ──────────────────────────────────────────────────────────────────────────────

/**
 * Internal: store the carbon-credit estimate after it has been calculated
 * by an external service (called from tyreJobActions.ts).
 */
export const setCarbonCreditEstimate = internalMutation({
  args: {
    jobId: v.id("tyreJobs"),
    estimate: v.number(),
  },
  returns: v.null(),
  handler: async (ctx, args) => {
    const job = await ctx.db.get(args.jobId);
    if (!job) throw new Error("Job not found");

    await ctx.db.patch(args.jobId, {
      carbonCreditEstimate: args.estimate,
    });

    return null;
  },
});
