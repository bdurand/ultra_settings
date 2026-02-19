document.addEventListener("DOMContentLoaded", () => {
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

  if (!sidebar || !mainContent) return;

  let activeConfigId = navItems.length > 0 ? navItems[0].dataset.configId : null;

  // ── Sidebar Navigation ──
  const selectConfig = (id) => {
    activeConfigId = id;
    navItems.forEach(el => el.classList.toggle("active", el.dataset.configId === id));
    const section = document.getElementById(id);
    if (section) section.scrollIntoView({ behavior: "smooth", block: "start" });
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
    if (dpValue) dpValue.textContent = isSecret === "true" ? "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022 (secret)" : value;
    if (dpMeta) dpMeta.innerHTML = "Type: <span>" + escapeHtml(type.toUpperCase()) + "</span>" + (isSecret === "true" ? ' \u00B7 <span style="color:var(--badge-secret-text)">SECRET</span>' : "");
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
    if (e.key === "Escape") { closePanel(); }
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
});
