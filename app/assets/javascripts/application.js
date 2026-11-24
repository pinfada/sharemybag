//= require popper
//= require bootstrap

document.addEventListener("DOMContentLoaded", function () {
  var formatEuros = function (amount) {
    if (isNaN(amount)) return "—";
    var sign = amount < 0 ? "-" : "";
    return sign + "€" + Math.abs(amount).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  };

  var formatWholeEuros = function (amount) {
    if (isNaN(amount)) return "—";
    var sign = amount < 0 ? "-" : "";
    return sign + "€" + Math.round(Math.abs(amount)).toLocaleString("en-US");
  };

  // 1. Live Order Book Trade Estimator + 1-Click Cross-the-Spread Buttons on /flights/:id (RGAA 7.5)
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
          "Estimated net payout: " + formatEuros(netPayout) + " (" + payoutLabel + ") · " +
          "Gross " + formatEuros(gross) + " − " + Math.round(commissionRate * 100) + "% airline fee (" + formatEuros(fee) + ").";
      } else {
        var airportTotal = qty * airportFee;
        var savings = Math.max(airportTotal - gross, 0);
        outputEl.textContent =
          "Estimated max cost: " + formatEuros(gross) + " vs " + formatEuros(airportTotal) + " at airport desk · " +
          "You save " + formatEuros(savings) + " (" + (airportTotal > 0 ? Math.round((savings / airportTotal) * 100) : 0) + "% less).";
      }
    };

    sideInputs.forEach(function (el) { el.addEventListener("change", updateOrderEstimate); });
    if (qtyInput) qtyInput.addEventListener("input", updateOrderEstimate);
    if (priceInput) priceInput.addEventListener("input", updateOrderEstimate);
    if (payoutSelect) payoutSelect.addEventListener("change", updateOrderEstimate);

    // 1-Click Quick-Fill buttons to cross the live Bid/Ask spread immediately
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

  // 2. Interactive CFO Annual Fleet ROI & Cannibalization Simulator on /airline-roi (RGAA 7.5)
  var roiSim = document.querySelector("[data-roi-simulator]");
  if (roiSim) {
    var flightsEl = roiSim.querySelector("[data-roi-daily-flights]");
    var kgEl = roiSim.querySelector("[data-roi-kg-per-flight]");
    var spotEl = roiSim.querySelector("[data-roi-spot-price]");
    var commEl = roiSim.querySelector("[data-roi-commission]");
    var voucherEl = roiSim.querySelector("[data-roi-voucher-rate]");
    var durationEl = roiSim.querySelector("[data-roi-duration]");
    var excessEl = roiSim.querySelector("[data-roi-airport-fee]");
    var cannibEl = roiSim.querySelector("[data-roi-cannibalization]");

    var outMargin = roiSim.querySelector("[data-roi-annual-margin]");
    var outIncremental = roiSim.querySelector("[data-roi-incremental-profit]");
    var outCommission = roiSim.querySelector("[data-roi-annual-commission]");
    var outVoucher = roiSim.querySelector("[data-roi-annual-voucher]");
    var outVoucherMargin = roiSim.querySelector("[data-roi-voucher-margin]");
    var outFuel = roiSim.querySelector("[data-roi-annual-fuel]");
    var outCannibDeduction = roiSim.querySelector("[data-roi-cannibalization-deduction]");
    var outSavings = roiSim.querySelector("[data-roi-annual-savings]");
    var outCash = roiSim.querySelector("[data-roi-annual-cash]");
    var outCheckinHours = roiSim.querySelector("[data-roi-checkin-hours]");

    var updateRoi = function () {
      var dailyFlights = parseFloat(flightsEl && flightsEl.value) || 0;
      var kgPerFlight = parseFloat(kgEl && kgEl.value) || 0;
      var spotPrice = parseFloat(spotEl && spotEl.value) || 0;
      var commissionPct = parseFloat(commEl && commEl.value) || 0;
      var voucherPct = parseFloat(voucherEl && voucherEl.value) || 0;
      var durationH = parseFloat(durationEl && durationEl.value) || 0;
      var excessFee = parseFloat(excessEl && excessEl.value) || 0;
      var cannibPct = parseFloat(cannibEl && cannibEl.value) || 0;

      var annualKg = dailyFlights * 365 * kgPerFlight;
      var gross = annualKg * spotPrice;
      var commission = gross * (commissionPct / 100.0);
      var sellerPayout = gross - commission;
      var retainedVoucher = sellerPayout * (voucherPct / 100.0);
      var voucherRebookingMargin = retainedVoucher * 0.30;
      var fuelPerKg = 0.035 * durationH * 1.10;
      var fuelCost = annualKg * fuelPerKg;
      var netMargin = commission - fuelCost;

      var cannibDeduction = annualKg * (cannibPct / 100.0) * Math.max(excessFee - fuelPerKg, 0);
      var incrementalProfit = netMargin + voucherRebookingMargin - cannibDeduction;

      var totalCashRetained = commission + retainedVoucher;
      var paxSavings = annualKg * Math.max(excessFee - spotPrice, 0);
      var checkinHours = Math.round((annualKg / 10.0) * 4.0 / 60.0);

      if (outMargin) outMargin.textContent = formatWholeEuros(netMargin);
      if (outIncremental) outIncremental.textContent = formatWholeEuros(incrementalProfit);
      if (outCommission) outCommission.textContent = formatWholeEuros(commission);
      if (outVoucher) outVoucher.textContent = formatWholeEuros(retainedVoucher);
      if (outVoucherMargin) outVoucherMargin.textContent = "+" + formatWholeEuros(voucherRebookingMargin);
      if (outFuel) outFuel.textContent = "-" + formatWholeEuros(fuelCost);
      if (outCannibDeduction) outCannibDeduction.textContent = "-" + formatWholeEuros(cannibDeduction);
      if (outSavings) outSavings.textContent = formatWholeEuros(paxSavings);
      if (outCash) outCash.textContent = formatWholeEuros(totalCashRetained);
      if (outCheckinHours) outCheckinHours.textContent = checkinHours.toLocaleString("en-US") + " hrs/yr";
    };

    [flightsEl, kgEl, spotEl, commEl, voucherEl, durationEl, excessEl, cannibEl].forEach(function (el) {
      if (el) el.addEventListener("input", updateRoi);
    });
    updateRoi();
  }

  // 3. Accessible confirmation on destructive or binding actions
  document.querySelectorAll("form[data-confirm-message]").forEach(function (form) {
    form.addEventListener("submit", function (event) {
      var message = form.getAttribute("data-confirm-message");
      if (message && !window.confirm(message)) {
        event.preventDefault();
      }
    });
  });

  // 4. Move keyboard focus to error summary when a form returns validation errors (RGAA 11.10)
  var errorSummary = document.querySelector("[data-error-summary]");
  if (errorSummary) {
    errorSummary.focus();
  }
});
