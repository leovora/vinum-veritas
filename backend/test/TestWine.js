const WineProduction = artifacts.require("WineProduction");

contract("WineProduction - Test Avanzati & Edge Cases", (accounts) => {
  const admin = accounts[0];
  const produttore1 = accounts[1]; // Cantina Rossi
  const supervisore = accounts[2];
  const hacker = accounts[3];
  const produttore2 = accounts[4]; // Cantina Bianchi (Il Rivale)

  let instance;

  before(async () => {
    instance = await WineProduction.deployed();
  });

  // --- I TEST STANDARD ---
  it("1. Setup iniziale: Admin è Admin", async () => {
    assert.equal(await instance.getRuolo(admin), "ADMIN");
  });

  it("2. Assegnazione ruoli corretta", async () => {
    await instance.impostaRuolo(produttore1, "PRODUTTORE", { from: admin });
    await instance.impostaRuolo(produttore2, "PRODUTTORE", { from: admin }); 
    assert.equal(await instance.getRuolo(produttore1), "PRODUTTORE");
    assert.equal(await instance.getRuolo(produttore2), "PRODUTTORE");
  });

  it("3. Produttore 1 crea un lotto (ID 1)", async () => {
    await instance.creaLotto("Vino Rossi", { from: produttore1 });
    const lotti = await instance.getLotti();
    assert.equal(lotti.length, 1);
    assert.equal(lotti[0].produttore, produttore1);
  });

  // --- 🔥 TEST CORRETTO QUI SOTTO 🔥 ---

  it("4. TEST SABOTAGGIO: Produttore 2 NON deve poter toccare il vino di Produttore 1", async () => {
    try {
      // Produttore 2 prova a modificare il vino ID 1 (indice 0) di Produttore 1
      await instance.avanzaStato(0, { from: produttore2 });
      assert.fail("ERRORE GRAVE: Il sistema non ha bloccato il sabotaggio!");
    } catch (err) {
      // QUI ERA L'ERRORE: Ora cerchiamo la frase esatta che usa il tuo contratto
      assert.include(err.message, "Solo il produttore", "Il messaggio di errore non corrisponde");
    }
  });

  it("5. TEST LICENZIAMENTO: Assegnando 'NESSUNO', l'utente viene bloccato", async () => {
    // 1. L'Admin revoca il ruolo impostando "NESSUNO"
    await instance.impostaRuolo(produttore2, "NESSUNO", { from: admin });

    // Verifica che il ruolo sia stato salvato
    const ruoloCorrente = await instance.getRuolo(produttore2);
    assert.equal(ruoloCorrente, "NESSUNO", "Il ruolo non è stato aggiornato a NESSUNO");

    // 2. L'utente prova a creare vino (e deve fallire)
    try {
      await instance.creaLotto("Vino Illegale", { from: produttore2 });
      assert.fail("ERRORE: Un utente con ruolo NESSUNO ha creato vino!");
    } catch (err) {
      assert.include(err.message, "Non hai il ruolo di PRODUTTORE", "Il blocco non ha funzionato");
    }
  });

  it("6. TEST ID SEQUENZIALE: Creiamo più lotti e verifichiamo i numeri", async () => {
    // Produttore 1 crea altri due vini
    await instance.creaLotto("Vino Rossi Riserva", { from: produttore1 }); // ID 2
    await instance.creaLotto("Vino Rossi Bianco", { from: produttore1 });  // ID 3
    
    const lotti = await instance.getLotti();
    
    // Verifica che ci siano 3 lotti totali
    assert.equal(lotti.length, 3, "Totale lotti errato");

    // Verifica gli ID (L'array parte da 0, gli ID da 1)
    assert.equal(lotti[1].id, 2, "L'ID del secondo lotto non è 2");
    assert.equal(lotti[2].id, 3, "L'ID del terzo lotto non è 3");
  });

  it("7. TEST LIMITI: Errore se cerco di aggiornare un lotto che non esiste", async () => {
    try {
      await instance.avanzaStato(99, { from: produttore1 });
      assert.fail("Doveva fallire per indice inesistente");
    } catch (err) {
      assert.include(err.message, "Lotto inesistente", "Non ha rilevato l'ID errato");
    }
  });

});