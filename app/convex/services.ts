import { query, mutation } from "./_generated/server";
import { v } from "convex/values";
import { Doc, Id } from "./_generated/dataModel";
import { getCurrentUser, requireOperator } from "./lib/auth";

const serviceValidator = v.object({
  _id: v.id("services"),
  _creationTime: v.number(),
  name: v.string(),
  code: v.string(),
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
  status: v.union(v.literal("live"), v.literal("beta"), v.literal("deprecated")),
  createdBy: v.id("users"),
  createdAt: v.number(),
});

export const list = query({
  args: {
    category: v.optional(
      v.union(
        v.literal("circular-economy"),
        v.literal("mining"),
        v.literal("carbon"),
        v.literal("logistics"),
        v.literal("ai"),
        v.literal("blockchain"),
        v.literal("other")
      )
    ),
    status: v.optional(
      v.union(v.literal("live"), v.literal("beta"), v.literal("deprecated"))
    ),
  },
  returns: v.array(serviceValidator),
  handler: async (ctx, args): Promise<Doc<"services">[]> => {
    await getCurrentUser(ctx);
    if (args.category) {
      return await ctx.db
        .query("services")
        .withIndex("by_category", (q) => q.eq("category", args.category!))
        .collect();
    }
    if (args.status) {
      return await ctx.db
        .query("services")
        .withIndex("by_status", (q) => q.eq("status", args.status!))
        .collect();
    }
    return await ctx.db.query("services").order("desc").collect();
  },
});

export const get = query({
  args: { id: v.id("services") },
  returns: v.union(serviceValidator, v.null()),
  handler: async (ctx, args): Promise<Doc<"services"> | null> => {
    await getCurrentUser(ctx);
    return await ctx.db.get(args.id);
  },
});

export const create = mutation({
  args: {
    name: v.string(),
    code: v.string(),
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
    status: v.union(v.literal("live"), v.literal("beta"), v.literal("deprecated")),
  },
  returns: v.id("services"),
  handler: async (ctx, args): Promise<Id<"services">> => {
    const user = await requireOperator(ctx);

    const existing = await ctx.db
      .query("services")
      .withIndex("by_code", (q) => q.eq("code", args.code))
      .unique();
    if (existing) throw new Error(`Service code "${args.code}" already exists`);

    return await ctx.db.insert("services", {
      ...args,
      createdBy: user._id,
      createdAt: Date.now(),
    });
  },
});

export const update = mutation({
  args: {
    id: v.id("services"),
    name: v.optional(v.string()),
    description: v.optional(v.string()),
    status: v.optional(
      v.union(v.literal("live"), v.literal("beta"), v.literal("deprecated"))
    ),
  },
  returns: v.null(),
  handler: async (ctx, args): Promise<null> => {
    await requireOperator(ctx);
    const { id, ...updates } = args;
    const patch: Partial<Pick<Doc<"services">, "name" | "description" | "status">> = {};
    if (updates.name !== undefined) patch.name = updates.name;
    if (updates.description !== undefined) patch.description = updates.description;
    if (updates.status !== undefined) patch.status = updates.status;
    await ctx.db.patch(id, patch);
    return null;
  },
});
