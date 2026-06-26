/** PSC04 + CH01 correspondence filing helpers (BRMSTE LTD). */

export function todayIso() {
  return new Date().toISOString().slice(0, 10);
}

export function pscAddressDto(canonical) {
  if (!canonical) return {};
  const dto = {
    premises: canonical.premises || "",
    address_line_1: canonical.address_line_1 || "",
    locality: canonical.locality || "",
    postalCode: canonical.postal_code || "",
    country: canonical.country || "United Kingdom",
  };
  if (canonical.address_line_2) dto.address_line_2 = canonical.address_line_2;
  if (canonical.region) dto.region = canonical.region;
  return Object.fromEntries(Object.entries(dto).filter(([, v]) => v));
}

export function extractResourceId(payload) {
  if (!payload) return null;
  if (payload.id) return String(payload.id);
  const selfLink = payload.links?.self || "";
  if (selfLink) return selfLink.replace(/\/$/, "").split("/").pop();
  return null;
}

export function parseAppointmentId(officerItem) {
  const selfLink = officerItem?.links?.self || "";
  if (!selfLink) throw new Error("officer_missing_links_self");
  return selfLink.replace(/\/$/, "").split("/").pop();
}

export function parsePscId(pscItem) {
  const selfLink = pscItem?.links?.self || "";
  if (!selfLink) throw new Error("psc_missing_links_self");
  return selfLink.replace(/\/$/, "").split("/").pop();
}

export function findDirector(officersPayload) {
  for (const item of officersPayload?.items || []) {
    if (item.officer_role === "director" && !item.resigned_on) return item;
  }
  throw new Error("no_active_director");
}

export function findIndividualPsc(pscListPayload) {
  for (const item of pscListPayload?.items || []) {
    if (
      item.kind === "individual-person-with-significant-control" &&
      !item.ceased_on
    ) {
      return item;
    }
  }
  throw new Error("no_active_individual_psc");
}

export function buildCh01PatchBody(directorItem, appointment, canonical) {
  return {
    referenceAppointmentId: parseAppointmentId(directorItem),
    referenceEtag: appointment?.etag || directorItem?.etag || "",
    referenceOfficerListEtag: directorItem?.etag || "",
    serviceAddress: pscAddressDto(canonical),
    residentialAddressSameAsServiceAddress: true,
  };
}

export function buildPsc04PatchBody(pscLive, pscId, canonical) {
  const nameElements = pscLive?.name_elements || {};
  const dob = pscLive?.date_of_birth || {};
  return {
    referencePscId: pscId,
    referenceEtag: pscLive?.etag || "",
    registerEntryDate: todayIso(),
    address: pscAddressDto(canonical),
    residentialAddressSameAsCorrespondenceAddress: true,
    nationality: pscLive?.nationality || "",
    countryOfResidence: pscLive?.country_of_residence || "United Kingdom",
    nameElements: {
      title: nameElements.title || "",
      forename: nameElements.forename || "",
      surname: nameElements.surname || "",
    },
    dateOfBirth: { month: dob.month, year: dob.year },
    naturesOfControl: pscLive?.natures_of_control || [],
  };
}

export function correspondenceUpdateRequired(bundle, livePscPostal, liveOfficerPostal) {
  const target = bundle?.brmste?.horseferry_canonical?.postal_code || "SW1P 2FE";
  const norm = (s) => String(s || "").replace(/\s/g, "").toUpperCase();
  return norm(livePscPostal) !== norm(target) || norm(liveOfficerPostal) !== norm(target);
}

export const BRMSTE_OAUTH_SCOPES = [
  "https://identity.company-information.service.gov.uk/user/profile.read",
  "https://api.company-information.service.gov.uk/company/15310393/registered-office-address.update",
  "https://api.company-information.service.gov.uk/company/15310393/registered-email-address.update",
  "https://api.company-information.service.gov.uk/company/15310393/officers.update",
  "https://api.company-information.service.gov.uk/company/15310393/persons-with-significant-control.update",
];
