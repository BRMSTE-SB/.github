import { useQuery, useMutation } from "convex/react";
import { api } from "../convex/_generated/api";
import { FormEvent, useState } from "react";
import "./App.css";

export default function App() {
  const tasks = useQuery(api.tasks.list);
  const createTask = useMutation(api.tasks.create);
  const updateTask = useMutation(api.tasks.update);
  const removeTask = useMutation(api.tasks.remove);

  const [newTitle, setNewTitle] = useState("");
  const [filter, setFilter] = useState<"all" | "active" | "done">("all");

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    const title = newTitle.trim();
    if (!title) return;
    await createTask({ title });
    setNewTitle("");
  };

  const filteredTasks = tasks?.filter((t) => {
    if (filter === "active") return !t.completed;
    if (filter === "done") return t.completed;
    return true;
  });

  const pendingCount = tasks?.filter((t) => !t.completed).length ?? 0;

  return (
    <main className="container">
      <header>
        <h1>Task Manager</h1>
        <p className="subtitle">Powered by Convex real-time backend</p>
      </header>

      <form className="task-form" onSubmit={handleSubmit}>
        <input
          type="text"
          value={newTitle}
          onChange={(e) => setNewTitle(e.target.value)}
          placeholder="What needs to be done?"
          className="task-input"
          aria-label="New task title"
        />
        <button type="submit" className="btn btn-primary" disabled={!newTitle.trim()}>
          Add Task
        </button>
      </form>

      <div className="filter-bar">
        {(["all", "active", "done"] as const).map((f) => (
          <button
            key={f}
            className={`btn btn-filter ${filter === f ? "active" : ""}`}
            onClick={() => setFilter(f)}
          >
            {f.charAt(0).toUpperCase() + f.slice(1)}
          </button>
        ))}
        <span className="pending-count">{pendingCount} left</span>
      </div>

      {tasks === undefined ? (
        <p className="loading">Loading tasks…</p>
      ) : filteredTasks!.length === 0 ? (
        <p className="empty">No tasks here. {filter === "all" ? "Add one above!" : ""}</p>
      ) : (
        <ul className="task-list">
          {filteredTasks!.map((task) => (
            <li key={task._id} className={`task-item ${task.completed ? "completed" : ""}`}>
              <input
                type="checkbox"
                checked={task.completed}
                onChange={(e) =>
                  updateTask({ taskId: task._id, completed: e.target.checked })
                }
                className="task-checkbox"
                aria-label={`Mark "${task.title}" as ${task.completed ? "incomplete" : "complete"}`}
              />
              <span className="task-title">{task.title}</span>
              <button
                className="btn btn-danger btn-sm"
                onClick={() => removeTask({ taskId: task._id })}
                aria-label={`Delete "${task.title}"`}
              >
                ✕
              </button>
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}
