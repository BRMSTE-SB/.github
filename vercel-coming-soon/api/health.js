export default function handler() {
  return new Response(
    JSON.stringify({
      ok: true,
      page: "brmste-coming-soon-v4-vercel",
      platform: "vercel",
    }),
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
    },
  );
}
