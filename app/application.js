document.addEventListener("DOMContentLoaded", () => {
  const menu = document.getElementById("config-selector");

  showCurrentConfiguration = () => {
    const selectedId = menu.options[menu.selectedIndex].value;
    const hash = selectedId.replace(/^config-/, "");

    document.querySelectorAll(".ultra-settings-configuration").forEach((configuration) => {
      if (configuration.id === selectedId) {
        configuration.style.display = "block";
        window.location.hash = hash;
      } else {
        configuration.style.display = "none";
      }
    });
  }

  menu.addEventListener("change", showCurrentConfiguration);

  const setCurrentSelection =  () => {
    const hash = window.location.hash.replace(/^#/, "");
    const selectedId = `config-${hash}`;
    for (const option of menu.options) {
      if (option.value === selectedId) {
        option.selected = true;
        break;
      }
    }

    showCurrentConfiguration();
  }

  window.addEventListener('hashchange', setCurrentSelection);


  if (window.location.hash) {
    setCurrentSelection()
  }

  showCurrentConfiguration();
});
