import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { getCurrentUser } from "./lib/auth";
import { Doc } from "./_generated/dataModel";

// ──────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ──────────────────────────────────────────────────────────────────────────────

async function getUserByToken(
  ctx: Parameters<typeof getCurrentUser>[0],
  tokenIdentifier: string
): Promise<Doc<"users"> | null> {
  return ctx.db
    .query("users")
    .withIndex("by_token", (q) => q.eq("tokenIdentifier", tokenIdentifier))
    .unique();
}

// ──────────────────────────────────────────────────────────────────────────────
// Queries
// ──────────────────────────────────────────────────────────────────────────────

/**
 * Return the current authenticated user's profile, or null if they have not
 * yet called `ensureUser`.
 */
export const me = query({
  args: {},
  returns: v.union(
    v.object({
      _id: v.id("users"),
      _creationTime: v.number(),
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
    }),
    v.null()
  ),
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) return null;
    return getUserByToken(ctx, identity.tokenIdentifier);
  },
});

/**
 * Admin-only: list all platform users, optionally filtered by role.
 */
export const listByRole = query({
  args: {
    role: v.optional(
      v.union(
        v.literal("customer"),
        v.literal("driver"),
        v.literal("admin")
      )
    ),
  },
  returns: v.array(
    v.object({
      _id: v.id("users"),
      _creationTime: v.number(),
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
  ),
  handler: async (ctx, args) => {
    const actor = await getCurrentUser(ctx);

    if (actor.role !== "admin") {
      throw new Error("Unauthorized: admin access required");
    }

    if (args.role) {
      return ctx.db
        .query("users")
        .withIndex("by_role", (q) => q.eq("role", args.role!))
        .collect();
    }

    return ctx.db.query("users").collect();
  },
});

// ──────────────────────────────────────────────────────────────────────────────
// Mutations
// ──────────────────────────────────────────────────────────────────────────────

/**
 * Upsert the authenticated user's profile row.
 *
 * Must be called once after the user signs in for the first time before any
 * other authenticated operation will succeed.  Safe to call on every sign-in
 * as a no-op when the row already exists.
 */
export const ensureUser = mutation({
  args: {
    email: v.string(),
    name: v.string(),
    role: v.optional(
      v.union(
        v.literal("customer"),
        v.literal("driver"),
        v.literal("admin")
      )
    ),
    phone: v.optional(v.string()),
  },
  returns: v.id("users"),
  handler: async (ctx, args) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Not authenticated");

    const existing = await getUserByToken(ctx, identity.tokenIdentifier);

    if (existing) {
      await ctx.db.patch(existing._id, {
        name: args.name,
        ...(args.phone !== undefined ? { phone: args.phone } : {}),
      });
      return existing._id;
    }

    return ctx.db.insert("users", {
      tokenIdentifier: identity.tokenIdentifier,
      email: args.email,
      name: args.name,
      role: args.role ?? "customer",
      phone: args.phone,
      createdAt: Date.now(),
    });
  },
});

/**
 * Update the current user's own editable profile fields.
 */
export const updateProfile = mutation({
  args: {
    name: v.optional(v.string()),
    phone: v.optional(v.string()),
  },
  returns: v.id("users"),
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);

    if (args.name !== undefined && args.name.trim().length < 2) {
      throw new Error("Name must be at least 2 characters");
    }

    const updates: { name?: string; phone?: string } = {};
    if (args.name !== undefined) updates.name = args.name.trim();
    if (args.phone !== undefined) updates.phone = args.phone;

    await ctx.db.patch(user._id, updates);
    return user._id;
  },
});

/**
 * Admin-only: promote / demote a user to a different role.
 */
export const setRole = mutation({
  args: {
    userId: v.id("users"),
    role: v.union(
      v.literal("customer"),
      v.literal("driver"),
      v.literal("admin")
    ),
  },
  returns: v.id("users"),
  handler: async (ctx, args) => {
    const actor = await getCurrentUser(ctx);

    if (actor.role !== "admin") {
      throw new Error("Unauthorized: admin access required");
    }

    const target = await ctx.db.get(args.userId);
    if (!target) throw new Error("User not found");

    await ctx.db.patch(args.userId, { role: args.role });
    return args.userId;
  },
});
