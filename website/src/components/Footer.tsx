import { site } from "../data/site";

export function Footer() {
  return (
    <footer className="footer">
      <p>{site.glasswing}</p>
      <p>
        <a href={site.links.linkedin} target="_blank" rel="noreferrer">
          Dr. Shravan Bansal
        </a>
        · {site.company} · {site.patent}
      </p>
      <p className="sign-lines">CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS</p>
    </footer>
  );
}
