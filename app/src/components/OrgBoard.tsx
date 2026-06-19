import { useState, FormEvent } from "react";
import { useQuery, useMutation } from "convex/react";
import { api } from "../../convex/_generated/api";

type OrgStatus = "active" | "onboarding" | "suspended";

export function OrgBoard() {
  const orgs = useQuery(api.organisations.list, {});
  const createOrg = useMutation(api.organisations.create);
  const updateOrg = useMutation(api.organisations.update);

  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    name: "",
    slug: "",
    sector: "",
    status: "onboarding" as OrgStatus,
  });

  const autoSlug = (name: string) =>
    name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    await createOrg(form);
    setForm({ name: "", slug: "", sector: "", status: "onboarding" });
    setShowForm(false);
  };

  const statusGroups: OrgStatus[] = ["active", "onboarding", "suspended"];

  return (
    <section className="panel">
      <div className="panel-header">
        <div>
          <h2 className="panel-title">Organisation Board</h2>
          <p className="panel-sub">Client organisations managed by OCTA</p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowForm((v) => !v)}>
          {showForm ? "Cancel" : "+ Add Organisation"}
        </button>
      </div>

      {showForm && (
        <form className="form-card" onSubmit={handleSubmit}>
          <div className="form-row">
            <div className="form-field">
              <label>Organisation Name</label>
              <input
                value={form.name}
                onChange={(e) =>
                  setForm((f) => ({
                    ...f,
                    name: e.target.value,
                    slug: autoSlug(e.target.value),
                  }))
                }
                placeholder="Acme Logistics Ltd"
                required
              />
            </div>
            <div className="form-field">
              <label>Slug</label>
              <input
                value={form.slug}
                onChange={(e) => setForm((f) => ({ ...f, slug: e.target.value }))}
                placeholder="acme-logistics"
                required
              />
            </div>
          </div>
          <div className="form-row">
            <div className="form-field">
              <label>Sector</label>
              <input
                value={form.sector}
                onChange={(e) => setForm((f) => ({ ...f, sector: e.target.value }))}
                placeholder="logistics"
                required
              />
            </div>
            <div className="form-field">
              <label>Status</label>
              <select
                value={form.status}
                onChange={(e) => setForm((f) => ({ ...f, status: e.target.value as OrgStatus }))}
              >
                <option value="onboarding">onboarding</option>
                <option value="active">active</option>
                <option value="suspended">suspended</option>
              </select>
            </div>
          </div>
          <button type="submit" className="btn btn-primary">Add</button>
        </form>
      )}

      {orgs === undefined ? (
        <p className="muted">Loading…</p>
      ) : orgs.length === 0 ? (
        <p className="muted">No organisations yet.</p>
      ) : (
        <div className="kanban">
          {statusGroups.map((status) => {
            const group = orgs.filter((o) => o.status === status);
            return (
              <div key={status} className="kanban-col">
                <div className="kanban-col-header">
                  <span className={`status-dot status-${status}`} />
                  {status} <span className="count">{group.length}</span>
                </div>
                {group.length === 0 ? (
                  <p className="muted small">None</p>
                ) : (
                  group.map((org) => (
                    <div key={org._id} className="org-card">
                      <div className="org-name">{org.name}</div>
                      <div className="org-slug">/{org.slug}</div>
                      <div className="org-sector">{org.sector}</div>
                      <div className="org-actions">
                        {status === "onboarding" && (
                          <button
                            className="btn btn-sm btn-ghost"
                            onClick={() => updateOrg({ id: org._id, status: "active" })}
                          >
                            Activate
                          </button>
                        )}
                        {status === "active" && (
                          <button
                            className="btn btn-sm btn-danger-ghost"
                            onClick={() => updateOrg({ id: org._id, status: "suspended" })}
                          >
                            Suspend
                          </button>
                        )}
                        {status === "suspended" && (
                          <button
                            className="btn btn-sm btn-ghost"
                            onClick={() => updateOrg({ id: org._id, status: "active" })}
                          >
                            Reactivate
                          </button>
                        )}
                      </div>
                    </div>
                  ))
                )}
              </div>
            );
          })}
        </div>
      )}
    </section>
  );
}
