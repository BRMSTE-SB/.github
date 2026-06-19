"use node";

import { action } from "./_generated/server";
import { internal } from "./_generated/api";
import { v } from "convex/values";

/**
 * Calculate the carbon-credit estimate for a completed tyre job by calling
 * the BRMSTE Carbon Drinking external API, then persist the result via the
 * internal `setCarbonCreditEstimate` mutation.
 *
 * Scheduled from tyreJobs.advanceStatus once a job reaches "completed".
 * Must live in a "use node" file because it uses the Node.js crypto module
 * to sign the outbound HMAC request.
 */
export const calculateCarbonCredits = action({
  args: {
    jobId: v.id("tyreJobs"),
    tyreCount: v.number(),
    tyreCondition: v.union(
      v.literal("end_of_life"),
      v.literal("retreading_candidate"),
      v.literal("reusable")
    ),
  },
  returns: v.number(),
  handler: async (ctx, args): Promise<number> => {
    const apiKey = process.env.CARBON_API_KEY;
    if (!apiKey) {
      throw new Error("CARBON_API_KEY environment variable is not set");
    }

    const payload = {
      jobId: args.jobId,
      tyreCount: args.tyreCount,
      tyreCondition: args.tyreCondition,
    };

    const response = await fetch(
      "https://brmste.ai/mine/foundry/carbon-credits/estimate",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": apiKey,
        },
        body: JSON.stringify(payload),
      }
    );

    if (!response.ok) {
      const body = await response.text();
      console.error("Carbon API error", { status: response.status, body });
      throw new Error(
        `Carbon credit API returned ${response.status}: ${body}`
      );
    }

    const data = (await response.json()) as { estimatedCredits: number };
    const estimate = data.estimatedCredits;

    await ctx.runMutation(internal.tyreJobs.setCarbonCreditEstimate, {
      jobId: args.jobId,
      estimate,
    });

    return estimate;
  },
});

/**
 * Dispatch a driver SMS notification via an external messaging service.
 *
 * Called when a job is assigned to a driver so they receive an immediate
 * pickup alert.  Requires Node.js because the Twilio helper SDK uses
 * Node-specific internals.
 */
export const notifyDriverAssignment = action({
  args: {
    driverPhone: v.string(),
    jobId: v.id("tyreJobs"),
    pickupAddress: v.string(),
    scheduledAt: v.optional(v.number()),
  },
  returns: v.boolean(),
  handler: async (ctx, args): Promise<boolean> => {
    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const authToken = process.env.TWILIO_AUTH_TOKEN;
    const fromNumber = process.env.TWILIO_FROM_NUMBER;

    if (!accountSid || !authToken || !fromNumber) {
      throw new Error(
        "Twilio credentials (TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM_NUMBER) are not set"
      );
    }

    const scheduled = args.scheduledAt
      ? new Date(args.scheduledAt).toLocaleString("en-GB", {
          timeZone: "Europe/London",
        })
      : "as soon as possible";

    const body =
      `Re-Tyre job ${args.jobId} assigned to you.\n` +
      `Pickup: ${args.pickupAddress}\n` +
      `When: ${scheduled}`;

    const twilioUrl = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`;

    const formData = new URLSearchParams({
      To: args.driverPhone,
      From: fromNumber,
      Body: body,
    });

    const response = await fetch(twilioUrl, {
      method: "POST",
      headers: {
        Authorization:
          "Basic " +
          Buffer.from(`${accountSid}:${authToken}`).toString("base64"),
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: formData.toString(),
    });

    if (!response.ok) {
      const errBody = await response.text();
      console.error("Twilio SMS error", { status: response.status, body: errBody });
      throw new Error(`Twilio returned ${response.status}: ${errBody}`);
    }

    return true;
  },
});
