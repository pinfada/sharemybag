//= require popper
//= require bootstrap

document.addEventListener("DOMContentLoaded", function () {
  var formatEuros = function (amount) {
    if (isNaN(amount)) return "—";
    return "€" + amount.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  };

  var formatWholeEuros = function (amount) {
    if (isNaN(amount)) return "—";
    return "€" + Math.round(amount).toLocaleString("en-US");
  };

  // 1. Live Order Book Trade Estimator on /flights/:id (RGAA 7.5 aria-live="polite")
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
    updateOrderEstimate();
  }

  // 2. Interactive Annual Fleet ROI Simulator on /airline-roi (RGAA 7.5 aria-live="polite")
  var roiSim = document.querySelector("[data-roi-simulator]");
  if (roiSim) {
    var flightsEl = roiSim.querySelector("[data-roi-daily-flights]");
    var kgEl = roiSim.querySelector("[data-roi-kg-per-flight]");
    var spotEl = roiSim.querySelector("[data-roi-spot-price]");
    var commEl = roiSim.querySelector("[data-roi-commission]");
    var voucherEl = roiSim.querySelector("[data-roi-voucher-rate]");
    var durationEl = roiSim.querySelector("[data-roi-duration]");
    var excessEl = roiSim.querySelector("[data-roi-airport-fee]");

    var outMargin = roiSim.querySelector("[data-roi-annual-margin]");
    var outCommission = roiSim.querySelector("[data-roi-annual-commission]");
    var outVoucher = roiSim.querySelector("[data-roi-annual-voucher]");
    var outFuel = roiSim.querySelector("[data-roi-annual-fuel]");
    var outSavings = roiSim.querySelector("[data-roi-annual-savings]");
    var outCash = roiSim.querySelector("[data-roi-annual-cash]");

    var updateRoi = function () {
      var dailyFlights = parseFloat(flightsEl && flightsEl.value) || 0;
      var kgPerFlight = parseFloat(kgEl && kgEl.value) || 0;
      var spotPrice = parseFloat(spotEl && spotEl.value) || 0;
      var commissionPct = parseFloat(commEl && commEl.value) || 0;
      var voucherPct = parseFloat(voucherEl && voucherEl.value) || 0;
      var durationH = parseFloat(durationEl && durationEl.value) || 0;
      var excessFee = parseFloat(excessEl && excessEl.value) || 0;

      var annualKg = dailyFlights * 365 * kgPerFlight;
      var gross = annualKg * spotPrice;
      var commission = gross * (commissionPct / 100.0);
      var sellerPayout = gross - commission;
      var retainedVoucher = sellerPayout * (voucherPct / 100.0);
      var fuelCost = annualKg * 0.035 * durationH * 1.10;
      var netMargin = commission - fuelCost;
      var totalCashRetained = commission + retainedVoucher;
      var paxSavings = annualKg * Math.max(excessFee - spotPrice, 0);

      if (outMargin) outMargin.textContent = formatWholeEuros(netMargin);
      if (outCommission) outCommission.textContent = formatWholeEuros(commission);
      if (outVoucher) outVoucher.textContent = formatWholeEuros(retainedVoucher);
      if (outFuel) outFuel.textContent = formatWholeEuros(fuelCost);
      if (outSavings) outSavings.textContent = formatWholeEuros(paxSavings);
      if (outCash) outCash.textContent = formatWholeEuros(totalCashRetained);
    };

    [flightsEl, kgEl, spotEl, commEl, voucherEl, durationEl, excessEl].forEach(function (el) {
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
