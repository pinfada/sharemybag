//= require popper
//= require bootstrap

document.addEventListener("DOMContentLoaded", function () {
  // 1. Live total price calculation (€/kg) with polite screen-reader updates (RGAA 7.5)
  var priceInput = document.querySelector("[data-bid-price-input]");
  var totalOutput = document.querySelector("[data-bid-total-output]");
  if (priceInput && totalOutput) {
    var weightKg = parseFloat(priceInput.getAttribute("data-request-weight") || "0");
    var updateTotal = function () {
      var raw = (priceInput.value || "").replace(",", ".");
      var perKg = parseFloat(raw);
      if (!isNaN(perKg) && perKg > 0 && weightKg > 0) {
        var total = (perKg * weightKg).toFixed(2);
        totalOutput.textContent = "€" + total;
      } else {
        totalOutput.textContent = "—";
      }
    };
    priceInput.addEventListener("input", updateTotal);
    updateTotal();
  }

  // 2. Copy secret code with accessible live status announcement (RGAA 7.5)
  document.querySelectorAll("[data-copy-code]").forEach(function (button) {
    button.addEventListener("click", function () {
      var code = button.getAttribute("data-copy-code");
      if (!code || !navigator.clipboard) return;
      var statusEl = document.getElementById(button.getAttribute("data-copy-status-id") || "");
      navigator.clipboard.writeText(code).then(function () {
        var original = button.innerHTML;
        button.innerHTML = '<i class="fas fa-check me-1" aria-hidden="true"></i>Copied';
        if (statusEl) {
          statusEl.textContent = "Code copied to clipboard.";
        }
        setTimeout(function () {
          button.innerHTML = original;
          if (statusEl) statusEl.textContent = "";
        }, 2000);
      });
    });
  });

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
