import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  users: defineTable({
    tokenIdentifier: v.string(),
    name: v.string(),
    email: v.string(),
  }).index("by_token", ["tokenIdentifier"]),

  tasks: defineTable({
    userId: v.id("users"),
    title: v.string(),
    completed: v.boolean(),
    createdAt: v.number(),
  })
    .index("by_user", ["userId"])
    .index("by_user_and_completed", ["userId", "completed"]),
});
