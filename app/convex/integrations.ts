import { query, mutation } from "./_generated/server";
import { v } from "convex/values";
import { Doc, Id } from "./_generated/dataModel";
import { getCurrentUser, requireOperator } from "./lib/auth";

const integrationValidator = v.object({
  _id: v.id("integrations"),
  _creationTime: v.number(),
  organisationId: v.id("organisations"),
  serviceId: v.id("services"),
  status: v.union(
    v.literal("active"),
    v.literal("pending"),
    v.literal("failed"),
    v.literal("paused")
  ),
  healthScore: v.number(),
  lastPingedAt: v.optional(v.number()),
  metadata: v.optional(v.string()),
  createdBy: v.id("users"),
  createdAt: v.number(),
});

export const listByOrg = query({
  args: { organisationId: v.id("organisations") },
  returns: v.array(integrationValidator),
  handler: async (ctx, args): Promise<Doc<"integrations">[]> => {
    await getCurrentUser(ctx);
    return await ctx.db
      .query("integrations")
      .withIndex("by_org", (q) => q.eq("organisationId", args.organisationId))
      .collect();
  },
});

export const listByService = query({
  args: { serviceId: v.id("services") },
  returns: v.array(integrationValidator),
  handler: async (ctx, args): Promise<Doc<"integrations">[]> => {
    await getCurrentUser(ctx);
    return await ctx.db
      .query("integrations")
      .withIndex("by_service", (q) => q.eq("serviceId", args.serviceId))
      .collect();
  },
});

export const listAll = query({
  args: {
    status: v.optional(
      v.union(
        v.literal("active"),
        v.literal("pending"),
        v.literal("failed"),
        v.literal("paused")
      )
    ),
  },
  returns: v.array(integrationValidator),
  handler: async (ctx, args): Promise<Doc<"integrations">[]> => {
    await getCurrentUser(ctx);
    if (args.status) {
      return await ctx.db
        .query("integrations")
        .withIndex("by_status", (q) => q.eq("status", args.status!))
        .collect();
    }
    return await ctx.db.query("integrations").order("desc").collect();
  },
});

export const create = mutation({
  args: {
    organisationId: v.id("organisations"),
    serviceId: v.id("services"),
    metadata: v.optional(v.string()),
  },
  returns: v.id("integrations"),
  handler: async (ctx, args): Promise<Id<"integrations">> => {
    const user = await requireOperator(ctx);

    const existing = await ctx.db
      .query("integrations")
      .withIndex("by_org_and_service", (q) =>
        q.eq("organisationId", args.organisationId).eq("serviceId", args.serviceId)
      )
      .unique();

    if (existing && existing.status !== "failed") {
      throw new Error("Integration already exists for this org + service pair");
    }

    return await ctx.db.insert("integrations", {
      organisationId: args.organisationId,
      serviceId: args.serviceId,
      status: "pending",
      healthScore: 100,
      metadata: args.metadata,
      createdBy: user._id,
      createdAt: Date.now(),
    });
  },
});

export const updateStatus = mutation({
  args: {
    id: v.id("integrations"),
    status: v.union(
      v.literal("active"),
      v.literal("pending"),
      v.literal("failed"),
      v.literal("paused")
    ),
    healthScore: v.optional(v.number()),
  },
  returns: v.null(),
  handler: async (ctx, args): Promise<null> => {
    await requireOperator(ctx);
    const patch: Partial<Pick<Doc<"integrations">, "status" | "healthScore" | "lastPingedAt">> = {
      status: args.status,
      lastPingedAt: Date.now(),
    };
    if (args.healthScore !== undefined) patch.healthScore = args.healthScore;
    await ctx.db.patch(args.id, patch);
    return null;
  },
});
