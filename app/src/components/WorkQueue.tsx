import { useState, FormEvent } from "react";
import { useQuery, useMutation } from "convex/react";
import { api } from "../../convex/_generated/api";

type TicketStatus = "open" | "in_progress" | "resolved" | "closed";
type TicketPriority = "critical" | "high" | "medium" | "low";

const PRIORITIES: TicketPriority[] = ["critical", "high", "medium", "low"];
const STATUSES: TicketStatus[] = ["open", "in_progress", "resolved", "closed"];

export function WorkQueue() {
  const [statusFilter, setStatusFilter] = useState<TicketStatus | "">("");
  const tickets = useQuery(
    api.tickets.list,
    statusFilter ? { status: statusFilter } : {}
  );
  const createTicket = useMutation(api.tickets.create);
  const updateTicket = useMutation(api.tickets.update);
  const removeTicket = useMutation(api.tickets.remove);

  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    title: "",
    description: "",
    priority: "medium" as TicketPriority,
  });

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    await createTicket({
      title: form.title,
      description: form.description || undefined,
      priority: form.priority,
    });
    setForm({ title: "", description: "", priority: "medium" });
    setShowForm(false);
  };

  const nextStatus: Record<TicketStatus, TicketStatus | null> = {
    open: "in_progress",
    in_progress: "resolved",
    resolved: "closed",
    closed: null,
  };

  return (
    <section className="panel">
      <div className="panel-header">
        <div>
          <h2 className="panel-title">Work Queue</h2>
          <p className="panel-sub">OCTA operational tickets and tasks</p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowForm((v) => !v)}>
          {showForm ? "Cancel" : "+ Raise Ticket"}
        </button>
      </div>

      {showForm && (
        <form className="form-card" onSubmit={handleSubmit}>
          <div className="form-row">
            <div className="form-field" style={{ flex: 2 }}>
              <label>Title</label>
              <input
                value={form.title}
                onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))}
                placeholder="Integration health degraded on acme-logistics"
                required
              />
            </div>
            <div className="form-field">
              <label>Priority</label>
              <select
                value={form.priority}
                onChange={(e) => setForm((f) => ({ ...f, priority: e.target.value as TicketPriority }))}
              >
                {PRIORITIES.map((p) => (
                  <option key={p} value={p}>{p}</option>
                ))}
              </select>
            </div>
          </div>
          <div className="form-field">
            <label>Description (optional)</label>
            <input
              value={form.description}
              onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
              placeholder="Additional context…"
            />
          </div>
          <button type="submit" className="btn btn-primary">Raise</button>
        </form>
      )}

      <div className="filter-bar">
        <button
          className={`btn btn-filter ${statusFilter === "" ? "active" : ""}`}
          onClick={() => setStatusFilter("")}
        >
          All
        </button>
        {STATUSES.map((s) => (
          <button
            key={s}
            className={`btn btn-filter ${statusFilter === s ? "active" : ""}`}
            onClick={() => setStatusFilter(s)}
          >
            {s.replace("_", " ")}
          </button>
        ))}
      </div>

      {tickets === undefined ? (
        <p className="muted">Loading…</p>
      ) : tickets.length === 0 ? (
        <p className="muted">No tickets. {statusFilter === "" ? "Raise one above!" : ""}</p>
      ) : (
        <div className="ticket-list">
          {tickets.map((t) => {
            const next = nextStatus[t.status];
            return (
              <div key={t._id} className={`ticket-row priority-${t.priority}`}>
                <div className="ticket-meta">
                  <span className={`chip chip-priority-${t.priority}`}>{t.priority}</span>
                  <span className={`chip chip-${t.status}`}>{t.status.replace("_", " ")}</span>
                </div>
                <div className="ticket-title">{t.title}</div>
                {t.description && (
                  <div className="ticket-desc">{t.description}</div>
                )}
                <div className="ticket-actions">
                  {next && (
                    <button
                      className="btn btn-sm btn-ghost"
                      onClick={() => updateTicket({ id: t._id, status: next })}
                    >
                      → {next.replace("_", " ")}
                    </button>
                  )}
                  <button
                    className="btn btn-sm btn-danger-ghost"
                    onClick={() => removeTicket({ id: t._id })}
                  >
                    ✕
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </section>
  );
}
