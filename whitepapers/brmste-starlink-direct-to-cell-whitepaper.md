<div align="center">

<img src="https://brmste.com/substrate/glasses/brmste-logo-primary.svg" alt="BRMSTE" width="420"/>

# Starlink Direct to Cell × BRMSTE GSI™

## Sky-Lifeline Connectivity for the Substrate Edge Fleet · Technical Whitepaper v1.0

</div>

---

**BRMSTE LTD · Companies House 15310393**
**GSI™ — Global Substrate Infrastructure™**
**Patent: GB2607860 · PCT/GB2026/050406**
**Beneficiary: Dimpy Bansal · Dimpy Bansal Trust**
**Operator: Shravan Bansal · BRMSTE LTD**

*BRMSTE™ and GSI — Global Substrate Infrastructure™ are trademarks of BRMSTE LTD (Companies House 15310393). "Starlink", "Direct to Cell", and "SpaceX" are trademarks of Space Exploration Technologies Corp.; their use here is descriptive and nominative only and implies no endorsement or partnership.*

---

## Abstract

The **BRMSTE Global Substrate Infrastructure (GSI™)** runs a geographically distributed fleet of
substrate edge nodes — mining pool workers, Re-Tyre™ collection sites, and field telemetry units —
many of which sit beyond reliable terrestrial coverage. This whitepaper specifies how **Starlink
Direct to Cell (DtC)** is adopted as the **sky-lifeline tier** of the GSI connectivity stack: a
last-resort, phone-grade satellite channel that keeps every node addressable for heartbeat,
attestation, command-and-control, and ledger-hydration failover even when fibre, terrestrial
cellular, and the fixed Starlink user terminal are all unavailable.

Direct to Cell is **not** a broadband replacement. It is a *survivability* primitive. GSI treats it
as the bottom rung of a four-tier connectivity ladder, fences it behind the same HTTPS-only,
patent-enforced, secret-free governance as every other GSI surface, and budgets it for the narrow,
high-value traffic classes that must never go dark.

---

## 1. Introduction

### 1.1 What is Starlink Direct to Cell?

Starlink Direct to Cell turns specially equipped low-Earth-orbit (LEO) satellites into
**space-based LTE base stations**. A satellite carrying the DtC payload runs an on-board **eNodeB**
(LTE base station) modem behind large phased-array antennas and broadcasts on a mobile network
operator's (MNO) **licensed terrestrial spectrum**. To a standard, unmodified LTE handset on the
ground, that satellite simply looks like another cell tower — a roaming `eNodeB` — so the phone
attaches with **no special hardware, firmware, antenna, or app**.

Service is delivered in phases by capability:

1. **Text (SMS)** — first to launch and the most robust low-bandwidth lane.
2. **IoT / low-rate data** — sensor telemetry and basic messaging at modest speeds.
3. **Voice and broader data** — higher link-budget services, arriving later in the rollout.

For GSI, the first two phases are exactly the traffic profile that matters: small, infrequent,
critical packets that keep a remote node *alive on the map*.

### 1.2 Why GSI cares

The GSI thesis is **traceable compute at the edge**. Edge nodes are deliberately placed where the
work is — quarry-adjacent mining sites, tyre-recovery yards, mobile processing rigs — and those
places routinely have weak or absent terrestrial connectivity. A node that cannot phone home
cannot:

- emit its **heartbeat** and health telemetry,
- receive a **command-and-control** instruction (pause, rotate key, safe-shutdown),
- confirm a **GB2607860 edge attestation**, or
- drain its **ledger-hydration** queue to the Foundry.

Direct to Cell gives every GSI node a **device-grade lifeline** that rides an MNO's existing
spectrum from space, independent of the node's primary backhaul. It closes the "dead-zone gap"
without shipping a second dish to every site.

---

## 2. How Direct to Cell Works

### 2.1 The "space tower" model

Each DtC satellite behaves as a transparent extension of the partner MNO's terrestrial network — an
`eNodeB` that happens to be ~550 km overhead and moving at roughly 27,000 km/h relative to the
ground. As it rises, transits, and sets, the network performs **satellite-to-satellite handoff** so
the serving cell changes seamlessly beneath the user.

```
   [ GSI edge node / standard LTE device ]
                  | LTE uplink on MNO licensed spectrum (~1.6–2.7 GHz)
                  v
        ( DtC satellite : on-board eNodeB + phased array )
                  | inter-satellite laser links (optical mesh)
                  v
          ( Starlink ground gateway : feeder link )
                  |
                  v
        [ Partner MNO core network ] --> [ GSI HTTPS edge / Foundry ]
```

### 2.2 The two physics problems (and how they are solved on-orbit)

| Problem | Cause | On-satellite mitigation |
|---------|-------|--------------------------|
| **Doppler shift** | Orbital velocity shifts the carrier frequency far beyond normal LTE tolerance | Software-defined radio computes per-device Doppler and **pre-compensates** the transmitted frequency, so the ground device sees an apparently stationary source |
| **Propagation delay** | At ~550 km the round trip is tens of milliseconds vs. fractions of a ms terrestrially | **Extended Timing Advance (TA)** values well beyond standard LTE keep uplink transmissions synchronised |

The handset's baseband never has to know any of this — the satellite does the work so the device
stays "stock LTE".

### 2.3 Spectrum and regulation

DtC operates on the **partner MNO's licensed mobile spectrum**, not on Starlink's Ku/Ka broadband
bands. Observed examples include mid-band PCS (≈1.9 GHz) in some markets and Band 3 (1800 MHz) in
others, within an approximate **1.6–2.7 GHz** working range. Regulatory enablement comes from
frameworks such as the FCC's **Supplemental Coverage from Space (SCS)** authorisation, under which
the MNO retains primary spectrum rights and the satellite operates as a secondary provider. Coverage
is further shaped by **ITU Radio Regulations** (e.g. power-flux-density limits and geographic
coordination), which is why DtC availability is **market-by-market**, gated on the local MNO
partnership.

> **GSI implication:** Direct-to-Cell reachability is a function of *where the node is* and *which
> MNO serves that geography*. GSI provisioning must record the per-site MNO and confirm SCS/DtC
> availability before a node may rely on the sky-lifeline tier.

### 2.4 What to expect on the link

- **Latency:** roughly **50–100 ms** when routed over inter-satellite laser links; higher (often
  **150–250 ms**) when gateway-routed. Acceptable for messaging, telemetry, and control; not for
  latency-sensitive interactive workloads.
- **Throughput:** modest and **shared** across every device in the satellite's footprint. Plan for
  SMS-class and low-rate IoT/data, not bulk transfer.
- **Posture:** a coverage-of-last-resort lane to **eliminate not-spots**, complementary to — never a
  substitute for — primary backhaul.

---

## 3. GSI Connectivity Architecture

### 3.1 The four-tier connectivity ladder

GSI nodes select the **highest-available** tier and fail downward automatically. Direct to Cell is
**Tier 4**: the lane that must keep working when everything above it has failed.

| Tier | Bearer | Role | Typical use |
|------|--------|------|-------------|
| **T1 — Fibre / wired** | Terrestrial broadband | Primary | Full ELT hydrate, OTA, bulk sync |
| **T2 — Terrestrial cellular** | 4G/5G modem | Primary failover | Hydrate + telemetry when wired is down |
| **T3 — Starlink user terminal** | Ku/Ka dish | Remote primary | Broadband for off-grid sites with a dish |
| **T4 — Starlink Direct to Cell** | LTE-from-space | **Sky lifeline** | Heartbeat, control, attestation, hydrate-queue drip |

### 3.2 Traffic classes mapped to Tier 4

When a node drops to the sky-lifeline tier, GSI restricts traffic to a minimal, prioritised set:

| Class | Direction | Budget | Why it rides the lifeline |
|-------|-----------|--------|----------------------------|
| **Heartbeat / health** | Node → GSI | Tiny, periodic | Proves the node is alive and located |
| **Command & control** | GSI → Node | Tiny, on-demand | Pause, key-rotate, safe-shutdown, config flip |
| **Edge attestation** | Node → Foundry | Small | GB2607860 trace continuity must not break |
| **Ledger-hydrate drip** | Node → Foundry | Throttled queue | Highest-value records trickle out; bulk waits for T1–T3 |
| **Alarm / SOS** | Node → Ops | Tiny, priority | Tamper, thermal, or power events escalate immediately |

Everything else (bulk ELT, software images, logs) is **deferred** until a higher tier returns.

### 3.3 Failover and recovery behaviour

- **Detection:** loss of T1–T3 for a configured dwell window triggers the lifeline attach.
- **Backoff:** lifeline transmits on jittered intervals to respect shared-beam capacity and PFD
  limits; non-critical classes are dropped first under congestion.
- **Store-and-forward:** the hydrate queue persists locally and **replays in priority order** when a
  higher tier is restored — no record is lost, only delayed.
- **Hysteresis:** GSI requires stable higher-tier connectivity before climbing back up, to avoid
  flapping between bearers.

---

## 4. Security and Governance

Direct to Cell does not get a governance exception. The sky-lifeline tier is held to the same
BRMSTE standard as every GSI surface.

### 4.1 Transport and identity

- **HTTPS-only with HSTS** end-to-end: the satellite link is *bearer*, not *trust*. All GSI traffic
  over DtC terminates on the same TLS-secured, HSTS-preloaded GSI edges.
- **Mutual authentication:** nodes authenticate to GSI with per-node credentials; the DtC bearer is
  never treated as an implicitly trusted network.
- **No secrets in transit assumptions:** the channel is assumed observable; confidentiality and
  integrity come from the application-layer TLS + signing, not from the radio.

### 4.2 Secret and key management

- Per-node lifeline credentials live in **GitHub Environments + org secrets**, never in git.
- `config/cf-workers.env`, wallet keys, and RPC credentials are **never committed** and never sent
  in the clear.
- Suspected exposure triggers rotation via the **command-and-control** class above.

### 4.3 Brand + patent gate

Every repository describing or configuring the lifeline tier passes `brmste-brand-patent-gate` on
push/PR to `main`. The gate:

1. Requires `PATENT-NOTICE.md` citing **GB2607860** and **PCT/GB2026/050406** and naming **BRMSTE LTD**.
2. Requires the README to reference **BRMSTE**.
3. Scans every `*.svg/*.png/*.jpg/*.jpeg/*.webp/*.gif` URL and rejects any logo not served from a
   canonical BRMSTE origin (`brmste.com`, `brmste.ai`, `raw.githubusercontent.com/BRMSTE-SB/`).
4. Rejects non-HTTPS asset URLs.
5. (Fort Knox lane) verifies the reusable caller workflow is present.

### 4.4 Trademark display rules

- **BRMSTE™** and **GSI™** appear with the ™ symbol on first use; **Global Substrate Infrastructure™**
  appears in full at least once per document.
- Third-party marks (Starlink, Direct to Cell, SpaceX) are used **nominatively** — descriptively, to
  identify the technology — and carry no implication of endorsement, partnership, or affiliation.

---

## 5. Re-Tyre Integration

**Re-Tyre™** — the BRMSTE circular tyre economy — operates collection and processing sites that are
often the very definition of "off-grid". The sky-lifeline tier lets Re-Tyre nodes:

- write **tyre collection / processing events** to the Foundry ledger as throttled hydrate drips,
- carry a **GSI edge trace (GB2607860 reference)** on every event even from a dead-zone yard, and
- receive **safe-shutdown / route-change** commands during field operations.

The result: a verifiable carbon-cycle record that does not develop gaps simply because a site lacks
terrestrial coverage.

---

## 6. Constraints and Honest Limitations

GSI states the boundaries plainly:

- **Availability is geographic and MNO-dependent.** No partner / no SCS in a market means no
  lifeline there. Provisioning must verify per-site coverage; the lifeline is a *bonus tier*, not an
  assumed one.
- **Capacity is shared and small.** Tier 4 carries control and the most valuable records only — never
  bulk ELT.
- **Latency varies** with routing (ISL vs. gateway) and is unsuitable for interactive or
  time-critical control loops.
- **Rollout is phased.** Text and low-rate IoT/data are the dependable lanes today; voice and richer
  data mature over the rollout. GSI designs to the conservative (text/IoT) envelope.
- **Regulatory limits apply.** PFD ceilings, exclusion zones, and ITU coordination constrain when and
  where the bearer is usable.

Designing GSI to the *floor* of these constraints is deliberate: the lifeline is valuable precisely
because it is dependable within its narrow envelope.

---

## 7. Roadmap

| Milestone | Description |
|-----------|-------------|
| **SLC v1.0** | Tier-4 sky-lifeline defined · heartbeat + attestation classes carried over DtC text/IoT |
| **SLC v1.1** | Per-site MNO/SCS coverage registry · automated lifeline-eligibility provisioning |
| **SLC v1.2** | Priority store-and-forward hydrate queue with hysteresis-based tier climb-back |
| **SLC v2.0** | Command-and-control over lifeline (pause / key-rotate / safe-shutdown) hardened + audited |
| **SLC v2.1** | Re-Tyre off-grid yards default-enrolled in lifeline tier |
| **SLC v3.0** | Voice/expanded-data lanes adopted where mature; latency-aware class routing |

---

## 8. Conclusion

Starlink Direct to Cell does not change what GSI is — it changes **how far GSI can reach without
going dark**. By treating DtC as a disciplined, governance-fenced **sky-lifeline tier** rather than a
broadband promise, GSI keeps every substrate edge node addressable for the traffic that truly
matters: heartbeat, control, attestation, and the highest-value ledger records.

The GSI mark on a node guarantees the same thing it always has — patent compliance, HTTPS/HSTS-only
transport, canonical brand assets, and automated git-worker enforcement — now extended to a node
that can phone home **from a dead zone, over a standard cellular channel, from space**.

---

## References

The following public sources informed the technical description in §2. They are descriptive
references only; BRMSTE LTD is not affiliated with the cited parties.

- SpaceX / Starlink — Direct to Cell first-text update and program overview.
- FCC — Supplemental Coverage from Space (SCS) regulatory framework (2024).
- ITU Radio Regulations — non-terrestrial spectrum coordination and power-flux-density limits.
- Independent technical analyses of Direct-to-Cell / 3GPP Non-Terrestrial Networks (NTN).

---

## Trademark & Patent Notice

BRMSTE™ and GSI — Global Substrate Infrastructure™ are trademarks of BRMSTE LTD
(Companies House 15310393). Patent GB2607860 · PCT/GB2026/050406.

"Starlink", "Direct to Cell", and "SpaceX" are trademarks of Space Exploration Technologies Corp.,
used here nominatively to describe the technology; no endorsement or partnership is implied.

**Beneficiary:** Dimpy Bansal · Dimpy Bansal Trust
**Operator:** Shravan Bansal · BRMSTE LTD

CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS

Live patent enforcement: https://brmste.com/substrate/patent-enforcement.json

© BRMSTE LTD · Companies House 15310393 · All rights reserved.
