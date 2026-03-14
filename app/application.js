document.addEventListener("DOMContentLoaded", () => {
  // ── i18n helper ──
  const _i18n = window.__ultraSettingsI18n || {};
  const t = (key) => _i18n[key] || key;

  const root = document.querySelector(".ultra-settings");
  const searchInput = document.getElementById("ultra-settings-search-input");
  const searchClear = document.getElementById("ultra-settings-search-clear");
  const configList = document.getElementById("ultra-settings-config-list");
  const configDetail = document.getElementById("ultra-settings-config-detail");
  const configListItems = document.querySelectorAll(".ultra-settings-config-list-item");
  const sections = document.querySelectorAll(".ultra-settings-config-section");
  const panelBg = document.getElementById("ultra-settings-panel-bg");
  const detailPanel = document.getElementById("ultra-settings-detail-panel");
  const dpTitle = document.getElementById("ultra-settings-dp-title");
  const dpValue = document.getElementById("ultra-settings-dp-value");
  const dpMeta = document.getElementById("ultra-settings-dp-meta");
  const dpClose = document.getElementById("ultra-settings-dp-close");
  const languageMenu = document.getElementById("ultra-settings-language-menu");
  const languageOptions = document.querySelectorAll(".ultra-settings-language-option");

  const closeLanguageMenu = () => {
    if (languageMenu) languageMenu.removeAttribute("open");
  };

  if (!root) return;

  const singleConfig = root.dataset.singleConfig || null;
  let selectedConfigId = null;
  let initialLoad = true;

  // ── View transition helper ──
  let animating = false;
  const animateView = (outEl, inEl, callback) => {
    if (animating) return;
    if (!outEl || !inEl) { if (callback) callback(); return; }
    animating = true;
    // Ensure the incoming element is hidden until the exit animation finishes
    inEl.style.display = "none";
    outEl.classList.add("ultra-settings-view-exit");
    outEl.addEventListener("animationend", function handler() {
      outEl.removeEventListener("animationend", handler);
      outEl.classList.remove("ultra-settings-view-exit");
      outEl.style.display = "none";
      inEl.style.display = "";
      inEl.classList.add("ultra-settings-view-enter");
      inEl.addEventListener("animationend", function handler2() {
        inEl.removeEventListener("animationend", handler2);
        inEl.classList.remove("ultra-settings-view-enter");
        animating = false;
      }, { once: true });
      if (callback) callback();
    }, { once: true });
  };

  // ── Config Selection ──
  const selectConfig = (configId) => {
    selectedConfigId = configId;

    // Show only the selected section
    sections.forEach(s => {
      s.style.display = (s.dataset.configId === configId) ? "" : "none";
    });

    // Update search field
    if (searchInput) {
      const configName = configId.replace(/^section-/, "");
      searchInput.value = configName;
      searchInput.readOnly = true;
    }
    if (searchClear) searchClear.classList.add("visible");

    // Update hash
    const configName = configId.replace(/^section-/, "");
    if (window.location.hash !== "#" + configName) {
      history.replaceState(null, "", "#" + configName);
    }

    // Animate list → detail
    if (configList && configDetail && !initialLoad) {
      if (configList.style.display === "none") {
        // Already showing detail, just swap content
        configDetail.classList.add("active");
      } else {
        configDetail.classList.add("active");
        animateView(configList, configDetail);
      }
    } else {
      if (configList) configList.style.display = "none";
      if (configDetail) configDetail.classList.add("active");
    }
  };

  const clearSelection = () => {
    selectedConfigId = null;

    // Hide all sections
    sections.forEach(s => { s.style.display = "none"; });

    // Reset search field
    if (searchInput) {
      searchInput.value = "";
      searchInput.readOnly = false;
    }
    if (searchClear) searchClear.classList.remove("visible");

    // Show all list items (clear any filter)
    configListItems.forEach(item => item.classList.remove("hidden"));

    // Clear hash
    history.replaceState(null, "", window.location.pathname + window.location.search);

    // Animate detail → list
    if (configDetail && configList) {
      animateView(configDetail, configList, () => {
        // Clean up: let CSS classes control display again
        configDetail.classList.remove("active");
        configDetail.style.display = "";
        configList.style.display = "";
      });
    } else {
      if (configList) configList.style.display = "";
      if (configDetail) configDetail.classList.remove("active");
    }
  };

  // ── Config List Item Handlers ──
  configListItems.forEach(item => {
    item.addEventListener("click", () => selectConfig(item.dataset.configId));
    item.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") { e.preventDefault(); selectConfig(item.dataset.configId); }
    });
  });

  // ── Search Filter (list view) ──
  if (searchInput) {
    searchInput.addEventListener("input", function() {
      if (selectedConfigId) return; // Don't filter when a config is selected

      const q = this.value.toLowerCase().trim();
      configListItems.forEach(item => {
        const searchData = item.dataset.search || "";
        const match = !q || searchData.includes(q);
        item.classList.toggle("hidden", !match);
      });
    });
  }

  // ── Clear Button ──
  if (searchClear) {
    searchClear.addEventListener("click", clearSelection);
  }

  // ── Hash-based Navigation ──
  const handleHash = () => {
    const hash = window.location.hash.replace(/^#/, "");
    if (hash) {
      const configId = "section-" + hash;
      const exists = Array.from(sections).some(s => s.dataset.configId === configId);
      if (exists) {
        selectConfig(configId);
        return;
      }
    }
    // No valid hash — if not single config, show list
    if (!singleConfig && selectedConfigId) {
      clearSelection();
    }
  };

  window.addEventListener("hashchange", handleHash);

  // ── Single Config Auto-Select ──
  if (singleConfig) {
    selectConfig(singleConfig);
  } else {
    // Check for stored config (after SuperSettings save reload)
    const storedConfig = sessionStorage.getItem("ultra-settings-selected-config");
    if (storedConfig) {
      sessionStorage.removeItem("ultra-settings-selected-config");
      const exists = Array.from(sections).some(s => s.dataset.configId === storedConfig);
      if (exists) {
        selectConfig(storedConfig);
      }
    } else {
      handleHash();
    }
  }

  initialLoad = false;

  // ── Detail Panel ──
  const openPanel = (name, value, type, isSecret) => {
    if (dpTitle) dpTitle.textContent = name;
    if (dpValue) dpValue.textContent = isSecret === "true" ? t("detail.secret_value") : value;
    if (dpMeta) dpMeta.innerHTML = t("detail.type_label") + " <span>" + escapeHtml(type.toUpperCase()) + "</span>" + (isSecret === "true" ? ' \u00B7 <span style="color:var(--badge-secret-text)">' + t("detail.secret_badge") + "</span>" : "");
    if (panelBg) panelBg.classList.add("open");
    if (detailPanel) detailPanel.classList.add("open");
  };

  const closePanel = () => {
    if (panelBg) panelBg.classList.remove("open");
    if (detailPanel) detailPanel.classList.remove("open");
  };

  if (panelBg) panelBg.addEventListener("click", closePanel);
  if (dpClose) dpClose.addEventListener("click", closePanel);

  // Delegate click on field values to open panel
  document.addEventListener("click", (e) => {
    const target = e.target.closest(".ultra-settings-field-value");
    if (target) {
      // If we're inside the full app shell with panel, use panel
      if (detailPanel) {
        openPanel(
          target.dataset.name || "",
          target.dataset.value || "",
          target.dataset.type || "",
          target.dataset.secret || "false"
        );
      } else {
        // Fallback: use dialog if available
        const block = target.closest(".ultra-settings-block");
        if (block) {
          const dialog = block.querySelector(".ultra-settings-dialog");
          if (dialog) {
            const title = dialog.querySelector(".ultra-settings-dialog-title");
            const value = dialog.querySelector(".ultra-settings-dialog-value");
            if (title) title.textContent = target.dataset.name || "";
            if (value) value.textContent = target.dataset.value || "";
            dialog.showModal();
          }
        }
      }
    }
  });

  // ── Keyboard Shortcuts ──
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") {
      closeLanguageMenu();
      closePanel();
      // Close SuperSettings edit panel if open
      const ssBg = document.getElementById("ultra-settings-ss-panel-bg");
      const ssP = document.getElementById("ultra-settings-ss-panel");
      if (ssBg) ssBg.classList.remove("open");
      if (ssP) ssP.classList.remove("open");
    }
  });

  // ── Equalize chip widths ──
  const equalizeChipWidths = () => {
    const chips = document.querySelectorAll(".ultra-settings-source-chip");
    if (!chips.length) return;
    chips.forEach(c => c.style.minWidth = "auto");
    let max = 0;
    chips.forEach(c => { max = Math.max(max, c.offsetWidth); });
    const container = document.querySelector(".ultra-settings");
    if (container) container.style.setProperty("--chip-width", max + "px");
    chips.forEach(c => c.style.minWidth = "");
  };

  equalizeChipWidths();

  // ── Restore selection & flash after setting save ──
  const changedKey = sessionStorage.getItem("ultra-settings-changed-key");
  if (changedKey) {
    sessionStorage.removeItem("ultra-settings-changed-key");
    const changedSection = sessionStorage.getItem("ultra-settings-changed-section");
    sessionStorage.removeItem("ultra-settings-changed-section");
    // Find the edit button with the matching key and highlight its field card
    const scope = (changedSection && document.getElementById(changedSection)) || document;
    const editBtn = scope.querySelector('.ultra-settings-ss-edit-btn[data-ss-key="' + CSS.escape(changedKey) + '"]');
    if (editBtn) {
      const card = editBtn.closest(".ultra-settings-field-card");
      if (card) {
        card.classList.add("ultra-settings-changed");
        card.addEventListener("animationend", () => card.classList.remove("ultra-settings-changed"), { once: true });
      }
    }
  }

  // ══════════════════════════════════════════
  // SuperSettings Inline Editing
  // ══════════════════════════════════════════
  const ssContainer = document.querySelector(".ultra-settings[data-ss-editing]");
  if (ssContainer) {
    const ssPanel = document.getElementById("ultra-settings-ss-panel");
    const ssPanelBg = document.getElementById("ultra-settings-ss-panel-bg");
    const ssForm = document.getElementById("ultra-settings-ss-form");
    const ssLoading = document.getElementById("ultra-settings-ss-loading");
    const ssErrors = document.getElementById("ultra-settings-ss-errors");
    const ssKeyInput = document.getElementById("ultra-settings-ss-key");
    const ssTitle = document.getElementById("ultra-settings-ss-title");
    const ssValueTypeSelect = document.getElementById("ultra-settings-ss-value-type");
    const ssValueTextarea = document.getElementById("ultra-settings-ss-value");
    const ssValueField = document.getElementById("ultra-settings-ss-value-field");
    const ssIntegerField = document.getElementById("ultra-settings-ss-integer-field");
    const ssIntegerInput = document.getElementById("ultra-settings-ss-integer-value");
    const ssFloatField = document.getElementById("ultra-settings-ss-float-field");
    const ssFloatInput = document.getElementById("ultra-settings-ss-float-value");
    const ssBooleanField = document.getElementById("ultra-settings-ss-boolean-field");
    const ssBooleanCheckbox = document.getElementById("ultra-settings-ss-boolean-value");
    const ssDatetimeField = document.getElementById("ultra-settings-ss-datetime-field");
    const ssDatetimeInput = document.getElementById("ultra-settings-ss-datetime-value");
    const ssTzLabel = document.getElementById("ultra-settings-ss-tz-label");
    const ssDescriptionInput = document.getElementById("ultra-settings-ss-description");
    const ssSaveBtn = document.getElementById("ultra-settings-ss-save");
    const ssCancelBtn = document.getElementById("ultra-settings-ss-cancel");
    const ssCloseBtn = document.getElementById("ultra-settings-ss-panel-close");
    const ssExternalLink = document.getElementById("ultra-settings-ss-external-link");
    const ssRuntimeUrlTemplate = ssContainer.dataset.runtimeSettingsUrl || "";

    // Determine API base URL from current page
    const getApiBase = () => {
      let base = window.location.pathname.replace(/\/+$/, "");
      return base;
    };

    // Fetch a setting from the SuperSettings API
    const fetchSetting = (key, callback) => {
      const url = getApiBase() + "/super_settings/setting?key=" + encodeURIComponent(key);
      fetch(url, {credentials: "same-origin"})
        .then(resp => {
          if (resp.ok) return resp.json();
          if (resp.status === 404) return null;
          throw new Error(resp.status + " " + resp.statusText);
        })
        .then(callback)
        .catch(err => {
          console.error("Error fetching setting:", err);
          callback(null);
        });
    };

    // Save a setting via the SuperSettings API
    const saveSetting = (params, callback) => {
      const url = getApiBase() + "/super_settings/setting";
      fetch(url, {
        method: "POST",
        credentials: "same-origin",
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
        body: JSON.stringify({settings: [params]})
      })
        .then(resp => resp.json().then(data => ({status: resp.status, data})))
        .then(callback)
        .catch(err => {
          console.error("Error saving setting:", err);
          callback({status: 500, data: {error: err.message}});
        });
    };

    // Get the local timezone name for display
    const localTz = (() => {
      try { return Intl.DateTimeFormat().resolvedOptions().timeZone; } catch(e) { return "UTC"; }
    })();
    if (ssTzLabel) ssTzLabel.textContent = localTz;

    // Show/hide value fields based on type
    const updateValueField = (type) => {
      ssValueField.style.display = "none";
      ssIntegerField.style.display = "none";
      ssFloatField.style.display = "none";
      ssBooleanField.style.display = "none";
      ssDatetimeField.style.display = "none";

      if (type === "boolean") {
        ssBooleanField.style.display = "";
      } else if (type === "integer") {
        ssIntegerField.style.display = "";
      } else if (type === "float") {
        ssFloatField.style.display = "";
      } else if (type === "datetime") {
        ssDatetimeField.style.display = "";
      } else if (type === "array") {
        ssValueField.style.display = "";
        ssValueTextarea.rows = 6;
        ssValueTextarea.placeholder = t("edit.placeholder_array");
      } else {
        ssValueField.style.display = "";
        ssValueTextarea.rows = 3;
        ssValueTextarea.placeholder = "";
      }
    };

    ssValueTypeSelect.addEventListener("change", () => {
      updateValueField(ssValueTypeSelect.value);
    });

    // Enforce integer-only input: strip non-integer characters as the user types
    if (ssIntegerInput) {
      ssIntegerInput.addEventListener("input", () => {
        const raw = ssIntegerInput.value;
        // Allow empty, sole minus sign while typing, or valid integer
        if (raw === "" || raw === "-") return;
        const parsed = parseInt(raw, 10);
        if (isNaN(parsed)) {
          ssIntegerInput.value = "";
        } else if (String(parsed) !== raw) {
          ssIntegerInput.value = parsed;
        }
      });
    }

    // Convert the datetime-local input value (local time) to a UTC ISO 8601 string
    const datetimeToISO = () => {
      const localVal = ssDatetimeInput.value; // e.g. "2025-01-15T10:30:00"
      if (!localVal) return "";
      const d = new Date(localVal);
      if (isNaN(d.getTime())) return localVal;
      return d.toISOString();
    };

    // Parse a UTC ISO 8601 string and populate the datetime-local input in local time
    const populateDatetime = (isoStr) => {
      if (!isoStr) {
        ssDatetimeInput.value = "";
        return;
      }
      let str = String(isoStr).trim();
      // Normalize Ruby Time#to_json format ("2026-03-20 01:07:56 UTC") to ISO 8601
      str = str.replace(/ UTC$/, "Z").replace(/ /, "T");
      // Ensure the string is treated as UTC if no timezone indicator present
      if (!str.endsWith("Z") && !/[+-]\d{2}:?\d{2}$/.test(str)) {
        str += "Z";
      }
      const d = new Date(str);
      if (isNaN(d.getTime())) {
        ssDatetimeInput.value = "";
        return;
      }
      // Format as local datetime-local value: YYYY-MM-DDTHH:MM:SS
      const pad = (n) => String(n).padStart(2, "0");
      ssDatetimeInput.value = d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) +
        "T" + pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds());
    };

    const getFormValue = () => {
      if (ssValueTypeSelect.value === "boolean") {
        return ssBooleanCheckbox.checked ? "true" : "false";
      }
      if (ssValueTypeSelect.value === "integer") {
        return ssIntegerInput.value;
      }
      if (ssValueTypeSelect.value === "float") {
        return ssFloatInput.value;
      }
      if (ssValueTypeSelect.value === "datetime") {
        return datetimeToISO();
      }
      return ssValueTextarea.value;
    };

    // Open the edit panel
    const openSsPanel = (key, defaultType, defaultDescription) => {
      if (!ssPanel) return;

      // Close the detail panel if open
      closePanel();

      // Reset form
      ssKeyInput.value = key;
      if (ssTitle) ssTitle.textContent = key;
      ssValueTextarea.value = "";
      ssIntegerInput.value = "";
      ssFloatInput.value = "";
      ssDatetimeInput.value = "";
      ssBooleanCheckbox.checked = false;
      ssDescriptionInput.value = defaultDescription || "";
      ssValueTypeSelect.value = defaultType || "string";
      updateValueField(ssValueTypeSelect.value);
      ssErrors.style.display = "none";
      ssErrors.textContent = "";
      ssForm.style.display = "none";
      ssLoading.style.display = "";
      ssSaveBtn.disabled = false;
      ssSaveBtn.textContent = t("edit.save");

      // Build and show external link if runtime_settings_url is configured
      if (ssExternalLink && ssRuntimeUrlTemplate) {
        const externalUrl = ssRuntimeUrlTemplate
          .replace("${name}", encodeURIComponent(key))
          .replace("${type}", encodeURIComponent(defaultType || ""))
          .replace("${description}", encodeURIComponent(defaultDescription || ""));
        ssExternalLink.href = externalUrl;
        ssExternalLink.style.display = "";
      } else if (ssExternalLink) {
        ssExternalLink.style.display = "none";
      }

      ssPanelBg.classList.add("open");
      ssPanel.classList.add("open");

      // Fetch existing setting
      fetchSetting(key, (setting) => {
        if (setting && !setting.error) {
          // Existing setting — populate form with current values
          ssValueTypeSelect.value = setting.value_type || defaultType || "string";
          updateValueField(ssValueTypeSelect.value);

          if (setting.value_type === "boolean") {
            ssBooleanCheckbox.checked = (setting.value === true || setting.value === "true");
          } else if (setting.value_type === "integer") {
            ssIntegerInput.value = (setting.value != null) ? String(setting.value) : "";
          } else if (setting.value_type === "float") {
            ssFloatInput.value = (setting.value != null) ? String(setting.value) : "";
          } else if (setting.value_type === "datetime") {
            populateDatetime((setting.value != null) ? String(setting.value) : "");
          } else if (setting.value_type === "array" && Array.isArray(setting.value)) {
            ssValueTextarea.value = setting.value.join("\n");
          } else {
            ssValueTextarea.value = (setting.value != null) ? String(setting.value) : "";
          }

          if (setting.description) {
            ssDescriptionInput.value = setting.description;
          }
        }
        // If not found, defaults already applied

        ssLoading.style.display = "none";
        ssForm.style.display = "";
      });
    };

    const closeSsPanel = () => {
      if (ssPanelBg) ssPanelBg.classList.remove("open");
      if (ssPanel) ssPanel.classList.remove("open");
    };

    // Handle save
    ssSaveBtn.addEventListener("click", () => {
      const params = {
        key: ssKeyInput.value,
        value: getFormValue(),
        value_type: ssValueTypeSelect.value,
        description: ssDescriptionInput.value
      };

      ssSaveBtn.disabled = true;
      ssSaveBtn.textContent = t("edit.saving");
      ssErrors.style.display = "none";

      saveSetting(params, (result) => {
        if (result.status === 200 && result.data.success) {
          closeSsPanel();
          // Store selected config so we can restore it after reload
          if (selectedConfigId) {
            sessionStorage.setItem("ultra-settings-selected-config", selectedConfigId);
          }
          sessionStorage.setItem("ultra-settings-changed-key", params.key);
          const activeSection = document.querySelector(".ultra-settings-config-section[style='']");
          if (activeSection) {
            sessionStorage.setItem("ultra-settings-changed-section", activeSection.id);
          }
          window.location.reload();
        } else {
          ssSaveBtn.disabled = false;
          ssSaveBtn.textContent = t("edit.save");

          let errorMsg = t("edit.save_error");
          if (result.data && result.data.errors) {
            const msgs = [];
            Object.entries(result.data.errors).forEach(([field, errs]) => {
              if (Array.isArray(errs)) {
                errs.forEach(e => msgs.push(e));
              } else {
                msgs.push(String(errs));
              }
            });
            if (msgs.length > 0) errorMsg = msgs.join("; ");
          } else if (result.data && result.data.error) {
            errorMsg = result.data.error;
          }
          ssErrors.textContent = errorMsg;
          ssErrors.style.display = "";
        }
      });
    });

    // Handle cancel / close
    ssCancelBtn.addEventListener("click", closeSsPanel);
    ssCloseBtn.addEventListener("click", closeSsPanel);
    if (ssPanelBg) ssPanelBg.addEventListener("click", closeSsPanel);

    // Delegate clicks on edit buttons
    document.addEventListener("click", (e) => {
      const btn = e.target.closest(".ultra-settings-ss-edit-btn");
      if (btn) {
        e.preventDefault();
        openSsPanel(
          btn.dataset.ssKey || "",
          btn.dataset.ssDefaultType || "string",
          btn.dataset.ssDefaultDescription || ""
        );
      }
    });
  }

  // ── Language Menu ──
  if (languageMenu && languageOptions.length > 0) {
    languageOptions.forEach((option) => {
      option.addEventListener("click", () => {
        const locale = option.dataset.locale;
        if (!locale) return;

        closeLanguageMenu();

        // Persist the choice in a cookie (accessible server-side)
        document.cookie = "ultra_settings_locale=" + encodeURIComponent(locale) + ";path=/;max-age=31536000;SameSite=Lax";

        // Also store in localStorage for client-side persistence
        try { localStorage.setItem("ultra_settings_locale", locale); } catch(e) {}

        // Reload with lang query param so server picks it up immediately
        const url = new URL(window.location.href);
        url.searchParams.set("lang", locale);
        window.location.href = url.toString();
      });
    });

    document.addEventListener("click", (e) => {
      if (languageMenu.hasAttribute("open") && !e.target.closest("#ultra-settings-language-menu")) {
        closeLanguageMenu();
      }
    });
  }
});
