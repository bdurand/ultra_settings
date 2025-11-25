document.addEventListener("DOMContentLoaded", () => {
  const dropdown = document.getElementById("config-dropdown");
  const button = document.getElementById("config-dropdown-button");
  const menu = document.getElementById("config-dropdown-menu");
  const searchInput = document.getElementById("config-search");
  const items = document.querySelectorAll(".ultra-settings-dropdown-item");
  const configurations = document.querySelectorAll(".ultra-settings-configuration");
  const configList = document.querySelector(".ultra-settings-configuration-list");

  // If no dropdown, we might be in single config mode or no configs.
  if (!dropdown) {
    // If there is exactly one configuration, show it.
    if (configurations.length === 1) {
      configurations[0].style.display = "block";
    }
    return;
  }

  const toggleMenu = () => {
    const isVisible = menu.style.display === "block";
    menu.style.display = isVisible ? "none" : "block";
    if (!isVisible) {
      searchInput.value = "";
      filterItems("");
      searchInput.focus();
    }
  };

  const closeMenu = () => {
    menu.style.display = "none";
  };

  const filterItems = (query) => {
    const lowerQuery = query.toLowerCase();
    items.forEach(item => {
      const label = item.getAttribute("data-search").toLowerCase();
      if (label.includes(lowerQuery)) {
        item.style.display = "flex";
      } else {
        item.style.display = "none";
      }
    });
  };

  const showConfigList = () => {
    if (configList) configList.style.display = "grid";
    configurations.forEach(config => config.style.display = "none");
    items.forEach(item => item.classList.remove("selected"));
    button.textContent = "Select Configuration";
    closeMenu();
  };

  const showConfig = (configId) => {
    if (configList) configList.style.display = "none";

    configurations.forEach(config => {
      config.style.display = config.id === configId ? "block" : "none";
    });

    items.forEach(item => {
      if (item.getAttribute("data-value") === configId) {
        item.classList.add("selected");
        button.textContent = item.getAttribute("data-label");
      } else {
        item.classList.remove("selected");
      }
    });

    closeMenu();
  };

  // Event Listeners
  button.addEventListener("click", (e) => {
    e.stopPropagation();
    toggleMenu();
  });

  document.addEventListener("click", (e) => {
    if (!dropdown.contains(e.target)) {
      closeMenu();
    }
  });

  searchInput.addEventListener("input", (e) => {
    filterItems(e.target.value);
  });

  items.forEach(item => {
    item.addEventListener("click", () => {
      const configId = item.getAttribute("data-value");
      const hash = configId.replace(/^config-/, "");

      if (item.classList.contains("selected")) {
        // Toggle off: clear hash
        history.pushState("", document.title, window.location.pathname + window.location.search);
        handleHashChange();
      } else {
        window.location.hash = hash;
      }
    });
  });

  // Initial Load & Hash Change
  const handleHashChange = () => {
    const hash = window.location.hash.replace(/^#/, "");
    if (hash) {
      const configId = `config-${hash}`;
      // Check if config exists
      const exists = Array.from(items).some(item => item.getAttribute("data-value") === configId);
      if (exists) {
        showConfig(configId);
      } else {
        showConfigList();
      }
    } else {
      showConfigList();
    }
  };

  window.addEventListener("hashchange", handleHashChange);

  // Run once on load
  handleHashChange();
});
