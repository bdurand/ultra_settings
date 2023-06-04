document.addEventListener("DOMContentLoaded", () => {
  const menu = document.getElementById("config-selector");

  menu.addEventListener("change", (e) => {
    const selectedId = menu.options[menu.selectedIndex].value;

    document.querySelectorAll(".configuration").forEach((configuration) => {
      if (configuration.id === selectedId) {
        configuration.style.display = "block";
      } else {
        configuration.style.display = "none";
      }
    });
  });

  document.querySelector(".configuration").style.display = "block";
});
