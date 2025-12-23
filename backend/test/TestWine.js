const WineProduction = artifacts.require("WineProduction");

contract("WineProduction - Gestione Lotti", (accounts) => {
  const produttore = accounts[0];
  const altroUtente = accounts[1];
  let instance;

  // Prima di eseguire i test, recuperiamo il contratto deployato
  before(async () => {
    instance = await WineProduction.deployed();
  });

  it("1. Dovrebbe creare un nuovo lotto correttamente", async () => {
    // Il produttore crea un lotto "Chianti Classico 2024"
    // Nota: passiamo { from: produttore } per simulare chi clicca il bottone
    const tx = await instance.creaLotto("Chianti Classico 2024", { from: produttore });

    // VERIFICA 1: L'evento 'LottoCreato' è stato emesso?
    const log = tx.logs[0];
    assert.equal(log.event, "LottoCreato", "L'evento LottoCreato non è stato emesso");
    assert.equal(log.args.tipo, "Chianti Classico 2024", "Il tipo di vino nell'evento è sbagliato");

    // VERIFICA 2: Il lotto è stato salvato nell'array 'lotti'?
    // Usiamo l'indice 0 perché è il primo elemento
    const lotto = await instance.lotti(0);
    assert.equal(lotto.id, 1, "L'ID del primo lotto dovrebbe essere 1");
    assert.equal(lotto.stato, 0, "Lo stato iniziale dovrebbe essere 0 (Creato)");
    assert.equal(lotto.produttore, produttore, "Il produttore registrato non corrisponde");
  });

  it("2. Dovrebbe avanzare lo stato a 'Vendemmiato'", async () => {
    // Il produttore avanza lo stato del lotto #0
    const tx = await instance.avanzaStato(0, { from: produttore });

    // VERIFICA: L'evento 'StatoAggiornato' è stato emesso?
    const log = tx.logs[0];
    assert.equal(log.event, "StatoAggiornato", "L'evento StatoAggiornato non è stato emesso");
    
    // VERIFICA: Lo stato è cambiato in blockchain?
    const lotto = await instance.lotti(0);
    assert.equal(lotto.stato, 1, "Lo stato dovrebbe essere ora 1 (Vendemmiato)");
  });

  it("3. Dovrebbe impedire a un estraneo di modificare lo stato", async () => {
    try {
      // Proviamo a far avanzare lo stato usando 'altroUtente' (che non è il produttore)
      await instance.avanzaStato(0, { from: altroUtente });
      assert.fail("Il contratto avrebbe dovuto lanciare un errore!");
    } catch (err) {
      // Ci aspettiamo che l'errore contenga la frase del require
      assert.include(err.message, "Solo il produttore", "Il messaggio di errore non è quello aspettato");
    }
  });

  it("4. Dovrebbe completare il ciclo fino a 'Fermentato'", async () => {
    // Avanziamo da Vendemmiato (1) a Fermentato (2)
    await instance.avanzaStato(0, { from: produttore });
    
    const lotto = await instance.lotti(0);
    assert.equal(lotto.stato, 2, "Lo stato dovrebbe essere ora 2 (Fermentato)");
  });
});