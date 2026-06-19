import { useQuery } from "convex/react";
import { api } from "../../convex/_generated/api";

export function Dashboard() {
  const services = useQuery(api.services.list, {});
  const orgs = useQuery(api.organisations.list, {});
  const integrations = useQuery(api.integrations.listAll, {});
  const openTickets = useQuery(api.tickets.list, { status: "open" });
  const criticalTickets = useQuery(api.tickets.list, { priority: "critical" });

  const liveServices = services?.filter((s) => s.status === "live").length ?? 0;
  const activeOrgs = orgs?.filter((o) => o.status === "active").length ?? 0;
  const activeIntegrations = integrations?.filter((i) => i.status === "active").length ?? 0;
  const failedIntegrations = integrations?.filter((i) => i.status === "failed").length ?? 0;
  const avgHealth =
    integrations && integrations.length > 0
      ? Math.round(
          integrations.reduce((sum, i) => sum + i.healthScore, 0) / integrations.length
        )
      : 100;

  const statCards = [
    { label: "Live Services", value: liveServices, accent: true },
    { label: "Active Orgs", value: activeOrgs, accent: false },
    { label: "Active Integrations", value: activeIntegrations, accent: false },
    { label: "Failed Integrations", value: failedIntegrations, warn: failedIntegrations > 0 },
    { label: "Open Tickets", value: openTickets?.length ?? "—", accent: false },
    { label: "Critical", value: criticalTickets?.length ?? "—", warn: (criticalTickets?.length ?? 0) > 0 },
    { label: "Avg Health Score", value: `${avgHealth}%`, accent: avgHealth >= 90 },
  ];

  return (
    <section className="panel">
      <h2 className="panel-title">OCTA Operations Overview</h2>
      <p className="panel-sub">Global Systems Integrator · Real-time · BRMSTE LTD</p>

      <div className="stat-grid">
        {statCards.map((c) => (
          <div
            key={c.label}
            className={`stat-card ${c.accent ? "stat-accent" : ""} ${c.warn ? "stat-warn" : ""}`}
          >
            <div className="stat-value">{c.value ?? "—"}</div>
            <div className="stat-label">{c.label}</div>
          </div>
        ))}
      </div>

      <h3 className="section-title" style={{ marginTop: "2rem" }}>Integration Health</h3>
      {integrations === undefined ? (
        <p className="muted">Loading…</p>
      ) : integrations.length === 0 ? (
        <p className="muted">No integrations yet. Connect an organisation to a service to get started.</p>
      ) : (
        <div className="health-list">
          {integrations.slice(0, 8).map((i) => (
            <div key={i._id} className="health-row">
              <span className={`status-dot status-${i.status}`} />
              <span className="health-id">{i._id.slice(-8)}</span>
              <div className="health-bar-wrap">
                <div
                  className="health-bar"
                  style={{
                    width: `${i.healthScore}%`,
                    background: i.healthScore >= 90 ? "var(--accent)" : i.healthScore >= 60 ? "var(--warn)" : "var(--danger)",
                  }}
                />
              </div>
              <span className="health-score">{i.healthScore}%</span>
              <span className={`chip chip-${i.status}`}>{i.status}</span>
            </div>
          ))}
        </div>
      )}
    </section>
  );
}
