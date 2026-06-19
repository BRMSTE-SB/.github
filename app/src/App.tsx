import { useState } from "react";
import { Dashboard } from "./components/Dashboard";
import { ServiceRegistry } from "./components/ServiceRegistry";
import { OrgBoard } from "./components/OrgBoard";
import { WorkQueue } from "./components/WorkQueue";
import "./App.css";

type Tab = "dashboard" | "services" | "orgs" | "queue";

const TABS: { id: Tab; label: string; icon: string }[] = [
  { id: "dashboard", label: "Dashboard", icon: "◈" },
  { id: "services", label: "Services", icon: "⬡" },
  { id: "orgs", label: "Organisations", icon: "⬡" },
  { id: "queue", label: "Work Queue", icon: "▤" },
];

export default function App() {
  const [tab, setTab] = useState<Tab>("dashboard");

  return (
    <div className="app">
      <aside className="sidebar">
        <div className="brand">
          <span className="brand-icon">◈</span>
          <div>
            <div className="brand-name">OCTA</div>
            <div className="brand-sub">BRMSTE GSI Platform</div>
          </div>
        </div>

        <nav className="nav">
          {TABS.map((t) => (
            <button
              key={t.id}
              className={`nav-item ${tab === t.id ? "active" : ""}`}
              onClick={() => setTab(t.id)}
            >
              <span className="nav-icon">{t.icon}</span>
              {t.label}
            </button>
          ))}
        </nav>

        <div className="sidebar-footer">
          <span className="badge">GB2607860</span>
          <span className="badge">BRMSTE LTD</span>
        </div>
      </aside>

      <main className="content">
        {tab === "dashboard" && <Dashboard />}
        {tab === "services" && <ServiceRegistry />}
        {tab === "orgs" && <OrgBoard />}
        {tab === "queue" && <WorkQueue />}
      </main>
    </div>
  );
}
