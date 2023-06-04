document.addEventListener("DOMContentLoaded", () => {
  let activeTab = true;
  document.querySelectorAll(".tabs a").forEach((link) => {
    const selectedId = link.dataset.configId;

    if (activeTab) {
      link.classList.add("active");
      document.getElementById(selectedId).style.display = "block";
      activeTab = false;
    }

    link.addEventListener("click", (e) => {
      e.preventDefault();
      document.querySelectorAll(".configuration").forEach((configuration) => {
        if (configuration.id === selectedId) {
          configuration.style.display = "block";
        } else {
          configuration.style.display = "none";
        }
      });

      document.querySelectorAll(".tabs a").forEach((tab) => {
        if (tab === link) {
          tab.classList.add("active");
        } else {
          tab.classList.remove("active");
        }
      });
    });
  });
});
