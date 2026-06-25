import { site } from "../data/site";

export function FortKnoxRail() {
  const summary = site.fortKnox;

  return (
    <section className="panel fort-knox glass" id="fort-knox">
      <div className="fort-knox-inner">
        <div>
          <p className="eyebrow">Human-open lane · metadata only</p>
          <h2>{summary.headline}</h2>
          <p>
            <strong>{summary.envVarCount}</strong> env var names ·{" "}
            <strong>{summary.scriptCount}</strong> Mac scripts ·{" "}
            <strong>{summary.railCount}</strong> payment and substrate rails — published on
            OPEN ALL. Values stay in <code>.env.fort-knox</code> on the operator Mac.
          </p>
          <p className="doctrine-line">{summary.doctrine}</p>
        </div>
        <div className="fort-knox-actions">
          <a className="btn primary" href={site.links.fortKnoxCorpus}>
            Public catalog
          </a>
          <a className="btn ghost" href={site.links.fortKnoxDocs}>
            Operator guide
          </a>
        </div>
      </div>
    </section>
  );
}
