import { useState, FormEvent } from "react";
import { useQuery, useMutation } from "convex/react";
import { api } from "../../convex/_generated/api";

type Category =
  | "circular-economy"
  | "mining"
  | "carbon"
  | "logistics"
  | "ai"
  | "blockchain"
  | "other";

type ServiceStatus = "live" | "beta" | "deprecated";

const CATEGORIES: Category[] = [
  "circular-economy",
  "mining",
  "carbon",
  "logistics",
  "ai",
  "blockchain",
  "other",
];

export function ServiceRegistry() {
  const [categoryFilter, setCategoryFilter] = useState<Category | "">("");
  const services = useQuery(
    api.services.list,
    categoryFilter ? { category: categoryFilter } : {}
  );
  const createService = useMutation(api.services.create);
  const updateService = useMutation(api.services.update);

  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    name: "",
    code: "",
    description: "",
    category: "other" as Category,
    status: "beta" as ServiceStatus,
  });

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    await createService(form);
    setForm({ name: "", code: "", description: "", category: "other", status: "beta" });
    setShowForm(false);
  };

  return (
    <section className="panel">
      <div className="panel-header">
        <div>
          <h2 className="panel-title">Service Registry</h2>
          <p className="panel-sub">OCTA-managed capabilities and integrations</p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowForm((v) => !v)}>
          {showForm ? "Cancel" : "+ Register Service"}
        </button>
      </div>

      {showForm && (
        <form className="form-card" onSubmit={handleSubmit}>
          <div className="form-row">
            <div className="form-field">
              <label>Service Name</label>
              <input
                value={form.name}
                onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
                placeholder="Re-Tyre Logistics API"
                required
              />
            </div>
            <div className="form-field">
              <label>Code (machine ID)</label>
              <input
                value={form.code}
                onChange={(e) => setForm((f) => ({ ...f, code: e.target.value }))}
                placeholder="retyre-logistics"
                required
              />
            </div>
          </div>
          <div className="form-field">
            <label>Description</label>
            <input
              value={form.description}
              onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
              placeholder="Circular tyre logistics coordination layer"
              required
            />
          </div>
          <div className="form-row">
            <div className="form-field">
              <label>Category</label>
              <select
                value={form.category}
                onChange={(e) => setForm((f) => ({ ...f, category: e.target.value as Category }))}
              >
                {CATEGORIES.map((c) => (
                  <option key={c} value={c}>{c}</option>
                ))}
              </select>
            </div>
            <div className="form-field">
              <label>Status</label>
              <select
                value={form.status}
                onChange={(e) => setForm((f) => ({ ...f, status: e.target.value as ServiceStatus }))}
              >
                <option value="beta">beta</option>
                <option value="live">live</option>
                <option value="deprecated">deprecated</option>
              </select>
            </div>
          </div>
          <button type="submit" className="btn btn-primary">Register</button>
        </form>
      )}

      <div className="filter-bar">
        <button
          className={`btn btn-filter ${categoryFilter === "" ? "active" : ""}`}
          onClick={() => setCategoryFilter("")}
        >
          All
        </button>
        {CATEGORIES.map((c) => (
          <button
            key={c}
            className={`btn btn-filter ${categoryFilter === c ? "active" : ""}`}
            onClick={() => setCategoryFilter(c)}
          >
            {c}
          </button>
        ))}
      </div>

      {services === undefined ? (
        <p className="muted">Loading…</p>
      ) : services.length === 0 ? (
        <p className="muted">No services registered yet.</p>
      ) : (
        <div className="card-grid">
          {services.map((s) => (
            <div key={s._id} className="service-card">
              <div className="service-card-header">
                <span className="service-code">{s.code}</span>
                <span className={`chip chip-${s.status}`}>{s.status}</span>
              </div>
              <div className="service-name">{s.name}</div>
              <div className="service-desc">{s.description}</div>
              <div className="service-footer">
                <span className={`chip chip-cat`}>{s.category}</span>
                {s.status !== "live" && (
                  <button
                    className="btn btn-sm btn-ghost"
                    onClick={() => updateService({ id: s._id, status: "live" })}
                  >
                    → Go Live
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </section>
  );
}
