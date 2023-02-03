function expandFilename(id) {
  var trunc = document.getElementById("truncated_" + id);
  var full = document.getElementById("full_" + id);
  var expand = document.getElementById("expand_" + id);

  if (full.style.display === "none") {
    full.style.display = "";
    trunc.style.display = "none";
    expand.innerHTML = "(Show less)";
  } else {
    full.style.display = "none";
    trunc.style.display = "";
    expand.innerHTML = "(Expand)"
  }
}
