import { site } from "../data/site";

export function Header() {
  return (
    <header className="header glass">
      <a className="brand" href="#top">
        <img
          src="https://brmste.com/substrate/glasses/brmste-logo-primary.svg"
          alt="BRMSTE"
          width={160}
          height={40}
        />
      </a>
      <nav className="nav">
        <a href="#lanes">Lanes</a>
        <a href="#harrods">Harrods</a>
        <a href="#carbon">Carbon justice</a>
        <a href={site.links.github} target="_blank" rel="noreferrer">
          GitHub
        </a>
        <a href={site.links.linkedin} target="_blank" rel="noreferrer">
          LinkedIn
        </a>
      </nav>
    </header>
  );
}
