import type { LaneCard } from "../data/site";

interface Props {
  lanes: LaneCard[];
}

export function LaneGrid({ lanes }: Props) {
  return (
    <section className="panel" id="lanes">
      <h2>Open lanes</h2>
      <div className="grid">
        {lanes.map((lane) => (
          <article key={lane.id} className="card glass">
            <div className="card-top">
              <h3>{lane.title}</h3>
              <span className={`pill ${lane.status}`}>{lane.status}</span>
            </div>
            <p>{lane.subtitle}</p>
            {lane.href ? (
              <a className="link" href={lane.href} target="_blank" rel="noreferrer">
                View register →
              </a>
            ) : null}
          </article>
        ))}
      </div>
    </section>
  );
}
