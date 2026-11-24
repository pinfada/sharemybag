//= require popper
//= require bootstrap

document.addEventListener("DOMContentLoaded", function () {
  var formatEuros = function (amount) {
    if (isNaN(amount)) return "—";
    var sign = amount < 0 ? "−" : "";
    return sign + "€" + Math.abs(amount).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  };

  var formatWholeEuros = function (amount) {
    if (isNaN(amount)) return "—";
    var sign = amount < 0 ? "−" : "";
    return sign + "€" + Math.round(Math.abs(amount)).toLocaleString("en-US");
  };

  var formatCompactMillions = function (amount) {
    if (isNaN(amount)) return "—";
    var sign = amount < 0 ? "−" : "";
    var abs = Math.abs(amount);
    if (abs >= 1000000) {
      return sign + "€" + (abs / 1000000).toFixed(2) + "M";
    }
    return formatWholeEuros(amount);
  };

  // 1. Live Order Book Trade Estimator + Pre-Fill Best Market Price Buttons on /flights/:id
  var orderForm = document.querySelector("[data-order-form]");
  if (orderForm) {
    var sideInputs = orderForm.querySelectorAll("input[name='kilo_order[side]']");
    var qtyInput = orderForm.querySelector("[data-order-qty]");
    var priceInput = orderForm.querySelector("[data-order-price]");
    var payoutSelect = orderForm.querySelector("[data-order-payout]");
    var payoutGroup = orderForm.querySelector("[data-payout-group]");
    var outputEl = orderForm.querySelector("[data-order-estimate-output]");

    var airportFee = parseFloat(orderForm.getAttribute("data-airport-fee-euros") || "15");
    var commissionRate = parseFloat(orderForm.getAttribute("data-commission-rate") || "0.25");

    var selectedSide = function () {
      var checked = orderForm.querySelector("input[name='kilo_order[side]']:checked");
      return checked ? checked.value : "sell";
    };

    var updateOrderEstimate = function () {
      var side = selectedSide();
      if (payoutGroup) {
        payoutGroup.classList.toggle("d-none", side === "buy");
      }

      var qty = parseFloat((qtyInput && qtyInput.value || "").replace(",", "."));
      var price = parseFloat((priceInput && priceInput.value || "").replace(",", "."));

      if (!outputEl) return;
      if (isNaN(qty) || qty <= 0 || isNaN(price) || price <= 0) {
        outputEl.textContent = "Enter weight (kg) and limit price (€/kg) to preview settlement.";
        return;
      }

      var gross = qty * price;
      var fee = gross * commissionRate;
      if (side === "sell") {
        var netPayout = gross - fee;
        var payoutLabel = (payoutSelect && payoutSelect.value === "cash") ? "cash refund" : "airline flight voucher";
        outputEl.textContent =
          "Estimated net payout: +" + formatEuros(netPayout) + " (" + payoutLabel + ") · " +
          "Gross " + formatEuros(gross) + " − " + Math.round(commissionRate * 100) + "% airline fee (" + formatEuros(fee) + ").";
      } else {
        var airportTotal = qty * airportFee;
        var savings = Math.max(airportTotal - gross, 0);
        outputEl.textContent =
          "Estimated max cost: " + formatEuros(gross) + " vs " + formatEuros(airportTotal) + " at airport desk · " +
          "You save +" + formatEuros(savings) + " (" + (airportTotal > 0 ? Math.round((savings / airportTotal) * 100) : 0) + "% less).";
      }
    };

    sideInputs.forEach(function (el) { el.addEventListener("change", updateOrderEstimate); });
    if (qtyInput) qtyInput.addEventListener("input", updateOrderEstimate);
    if (priceInput) priceInput.addEventListener("input", updateOrderEstimate);
    if (payoutSelect) payoutSelect.addEventListener("change", updateOrderEstimate);

    // Pre-fill best market price buttons (honestly pre-fills form without auto-submitting)
    document.querySelectorAll("[data-quick-fill-side]").forEach(function (btn) {
      btn.addEventListener("click", function () {
        var targetSide = btn.getAttribute("data-quick-fill-side");
        var targetQty = btn.getAttribute("data-quick-fill-qty");
        var targetPrice = btn.getAttribute("data-quick-fill-price");

        var radio = orderForm.querySelector("input[name='kilo_order[side]'][value='" + targetSide + "']");
        if (radio) radio.checked = true;
        if (qtyInput && targetQty) qtyInput.value = targetQty;
        if (priceInput && targetPrice) priceInput.value = targetPrice;
        updateOrderEstimate();
        if (qtyInput) qtyInput.focus();
      });
    });

    updateOrderEstimate();
  }

  // 2. Accessible Mobile Order Book Buy / Sell Tabs (< 768px)
  document.querySelectorAll("[data-orderbook-tabs]").forEach(function (tablist) {
    var tabs = tablist.querySelectorAll("[role='tab']");
    var scope = tablist.closest("[data-orderbook-scope]") || document;
    tabs.forEach(function (tab) {
      tab.addEventListener("click", function () {
        var targetName = tab.getAttribute("data-book-target");
        tabs.forEach(function (t) {
          t.setAttribute("aria-selected", t === tab ? "true" : "false");
        });
        scope.querySelectorAll("[data-book-panel]").forEach(function (panel) {
          panel.classList.toggle("is-mobile-active", panel.getAttribute("data-book-panel") === targetName);
        });
      });
    });
  });

  // 3. CFO Annual Fleet ROI & Dual-Cannibalization Simulator on /airline-roi (aria-live="polite")
  var roiSim = document.querySelector("[data-roi-simulator]");
  if (roiSim) {
    var flightsEl = roiSim.querySelector("[data-roi-daily-flights]");
    var kgEl = roiSim.querySelector("[data-roi-kg-per-flight]");
    var unusedEl = roiSim.querySelector("[data-roi-unused-rate]");
    var spotEl = roiSim.querySelector("[data-roi-spot-price]");
    var commEl = roiSim.querySelector("[data-roi-commission]");
    var voucherEl = roiSim.querySelector("[data-roi-voucher-rate]");
    var durationEl = roiSim.querySelector("[data-roi-duration]");
    var excessEl = roiSim.querySelector("[data-roi-airport-fee]");
    var cannibEl = roiSim.querySelector("[data-roi-cannibalization]");
    var bookingCannibEl = roiSim.querySelector("[data-roi-booking-cannib]");
    var bookingFeeEl = roiSim.querySelector("[data-roi-booking-fee]");

    var outRange = roiSim.querySelector("[data-roi-incremental-range]");
    var outMargin = roiSim.querySelector("[data-roi-annual-margin]");
    var outIncremental = roiSim.querySelector("[data-roi-incremental-profit]");
    var outCommission = roiSim.querySelector("[data-roi-annual-commission]");
    var outVoucher = roiSim.querySelector("[data-roi-annual-voucher]");
    var outVoucherMargin = roiSim.querySelector("[data-roi-voucher-margin]");
    var outFuel = roiSim.querySelector("[data-roi-annual-fuel]");
    var outBookingCannib = roiSim.querySelector("[data-roi-booking-cannib-deduction]");
    var outCannibDeduction = roiSim.querySelector("[data-roi-cannibalization-deduction]");
    var outSavings = roiSim.querySelector("[data-roi-annual-savings]");
    var outCash = roiSim.querySelector("[data-roi-annual-cash]");
    var outCheckinHours = roiSim.querySelector("[data-roi-checkin-hours]");

    var updateRoi = function () {
      var dailyFlights = parseFloat(flightsEl && flightsEl.value) || 0;
      var kgPerFlight = parseFloat(kgEl && kgEl.value) || 0;
      var unusedPct = parseFloat(unusedEl && unusedEl.value) || 35;
      var spotPrice = parseFloat(spotEl && spotEl.value) || 0;
      var commissionPct = parseFloat(commEl && commEl.value) || 0;
      var voucherPct = parseFloat(voucherEl && voucherEl.value) || 0;
      var durationH = parseFloat(durationEl && durationEl.value) || 0;
      var excessFee = parseFloat(excessEl && excessEl.value) || 0;
      var counterCannibPct = parseFloat(cannibEl && cannibEl.value) || 0;
      var bookingCannibPct = parseFloat(bookingCannibEl && bookingCannibEl.value) || 0;
      var bookingFee = parseFloat(bookingFeeEl && bookingFeeEl.value) || 10;

      var unusedScale = unusedPct / 35.0;
      var annualKg = dailyFlights * 365 * kgPerFlight * unusedScale;
      var gross = annualKg * spotPrice;
      var commission = gross * (commissionPct / 100.0);
      var sellerPayout = gross - commission;
      var retainedVoucher = sellerPayout * (voucherPct / 100.0);
      var voucherRebookingMargin = retainedVoucher * 0.30;
      var fuelPerKg = 0.035 * durationH * 1.10;
      var fuelCost = annualKg * fuelPerKg;
      var netMargin = commission - fuelCost;

      var bookingCannibDeduction = annualKg * (bookingCannibPct / 100.0) * Math.max(bookingFee - fuelPerKg, 0);
      var counterCannibDeduction = annualKg * (counterCannibPct / 100.0) * Math.max(excessFee - fuelPerKg, 0);
      var incrementalProfit = netMargin + voucherRebookingMargin - bookingCannibDeduction - counterCannibDeduction;
      var incrementalLow = incrementalProfit * 0.70;

      var totalCashRetained = commission + retainedVoucher;
      var paxSavings = annualKg * Math.max(excessFee - spotPrice, 0);
      var checkinHours = Math.round((annualKg / 10.0) * 4.0 / 60.0);

      if (outRange) {
        outRange.textContent = formatCompactMillions(incrementalLow) + " – " + formatCompactMillions(incrementalProfit) + " / yr";
      }
      if (outMargin) outMargin.textContent = (netMargin >= 0 ? "+" : "") + formatWholeEuros(netMargin);
      if (outIncremental) outIncremental.textContent = (incrementalProfit >= 0 ? "+" : "") + formatWholeEuros(incrementalProfit);
      if (outCommission) outCommission.textContent = "+" + formatWholeEuros(commission);
      if (outVoucher) outVoucher.textContent = formatWholeEuros(retainedVoucher);
      if (outVoucherMargin) outVoucherMargin.textContent = "+" + formatWholeEuros(voucherRebookingMargin);
      if (outFuel) outFuel.textContent = "−" + formatWholeEuros(fuelCost);
      if (outBookingCannib) outBookingCannib.textContent = "−" + formatWholeEuros(bookingCannibDeduction);
      if (outCannibDeduction) outCannibDeduction.textContent = "−" + formatWholeEuros(counterCannibDeduction);
      if (outSavings) outSavings.textContent = formatWholeEuros(paxSavings);
      if (outCash) outCash.textContent = formatWholeEuros(totalCashRetained);
      if (outCheckinHours) outCheckinHours.textContent = checkinHours.toLocaleString("en-US") + " hrs/yr";
    };

    [flightsEl, kgEl, unusedEl, spotEl, commEl, voucherEl, durationEl, excessEl, cannibEl, bookingCannibEl, bookingFeeEl].forEach(function (el) {
      if (el) el.addEventListener("input", updateRoi);
    });
    updateRoi();
  }

  // 4. Home Live Departure Desk 3-Party Settlement Simulator (aria-live="polite")
  var homeSim = document.querySelector("[data-home-trade-sim]");
  if (homeSim) {
    var homeKgInput = homeSim.querySelector("[data-home-sim-kg]");
    var homeKgLabel = homeSim.querySelector("[data-home-sim-kg-label]");
    var outSeller = homeSim.querySelector("[data-home-sim-seller]");
    var outSellerPnr = homeSim.querySelector("[data-home-sim-seller-pnr]");
    var outBuyer = homeSim.querySelector("[data-home-sim-buyer]");
    var outBuyerSave = homeSim.querySelector("[data-home-sim-buyer-save]");
    var outAirline = homeSim.querySelector("[data-home-sim-airline]");

    var simPrice = parseFloat(homeSim.getAttribute("data-sim-price") || "7.5");
    var simAirportFee = parseFloat(homeSim.getAttribute("data-sim-airport-fee") || "15");
    var simComm = parseFloat(homeSim.getAttribute("data-sim-commission") || "0.25");
    var simDuration = parseFloat(homeSim.getAttribute("data-sim-duration") || "5.5");
    var simBurn = parseFloat(homeSim.getAttribute("data-sim-burn") || "0.035");

    var updateHomeSim = function () {
      var kg = parseInt(homeKgInput && homeKgInput.value, 10) || 8;
      var gross = kg * simPrice;
      var fee = gross * simComm;
      var sellerPayout = gross - fee;
      var fuelCost = kg * simBurn * simDuration * 1.10;
      var netMargin = fee - fuelCost;
      var savings = Math.max((simAirportFee - simPrice) * kg, 0);

      if (homeKgLabel) homeKgLabel.textContent = kg + " kg";
      if (outSeller) outSeller.textContent = "+" + formatEuros(sellerPayout);
      if (outSellerPnr) outSellerPnr.textContent = "PNR 23 → " + (23 - kg) + " kg";
      if (outBuyer) outBuyer.textContent = formatEuros(gross);
      if (outBuyerSave) outBuyerSave.textContent = "Saves +" + formatEuros(savings);
      if (outAirline) outAirline.textContent = "+" + formatEuros(netMargin);
    };

    if (homeKgInput) homeKgInput.addEventListener("input", updateHomeSim);
    updateHomeSim();
  }

  // 5. Accessible confirmation on destructive or binding actions
  document.querySelectorAll("form[data-confirm-message]").forEach(function (form) {
    form.addEventListener("submit", function (event) {
      var message = form.getAttribute("data-confirm-message");
      if (message && !window.confirm(message)) {
        event.preventDefault();
      }
    });
  });

  // 6. Move keyboard focus to error summary when a form returns validation errors
  var errorSummary = document.querySelector("[data-error-summary]");
  if (errorSummary) {
    errorSummary.focus();
  }
});
