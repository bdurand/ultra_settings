document.addEventListener("DOMContentLoaded", () => {
  const menu = document.getElementById("config-selector");

  showCurrentConfiguration = () => {
    const selectedId = menu.options[menu.selectedIndex].value;

    document.querySelectorAll(".ultra-settings-configuration").forEach((configuration) => {
      if (configuration.id === selectedId) {
        configuration.style.display = "block";
      } else {
        configuration.style.display = "none";
      }
    });
  }

  menu.addEventListener("change", showCurrentConfiguration);

  showCurrentConfiguration();
});
