/**
 * BRMSTE banking net worth valuation from eToro clientPortfolio.
 * Mirrors scripts/lib/etoro-networth.py (eToro equity guide).
 */

function num(value) {
  if (value === null || value === undefined) return 0;
  return Number(value) || 0;
}

function positionPnl(position) {
  const unrealized = position?.unrealizedPnL;
  if (unrealized && typeof unrealized === "object") {
    return num(unrealized.pnL);
  }
  return num(unrealized);
}

function reservedOpenOrders(portfolio) {
  let reserved = 0;
  for (const order of portfolio.ordersForOpen ?? []) {
    if (num(order.mirrorID) === 0) reserved += num(order.amount);
  }
  for (const order of portfolio.orders ?? []) {
    reserved += num(order.amount);
  }
  return reserved;
}

function totalInvested(portfolio) {
  let invested = 0;

  for (const position of portfolio.positions ?? []) {
    invested += num(position.amount);
  }

  for (const mirror of portfolio.mirrors ?? []) {
    invested += num(mirror.availableAmount) - num(mirror.closedPositionsNetProfit);
    for (const position of mirror.positions ?? []) {
      invested += num(position.amount);
    }
  }

  for (const order of portfolio.ordersForOpen ?? []) {
    if (num(order.mirrorID) === 0) {
      invested += num(order.amount);
      invested += num(order.totalExternalCosts);
    }
  }

  for (const order of portfolio.orders ?? []) {
    invested += num(order.amount);
  }

  return invested;
}

function unrealizedPnl(portfolio) {
  let pnl = 0;

  for (const position of portfolio.positions ?? []) {
    pnl += positionPnl(position);
  }

  for (const mirror of portfolio.mirrors ?? []) {
    pnl += num(mirror.closedPositionsNetProfit);
    for (const position of mirror.positions ?? []) {
      pnl += positionPnl(position);
    }
  }

  return pnl;
}

export function computeValuation(portfolio, options = {}) {
  const {
    currency = "USD",
    source = "etoro_pnl",
    environment = null,
  } = options;

  const credit = num(portfolio.credit);
  const bonusCredit = num(portfolio.bonusCredit);
  const reservedOrders = reservedOpenOrders(portfolio);
  const availableCash = credit - reservedOrders;
  const invested = totalInvested(portfolio);
  const unrealized = unrealizedPnl(portfolio);
  const equity = availableCash + invested + unrealized;

  const positions = portfolio.positions ?? [];
  const mirrors = portfolio.mirrors ?? [];

  return {
    schema: "brmste-banking-networth-valuation/v1",
    source,
    currency,
    environment,
    asOf: new Date().toISOString(),
    cash: {
      credit: round2(credit),
      bonusCredit: round2(bonusCredit),
      reservedOrders: round2(reservedOrders),
      availableCash: round2(availableCash),
    },
    invested: {
      totalInvested: round2(invested),
      openPositions: positions.length,
      activeMirrors: mirrors.length,
    },
    pnl: {
      unrealized: round2(unrealized),
    },
    netWorth: {
      equity: round2(equity),
      label: "Real-time cash net worth (banking valuation)",
    },
    formula: {
      equity: "availableCash + totalInvested + unrealizedPnL",
      docs: "https://api-portal.etoro.com/guides/calculate-equity",
    },
  };
}

export function valuationFromPnlResponse(payload, options = {}) {
  const portfolio = payload?.clientPortfolio;
  if (!portfolio || typeof portfolio !== "object") {
    throw new Error("payload missing clientPortfolio object");
  }
  return computeValuation(portfolio, options);
}

function round2(value) {
  return Math.round(value * 100) / 100;
}
