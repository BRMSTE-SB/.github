import { query, mutation } from "./_generated/server";
import { v } from "convex/values";
import { Doc, Id } from "./_generated/dataModel";
import { getCurrentUser, requireOperator } from "./lib/auth";

const orgValidator = v.object({
  _id: v.id("organisations"),
  _creationTime: v.number(),
  name: v.string(),
  slug: v.string(),
  sector: v.string(),
  status: v.union(
    v.literal("active"),
    v.literal("onboarding"),
    v.literal("suspended")
  ),
  createdBy: v.id("users"),
  createdAt: v.number(),
});

export const list = query({
  args: {
    status: v.optional(
      v.union(v.literal("active"), v.literal("onboarding"), v.literal("suspended"))
    ),
  },
  returns: v.array(orgValidator),
  handler: async (ctx, args): Promise<Doc<"organisations">[]> => {
    await getCurrentUser(ctx);
    if (args.status) {
      return await ctx.db
        .query("organisations")
        .withIndex("by_status", (q) => q.eq("status", args.status!))
        .collect();
    }
    return await ctx.db.query("organisations").order("desc").collect();
  },
});

export const get = query({
  args: { id: v.id("organisations") },
  returns: v.union(orgValidator, v.null()),
  handler: async (ctx, args): Promise<Doc<"organisations"> | null> => {
    await getCurrentUser(ctx);
    return await ctx.db.get(args.id);
  },
});

export const create = mutation({
  args: {
    name: v.string(),
    slug: v.string(),
    sector: v.string(),
    status: v.union(
      v.literal("active"),
      v.literal("onboarding"),
      v.literal("suspended")
    ),
  },
  returns: v.id("organisations"),
  handler: async (ctx, args): Promise<Id<"organisations">> => {
    const user = await requireOperator(ctx);

    const existing = await ctx.db
      .query("organisations")
      .withIndex("by_slug", (q) => q.eq("slug", args.slug))
      .unique();
    if (existing) throw new Error(`Slug "${args.slug}" is already taken`);

    return await ctx.db.insert("organisations", {
      ...args,
      createdBy: user._id,
      createdAt: Date.now(),
    });
  },
});

export const update = mutation({
  args: {
    id: v.id("organisations"),
    name: v.optional(v.string()),
    sector: v.optional(v.string()),
    status: v.optional(
      v.union(v.literal("active"), v.literal("onboarding"), v.literal("suspended"))
    ),
  },
  returns: v.null(),
  handler: async (ctx, args): Promise<null> => {
    await requireOperator(ctx);
    const { id, ...updates } = args;
    const patch: Partial<Pick<Doc<"organisations">, "name" | "sector" | "status">> = {};
    if (updates.name !== undefined) patch.name = updates.name;
    if (updates.sector !== undefined) patch.sector = updates.sector;
    if (updates.status !== undefined) patch.status = updates.status;
    await ctx.db.patch(id, patch);
    return null;
  },
});
