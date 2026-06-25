export interface LaneCard {
  id: string;
  title: string;
  subtitle: string;
  status: string;
  href?: string;
}

export interface FortKnoxSummary {
  headline: string;
  doctrine: string;
  envVarCount: number;
  scriptCount: number;
  railCount: number;
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
  fortKnox: FortKnoxSummary;
  lanes: LaneCard[];
  links: {
    github: string;
    openAll: string;
    glasswing: string;
    carbonJustice: string;
    harrods: string;
    fortKnoxCorpus: string;
    fortKnoxDocs: string;
    substrate: string;
    linkedin: string;
  };
}

import generated from "./generated-content.json";

export const site = generated as SiteContent;
