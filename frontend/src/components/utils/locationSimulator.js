// locationSimulator.js
// Restituisce un luogo casuale basato sul ruolo dell'utente
export const getSimulatedLocation = (role) => {
  const locations = {
    AGRICOLTORE: [
      "Vigneto Toscano - Siena",
      "Vigneto Chianti - Firenze",
      "Vigneto Montalcino - Siena"
    ],
    SUPERVISORE: [
      "Laboratorio Controllo Qualità - Firenze",
      "Laboratorio Analisi Vini - Pisa"
    ],
    CANTINIERE: [
      "Cantina Centrale - Montalcino",
      "Cantina Storica - Chianti"
    ],
    CORRIERE: [
      "Centro Logistico - Bologna",
      "Deposito Merci - Parma"
    ],
    DISTRIBUTORE: [
      "Deposito Distribuzione - Milano",
      "Magazzino Regionale - Torino"
    ],
    ADMIN: [
      "Ufficio Amministrativo - Torino",
      "Sede Centrale - Roma"
    ]
  };

  const possibleLocations = locations[role] || ["Luogo sconosciuto"];
  
  const randomIndex = Math.floor(Math.random() * possibleLocations.length);
  return possibleLocations[randomIndex];
};
