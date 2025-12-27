const WineProduction = artifacts.require("WineProduction");

contract("WineProduction - Versione Finale No Note", (accounts) => {
  const admin = accounts[0];
  const produttore = accounts[1];
  const supervisore = accounts[2];
  const hacker = accounts[3];

  let instance;

  before(async () => {
    instance = await WineProduction.deployed();
  });

  // =========================================================
  // SEZIONE 1: GESTIONE RUOLI
  // =========================================================

  it("1.1. L'Admin deve avere il ruolo 'ADMIN' automaticamente", async () => {
    const ruolo = await instance.getRuolo(admin);
    assert.equal(ruolo, "ADMIN", "Errore in inizializzazione Admin");
  });

  it("1.2. Assegnazione corretta ruolo 'PRODUTTORE'", async () => {
    await instance.impostaRuolo(produttore, "PRODUTTORE", { from: admin });
    const ruolo = await instance.getRuolo(produttore);
    assert.equal(ruolo, "PRODUTTORE", "Assegnazione Produttore fallita");
  });

  it("1.3. Assegnazione corretta ruolo 'SUPERVISORE'", async () => {
    await instance.impostaRuolo(supervisore, "SUPERVISORE", { from: admin });
    const ruolo = await instance.getRuolo(supervisore);
    assert.equal(ruolo, "SUPERVISORE", "Assegnazione Supervisore fallita");
  });

  it("1.4. SICUREZZA: Rifiuto ruoli non validi", async () => {
    try {
      await instance.impostaRuolo(produttore, "FANTASIA", { from: admin });
      assert.fail("Doveva fallire (ruolo non valido)");
    } catch (err) {
      assert.include(err.message, "Ruolo non valido", "Errore non corretto");
    }
  });

  it("1.5. SICUREZZA: Hacker non può darsi ruoli", async () => {
    try {
      await instance.impostaRuolo(hacker, "ADMIN", { from: hacker });
      assert.fail("Doveva fallire (hacker non è admin)");
    } catch (err) {
      assert.include(err.message, "Solo l'admin", "Errore non corretto");
    }
  });

  // =========================================================
  // SEZIONE 2: FILIERA VINO (Senza Note)
  // =========================================================

  it("2.1. Creazione Lotto (Solo Tipo, niente Note)", async () => {
    // Ora passiamo SOLO il tipo, come da tuo contratto
    await instance.creaLotto("Chianti Classico", { from: produttore });
    
    const lotti = await instance.getLotti();
    const ultimo = lotti[lotti.length - 1];

    assert.equal(ultimo.tipo, "Chianti Classico", "Tipo errato");
    assert.equal(ultimo.produttore, produttore, "Produttore errato");
    assert.equal(ultimo.stato, 0, "Stato iniziale errato");
  });

  it("2.2. SICUREZZA: Hacker non può creare", async () => {
    try {
      await instance.creaLotto("Vino Falso", { from: hacker });
      assert.fail("Doveva fallire");
    } catch (err) {
      assert.include(err.message, "Non hai il ruolo di PRODUTTORE", "Errore ruolo mancante");
    }
  });

  it("2.3. Avanzamento Stato (Creato -> Vendemmiato)", async () => {
    const lotti = await instance.getLotti();
    // Usiamo l'indice corretto (length - 1 prende l'ultimo elemento)
    const index = lotti.length - 1;

    await instance.avanzaStato(index, { from: produttore });
    
    const lottoAggiornato = await instance.lotti(index);
    assert.equal(lottoAggiornato.stato, 1, "Stato non avanzato a Vendemmiato");
  });

  it("2.4. Avanzamento Stato (Vendemmiato -> Fermentato)", async () => {
    const lotti = await instance.getLotti();
    const index = lotti.length - 1;

    await instance.avanzaStato(index, { from: produttore });
    
    const lottoFinale = await instance.lotti(index);
    assert.equal(lottoFinale.stato, 2, "Stato non avanzato a Fermentato");
  });

  it("2.5. SICUREZZA: Hacker non può avanzare stato", async () => {
    const lotti = await instance.getLotti();
    const index = lotti.length - 1;

    try {
      await instance.avanzaStato(index, { from: hacker });
      assert.fail("Doveva fallire");
    } catch (err) {
      assert.include(err.message, "Solo il produttore", "Errore ownership mancante");
    }
  });
});