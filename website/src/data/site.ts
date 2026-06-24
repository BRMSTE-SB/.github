export interface LaneCard {
  id: string;
  title: string;
  subtitle: string;
  status: string;
  href?: string;
}

export interface SiteContent {
  operator: string;
  company: string;
  patent: string;
  headline: string;
  tagline: string;
  glasswing: string;
  carbonJustice: string;
  nemotron: {
    model: string;
    role: string;
  };
  lanes: LaneCard[];
  links: {
    github: string;
    openAll: string;
    glasswing: string;
    carbonJustice: string;
    harrods: string;
    substrate: string;
  };
}

import generated from "./generated-content.json";

export const site = generated as SiteContent;
