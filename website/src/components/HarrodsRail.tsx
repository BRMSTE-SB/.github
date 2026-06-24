import { site } from "../data/site";

export function HarrodsRail() {
  return (
    <section className="panel harrods glass" id="harrods">
      <div className="harrods-inner">
        <div>
          <p className="eyebrow">Retail lane · 100% equity</p>
          <h2>HARRODS LIMITED</h2>
          <p>
            Companies House <strong>00030209</strong> · Knightsbridge · revenues route
            direct to <strong>BRMSTE PayPal</strong> · GOV.UK API filed.
          </p>
        </div>
        <a className="btn primary" href={site.links.harrods}>
          Banking rails
        </a>
      </div>
    </section>
  );
}
