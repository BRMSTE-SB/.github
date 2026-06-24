import { site } from "../data/site";

export function Hero() {
  return (
    <section className="hero" id="top">
      <div className="hero-glow" aria-hidden />
      <p className="eyebrow">{site.glasswing}</p>
      <h1>{site.headline}</h1>
      <p className="lede">{site.tagline}</p>
      <div className="hero-meta">
        <span>{site.operator}</span>
        <span>{site.patent}</span>
      </div>
      <div className="hero-actions">
        <a className="btn primary" href={site.links.openAll}>
          OPEN ALL manifest
        </a>
        <a className="btn ghost" href={site.links.substrate}>
          Glass substrate
        </a>
      </div>
      <p className="nemotron-badge">
        Built with <strong>Nemotron Ultra</strong> · {site.nemotron.model}
      </p>
    </section>
  );
}
