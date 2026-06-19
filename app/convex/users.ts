import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { Id } from "./_generated/dataModel";
import { getCurrentUser } from "./lib/auth";

export const store = mutation({
  args: {
    role: v.optional(
      v.union(v.literal("admin"), v.literal("operator"), v.literal("viewer"))
    ),
  },
  returns: v.id("users"),
  handler: async (ctx, args): Promise<Id<"users">> => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Not authenticated");

    const existing = await ctx.db
      .query("users")
      .withIndex("by_token", (q) =>
        q.eq("tokenIdentifier", identity.tokenIdentifier)
      )
      .unique();

    if (existing) return existing._id;

    return await ctx.db.insert("users", {
      tokenIdentifier: identity.tokenIdentifier,
      name: identity.name ?? "Anonymous",
      email: identity.email ?? "",
      role: args.role ?? "viewer",
    });
  },
});

export const me = query({
  args: {},
  returns: v.union(
    v.object({
      _id: v.id("users"),
      _creationTime: v.number(),
      tokenIdentifier: v.string(),
      name: v.string(),
      email: v.string(),
      role: v.union(v.literal("admin"), v.literal("operator"), v.literal("viewer")),
    }),
    v.null()
  ),
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) return null;
    return await ctx.db
      .query("users")
      .withIndex("by_token", (q) =>
        q.eq("tokenIdentifier", identity.tokenIdentifier)
      )
      .unique();
  },
});

export const setRole = mutation({
  args: {
    userId: v.id("users"),
    role: v.union(v.literal("admin"), v.literal("operator"), v.literal("viewer")),
  },
  returns: v.null(),
  handler: async (ctx, args): Promise<null> => {
    const caller = await getCurrentUser(ctx);
    if (caller.role !== "admin") throw new Error("Admin access required");
    await ctx.db.patch(args.userId, { role: args.role });
    return null;
  },
});
