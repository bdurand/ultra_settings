document.addEventListener("DOMContentLoaded", () => {
  // ── i18n helper ──
  const _i18n = window.__ultraSettingsI18n || {};
  const t = (key) => _i18n[key] || key;

  const sidebar = document.getElementById("ultra-settings-sidebar");
  const sidebarOverlay = document.getElementById("ultra-settings-sidebar-overlay");
  const hamburger = document.getElementById("ultra-settings-hamburger");
  const mainContent = document.getElementById("ultra-settings-main");
  const navItems = document.querySelectorAll(".ultra-settings-nav-item");
  const sections = document.querySelectorAll(".ultra-settings-config-section");
  const searchInput = document.getElementById("ultra-settings-search-input");
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

  if (!sidebar || !mainContent) return;

  let activeConfigId = navItems.length > 0 ? navItems[0].dataset.configId : null;

  // ── Sidebar Navigation ──
  const selectConfig = (id) => {
    activeConfigId = id;
    navItems.forEach(el => el.classList.toggle("active", el.dataset.configId === id));
    const section = document.getElementById(id);
    if (section) section.scrollIntoView({ block: "start" });
    if (window.innerWidth <= 768) closeSidebar();
  };

  navItems.forEach(item => {
    item.addEventListener("click", () => selectConfig(item.dataset.configId));
    item.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") { e.preventDefault(); selectConfig(item.dataset.configId); }
    });
  });

  // ── Scroll Spy ──
  if (mainContent && sections.length > 0) {
    mainContent.addEventListener("scroll", () => {
      let current = activeConfigId;
      sections.forEach(s => {
        if (s.getBoundingClientRect().top <= 160) current = s.dataset.configId;
      });
      if (current !== activeConfigId) {
        activeConfigId = current;
        navItems.forEach(el => el.classList.toggle("active", el.dataset.configId === current));
      }
    });
  }

  // ── Hamburger Menu ──
  const openSidebar = () => {
    if (sidebar) sidebar.classList.add("open");
    if (sidebarOverlay) sidebarOverlay.classList.add("open");
  };

  const closeSidebar = () => {
    if (sidebar) sidebar.classList.remove("open");
    if (sidebarOverlay) sidebarOverlay.classList.remove("open");
    closeLanguageMenu();
  };

  if (hamburger) hamburger.addEventListener("click", () => {
    sidebar.classList.contains("open") ? closeSidebar() : openSidebar();
  });

  if (sidebarOverlay) sidebarOverlay.addEventListener("click", closeSidebar);

  // ── Inline Search Filter ──
  if (searchInput) {
    searchInput.addEventListener("input", function() {
      const q = this.value.toLowerCase().trim();

      sections.forEach(section => {
        const configId = section.dataset.configId;
        const navItem = document.querySelector('.ultra-settings-nav-item[data-config-id="' + configId + '"]');
        const configSearch = navItem ? (navItem.dataset.search || "") : "";
        const configMatch = !q || configSearch.includes(q);
        const cards = section.querySelectorAll(".ultra-settings-field-card");
        let anyFieldMatch = false;

        cards.forEach(card => {
          const fieldSearch = (card.dataset.fieldSearch || "");
          const fieldMatch = configMatch || !q || fieldSearch.includes(q);
          card.classList.toggle("hidden", !fieldMatch);
          if (fieldMatch) anyFieldMatch = true;
        });

        const showSection = configMatch || anyFieldMatch;
        section.classList.toggle("hidden", !showSection);

        // Sync nav item visibility with section
        if (navItem) navItem.classList.toggle("hidden", !showSection);
      });
    });
  }

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

  // ── Hash-based navigation ──
  const handleHash = () => {
    const hash = window.location.hash.replace(/^#/, "");
    if (hash) {
      const configId = "section-" + hash;
      const exists = Array.from(navItems).some(item => item.dataset.configId === configId);
      if (exists) selectConfig(configId);
    }
  };

  window.addEventListener("hashchange", handleHash);
  handleHash();

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

  // ── Restore scroll & flash after setting save ──
  const savedScroll = sessionStorage.getItem("ultra-settings-scroll");
  const changedKey = sessionStorage.getItem("ultra-settings-changed-key");
  if (savedScroll != null) {
    mainContent.scrollTop = parseInt(savedScroll, 10);
    sessionStorage.removeItem("ultra-settings-scroll");
  }
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
          // Preserve scroll position and flash the changed row after reload
          if (mainContent) {
            sessionStorage.setItem("ultra-settings-scroll", mainContent.scrollTop);
          }
          sessionStorage.setItem("ultra-settings-changed-key", params.key);
          if (ssContainer._activeSectionId) {
            sessionStorage.setItem("ultra-settings-changed-section", ssContainer._activeSectionId);
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
        const section = btn.closest(".ultra-settings-config-section");
        ssContainer._activeSectionId = section ? section.id : null;
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
