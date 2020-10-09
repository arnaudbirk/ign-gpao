const apiUrl = document.currentScript.getAttribute('api-url');

// Fonction permettant de supprimer un chantier
function delChantier(id, name) {
  if (window.confirm(`Supprimer le chantier : ${name} ?`)) {
    // on fait une requete sur l'API
    fetch(`${apiUrl}/api/project/${id}`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
      },
    }).then(() => {
      location.reload();
    });
  }
}

// Fonction modifiant le nombre de thrad actif sur une machine
function setNbThread(host, active) {
  value = window.prompt(`Modifier le nombre de Threads actifs pour ${host}, ${active}`, 10);

  if (!isNaN(value)) {
    fetch(`${apiUrl}/api/node/setNbActive?host=${host}&limit=${value}`, {
      method: 'POST',
    }).then(() => {
      location.reload();
    });
  }
}

// Fonction qui permet de calculer le pourcentage entre une valeur et le total
function percent(num, per) {
  return (Math.round((num / per) * 100));
}
