import { query, mutation } from "./_generated/server";
import { v } from "convex/values";
import { Doc, Id } from "./_generated/dataModel";
import { getCurrentUser, requireOperator } from "./lib/auth";

const ticketValidator = v.object({
  _id: v.id("tickets"),
  _creationTime: v.number(),
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
});

export const list = query({
  args: {
    status: v.optional(
      v.union(
        v.literal("open"),
        v.literal("in_progress"),
        v.literal("resolved"),
        v.literal("closed")
      )
    ),
    priority: v.optional(
      v.union(
        v.literal("critical"),
        v.literal("high"),
        v.literal("medium"),
        v.literal("low")
      )
    ),
  },
  returns: v.array(ticketValidator),
  handler: async (ctx, args): Promise<Doc<"tickets">[]> => {
    await getCurrentUser(ctx);
    if (args.status) {
      return await ctx.db
        .query("tickets")
        .withIndex("by_status", (q) => q.eq("status", args.status!))
        .order("desc")
        .collect();
    }
    if (args.priority) {
      return await ctx.db
        .query("tickets")
        .withIndex("by_priority", (q) => q.eq("priority", args.priority!))
        .order("desc")
        .collect();
    }
    return await ctx.db.query("tickets").order("desc").collect();
  },
});

export const listMine = query({
  args: {},
  returns: v.array(ticketValidator),
  handler: async (ctx): Promise<Doc<"tickets">[]> => {
    const user = await getCurrentUser(ctx);
    return await ctx.db
      .query("tickets")
      .withIndex("by_assignee", (q) => q.eq("assigneeId", user._id))
      .order("desc")
      .collect();
  },
});

export const create = mutation({
  args: {
    title: v.string(),
    description: v.optional(v.string()),
    priority: v.union(
      v.literal("critical"),
      v.literal("high"),
      v.literal("medium"),
      v.literal("low")
    ),
    organisationId: v.optional(v.id("organisations")),
    serviceId: v.optional(v.id("services")),
    assigneeId: v.optional(v.id("users")),
  },
  returns: v.id("tickets"),
  handler: async (ctx, args): Promise<Id<"tickets">> => {
    const user = await getCurrentUser(ctx);
    return await ctx.db.insert("tickets", {
      ...args,
      status: "open",
      raisedBy: user._id,
      createdAt: Date.now(),
    });
  },
});

export const update = mutation({
  args: {
    id: v.id("tickets"),
    title: v.optional(v.string()),
    description: v.optional(v.string()),
    priority: v.optional(
      v.union(
        v.literal("critical"),
        v.literal("high"),
        v.literal("medium"),
        v.literal("low")
      )
    ),
    status: v.optional(
      v.union(
        v.literal("open"),
        v.literal("in_progress"),
        v.literal("resolved"),
        v.literal("closed")
      )
    ),
    assigneeId: v.optional(v.id("users")),
  },
  returns: v.null(),
  handler: async (ctx, args): Promise<null> => {
    await requireOperator(ctx);
    const { id, ...fields } = args;

    const patch: Partial<Doc<"tickets">> = {};
    if (fields.title !== undefined) patch.title = fields.title;
    if (fields.description !== undefined) patch.description = fields.description;
    if (fields.priority !== undefined) patch.priority = fields.priority;
    if (fields.assigneeId !== undefined) patch.assigneeId = fields.assigneeId;
    if (fields.status !== undefined) {
      patch.status = fields.status;
      if (fields.status === "resolved") patch.resolvedAt = Date.now();
    }

    await ctx.db.patch(id, patch);
    return null;
  },
});

export const remove = mutation({
  args: { id: v.id("tickets") },
  returns: v.null(),
  handler: async (ctx, args): Promise<null> => {
    await requireOperator(ctx);
    await ctx.db.delete(args.id);
    return null;
  },
});
