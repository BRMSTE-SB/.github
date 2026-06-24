import { Header } from "./components/Header";
import { Hero } from "./components/Hero";
import { LaneGrid } from "./components/LaneGrid";
import { HarrodsRail } from "./components/HarrodsRail";
import { Footer } from "./components/Footer";
import { site } from "./data/site";

export default function App() {
  return (
    <div className="page">
      <Header />
      <main>
        <Hero />
        <LaneGrid lanes={site.lanes} />
        <HarrodsRail />
        <section className="panel glass" id="carbon">
          <h2>Carbon justice</h2>
          <p>{site.carbonJustice}</p>
          <a className="link" href={site.links.carbonJustice}>
            Read CARBON-JUSTICE.md
          </a>
        </section>
      </main>
      <Footer />
    </div>
  );
}
