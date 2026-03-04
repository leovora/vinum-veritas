// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *      Smart contract per la tracciabilità della filiera vinicola su blockchain.
 *      Il deployer diventa automaticamente ADMIN.
 */
contract WineProduction {

    // ===================== RUOLI =====================

    /**
     *      Ogni ruolo corrisponde a una fase specifica della filiera:
     *      - ADMIN:        gestione amministrativa (crea/elimina/riabilita lotti, gestisce utenti)
     *      - AGRICOLTORE:  fase di vendemmia
     *      - SUPERVISORE:  fasi di fermentazione e affinamento
     *      - CANTINIERE:   fase di imbottigliamento
     *      - CORRIERE:     fase di spedizione
     *      - DISTRIBUTORE: fase di distribuzione e chiusura filiera
     */
    bytes32 public constant ADMIN        = keccak256("ADMIN");
    bytes32 public constant AGRICOLTORE  = keccak256("AGRICOLTORE");
    bytes32 public constant SUPERVISORE  = keccak256("SUPERVISORE");
    bytes32 public constant CANTINIERE   = keccak256("CANTINIERE");
    bytes32 public constant CORRIERE     = keccak256("CORRIERE");
    bytes32 public constant DISTRIBUTORE = keccak256("DISTRIBUTORE");


    // ===================== STATI DI FILIERA =====================

    /**
     *      Enum che modella l'avanzamento del lotto.
     *      La progressione è sequenziale ogni stato
     *      può avanzare solo al successivo.
     */
    enum StatoFiliera {
        Creato,       // 0 - Lotto registrato, in attesa di vendemmia
        Vendemmiato,  // 1 - Uva raccolta
        Fermentato,   // 2 - Fermentazione completata
        Affinato,     // 3 - Affinamento completato
        Imbottigliato,// 4 - Prodotto imbottigliato
        Spedito,      // 5 - In transito
        Distribuito  // 6 - Consegnato al distributore
    }


    // ===================== STATO AMMINISTRATIVO =====================

    /**
     *      Enum per il controllo amministrativo del lotto, indipendente
     *      dallo stato di filiera:
     *
     *      Attivo      → operatività normale, avanzamento consentito
     *      InRevisione → lotto bloccato a seguito di segnalazione problema;
     *                    nessun avanzamento possibile fino a riabilitazione o eliminazione
     *      Eliminato   → soft delete: il lotto rimane nello storage ma è
     *                    operativamente inerte (non può essere riattivato)
     */
    enum StatoControllo {
        Attivo,      // 0 - Operativo
        InRevisione, // 1 - Bloccato, in attesa di decisione admin
        Eliminato    // 2 - Soft deleted
    }


    // ===================== STORICO STRUTTURATO =====================

    /**
     *      Struttura per ogni evento registrato nello storico del lotto.
     *      Ogni transizione di stato produce un EventoFiliera
     *      che viene appeso all'array `storico` del lotto.
     *
     *      `luogo` è una stringa casuale generata locationSimulator.js, 
     *       che ha lo scopo simulare un localizzatore.
     */
    struct EventoFiliera {
        uint256 timestamp; // timestamp al momento della transizione
        string luogo;      // Luogo dell'operazione
        StatoFiliera stato; // Stato raggiunto
    }


    // ===================== LOTTO =====================

    /**
     *      Struttura principale del lotto. Contiene sia i dati correnti
     *      che lo storico completo delle transizioni.
     *
     *      Gli attori sono fissati al momento della creazione del lotto dall'admin.
     *      Questo garantisce che solo gli indirizzi autorizzati possano
     *      operare su uno specifico lotto.
     */
    struct Lotto {
        uint256 id;
        string tipo; // Tipologia del vino ("Rosso", "Bianco", "Rosé")

        StatoFiliera stato;          // Stato corrente di filiera
        StatoControllo statoControllo; // Stato amministrativo corrente
        StatoFiliera statoPrecedente;  // salvato prima di entrare in InRevisione

        string motivoRevisione; // Motivazione del blocco/revisione

        // Attori assegnati al lotto alla creazione
        address agricoltore;
        address supervisore;
        address cantiniere;
        address corriere;
        address distributore;

        // Storico degli eventi
        EventoFiliera[] storico;
    }

    /**
     *       Struttura per la gestione degli utenti registrati nel sistema.
     */
    struct User {
        string name;
        string role;
        bool isActive;
    }


    // ===================== STORAGE =====================

    /**
     *      Mapping per il controllo degli accessi.
     */
    mapping(address => bytes32) public roles;

    /**
     *      Contiene i metadati dell'utente (nome, ruolo stringa).
     */
    mapping(address => User) public users;

    /**
     *      Array per iterare sugli utenti registrati.
     */
    address[] public userAddresses;

    /**
     *      Mapping dei lotti
     *      Serve per l'iterazione off-chain.
     */
    mapping(uint256 => Lotto) public lotti;
    uint256[] public lottoIds;

    /**
     *      Contatore auto-incrementale per gli ID dei lotti.
     */
    uint256 public nextId = 1;


    // ===================== EVENTI =====================

    event LottoCreato(uint256 indexed lottoId);
    event StatoAvanzato(uint256 indexed lottoId, StatoFiliera nuovoStato);
    event LottoInRevisione(uint256 indexed lottoId, string motivo, address segnalatore);
    event LottoRiabilitato(uint256 indexed lottoId, StatoFiliera statoRipristinato);
    event LottoEliminato(uint256 indexed lottoId);


    // ===================== COSTRUTTORE =====================

    /**
     *      Assegna il ruolo ADMIN al deployer del contratto.
     */
    constructor() {
        roles[msg.sender] = ADMIN;
    }


    // ===================== MODIFIER =====================

    /**
     *     Guard per le funzioni riservate all'amministratore.
     */
    modifier onlyAdmin() {
        require(roles[msg.sender] == ADMIN, "Solo Admin");
        _;
    }

    /**
     *      Verifica l'esistenza del lotto sfruttando il fatto che `id`
     *      non può mai essere 0 nei lotti validi (nextId parte da 1).
     */
    modifier lottoEsistente(uint256 _id) {
        require(lotti[_id].id != 0, "Lotto inesistente");
        _;
    }


    // ===================== CREA LOTTO =====================

    /**
     *      Crea un nuovo lotto e ne registra il primo evento nello storico.
     *      Solo l'ADMIN può creare lotti. Gli indirizzi degli attori vengono
     *      fissati alla creazione e non possono essere modificati successivamente.
     *
     *      Il lotto viene inizializzato con:
     *      - stato filiera: Creato
     *      - stato controllo: Attivo
     *      - primo evento nello storico con timestamp di creazione
     *
     * @param _tipo        Tipologia del vino
     * @param _agricoltore Indirizzo dell'agricoltore assegnato al lotto
     * @param _supervisore Indirizzo del supervisore assegnato al lotto
     * @param _cantiniere  Indirizzo del cantiniere assegnato al lotto
     * @param _corriere    Indirizzo del corriere assegnato al lotto
     * @param _distributore Indirizzo del distributore assegnato al lotto
     */
    function creaLotto(
        string memory _tipo,
        address _agricoltore,
        address _supervisore,
        address _cantiniere,
        address _corriere,
        address _distributore
    ) public onlyAdmin {

        uint256 id = nextId++; 

        Lotto storage lotto = lotti[id];
        lotto.id = id;
        lotto.tipo = _tipo;
        lotto.stato = StatoFiliera.Creato;
        lotto.statoControllo = StatoControllo.Attivo;

        lotto.agricoltore   = _agricoltore;
        lotto.supervisore   = _supervisore;
        lotto.cantiniere    = _cantiniere;
        lotto.corriere      = _corriere;
        lotto.distributore  = _distributore;

        // Il primo evento nello storico documenta la creazione del lotto
        lotto.storico.push(
            EventoFiliera(block.timestamp, "Creazione lotto", StatoFiliera.Creato)
        );

        lottoIds.push(id);

        emit LottoCreato(id);
    }

    /**
     *      Elimina un lotto in revisione. L'eliminazione è irreversibile.
     *
     * @param _id ID del lotto da eliminare
     */
    function eliminaLotto(uint256 _id) external onlyAdmin {
        Lotto storage l = lotti[_id];

        // impedisce di eliminare lotto attivo
        require(l.statoControllo == StatoControllo.InRevisione,
            "Non in revisione");

        l.statoControllo = StatoControllo.Eliminato;

        emit LottoEliminato(_id);
    }


    // ===================== AVANZA STATO =====================

    /**
     *      Avanza il lotto allo stato successivo della filiera.
     *      Garantisce che solo l'attore pre-assegnato per quel lotto
     *      possa operare, anche se esistono altri utenti con lo stesso ruolo.
     *
     * @param _id    ID del lotto da avanzare
     * @param _luogo Descrizione del luogo dell'operazione (registrata nello storico)
     */
    function avanzaStato(uint256 _id, string memory _luogo)
        public
        lottoEsistente(_id)
    {
        Lotto storage lotto = lotti[_id];

        require(lotto.statoControllo == StatoControllo.Attivo, "Lotto bloccato");
        require(lotto.stato != StatoFiliera.Distribuito, "Processo completato");

        bytes32 userRole = roles[msg.sender];

        // Doppio check (ruolo globale + indirizzo specifico sul lotto)
        if (lotto.stato == StatoFiliera.Creato) {
            require(userRole == AGRICOLTORE && msg.sender == lotto.agricoltore,
                "Solo Agricoltore");
        } else if (
            lotto.stato == StatoFiliera.Vendemmiato ||
            lotto.stato == StatoFiliera.Fermentato
        ) {
            require(userRole == SUPERVISORE && msg.sender == lotto.supervisore,
                "Solo Supervisore");
        } else if (lotto.stato == StatoFiliera.Affinato) {
            require(userRole == CANTINIERE && msg.sender == lotto.cantiniere,
                "Solo Cantiniere");
        } else if (lotto.stato == StatoFiliera.Imbottigliato) {
            require(userRole == CORRIERE && msg.sender == lotto.corriere,
                "Solo Corriere");
        } else if (lotto.stato == StatoFiliera.Spedito) {
            require(userRole == DISTRIBUTORE && msg.sender == lotto.distributore,
                "Solo Distributore");
        }

        // Avanzamento
        lotto.stato = StatoFiliera(uint(lotto.stato) + 1);

        // Lo storico registra il nuovo stato raggiunto
        lotto.storico.push(
            EventoFiliera(block.timestamp, _luogo, lotto.stato)
        );

        emit StatoAvanzato(_id, lotto.stato);
    }


    // ===================== SEGNALA PROBLEMA =====================

    /**
     *      Mette un lotto in revisione, bloccando l'avanzamento.
     *      Qualsiasi indirizzo può segnalare un problema.
     *
     *      Il salvataggio di `statoPrecedente` prima di entrare in InRevisione
     *      è necessario per il corretto funzionamento di `riabilitaLotto`.
     *
     * @param _id          ID del lotto da mettere in revisione
     * @param _motivazione Testo libero che descrive il problema riscontrato
     */
    function segnalaProblema(uint256 _id, string memory _motivazione)
        public
        lottoEsistente(_id)
    {
        Lotto storage lotto = lotti[_id];

        require(lotto.statoControllo == StatoControllo.Attivo, "Gia in revisione");
        // I lotti completati non possono essere messi in revisione
        require(lotto.stato != StatoFiliera.Distribuito, "Lotto completato");

        // Snapshot dello stato corrente prima del blocco
        lotto.statoPrecedente = lotto.stato;
        lotto.statoControllo = StatoControllo.InRevisione;
        lotto.motivoRevisione = _motivazione;

        emit LottoInRevisione(_id, _motivazione, msg.sender);
    }


    // ===================== RIABILITA LOTTO =====================

    /**
     *      Riporta un lotto in revisione allo stato attivo precedente.
     *      Solo l'ADMIN può riabilitare un lotto. Il ripristino avviene
     *      allo `statoPrecedente` salvato in `segnalaProblema`.
     *
     *      Il campo `motivoRevisione` viene azzerato.
     *
     * @param _id ID del lotto da riabilitare
     */
    function riabilitaLotto(uint256 _id)
        public
        onlyAdmin
        lottoEsistente(_id)
    {
        Lotto storage lotto = lotti[_id];

        require(lotto.statoControllo == StatoControllo.InRevisione, "Non in revisione");

        // Ripristino dello stato di filiera al punto precedente alla segnalazione
        lotto.stato = lotto.statoPrecedente;
        lotto.statoControllo = StatoControllo.Attivo;
        lotto.motivoRevisione = ""; // Reset del motivo

        emit LottoRiabilitato(_id, lotto.stato);
    }


    // ===================== GETTERS =====================

    /**
     *      Restituisce i dati principali di un lotto (senza storico, ha un get separato)
     *
     * @param _id ID del lotto da restituire
     */
    function getLotto(uint256 _id)
        public
        view
        lottoEsistente(_id)
        returns (
            uint256 id,
            string memory tipo,
            StatoFiliera stato,
            StatoControllo statoControllo,
            string memory motivoRevisione,
            address agricoltore,
            address supervisore,
            address cantiniere,
            address corriere,
            address distributore
        )
    {
        Lotto storage l = lotti[_id];
        return (
            l.id,
            l.tipo,
            l.stato,
            l.statoControllo,
            l.motivoRevisione,
            l.agricoltore,
            l.supervisore,
            l.cantiniere,
            l.corriere,
            l.distributore
        );
    }

    /**
     *      Restituisce l'intero storico degli eventi di un lotto.
     *
     * @param _id ID del lotto di cui recuperare lo storico
     * @return Array di EventoFiliera in ordine cronologico di inserimento
     */
    function getStorico(uint256 _id)
        public
        view
        lottoEsistente(_id)
        returns (EventoFiliera[] memory)
    {
        return lotti[_id].storico;
    }

    /**
     *      Restituisce tutti gli ID dei lotti registrati.
     */
    function getAllLottoIds() public view returns (uint256[] memory) {
        return lottoIds;
    }


    // ===================== GESTIONE UTENTI =====================

    /**
     *      Registra un utente nel sistema, assegnandogli un ruolo.
     *
     * @param _user     Indirizzo dell'utente da registrare
     * @param _name     Nome dell'utente
     * @param _roleName Stringa del ruolo
     */
    function addUser(address _user, string memory _name, string memory _roleName)
        public
        onlyAdmin
    {
        bytes32 roleHash = keccak256(abi.encodePacked(_roleName));
        roles[_user] = roleHash;
        users[_user] = User(_name, _roleName, true);

        bool exists;
        for (uint i = 0; i < userAddresses.length; i++) {
            if (userAddresses[i] == _user) {
                exists = true;
                break;
            }
        }

        if (!exists) userAddresses.push(_user);
    }

    /**
    *      Verifica se un utente è coinvolto in un lotto
    *      che non sia completato o eliminato.
    *
    * @param _user Indirizzo da verificare
    * @return true se esiste almeno un lotto attivo o in revisione che coinvolge _user
    */
    function _utenteHaLottiAttivi(address _user) internal view returns (bool) {
        for (uint i = 0; i < lottoIds.length; i++) {
            Lotto storage l = lotti[lottoIds[i]];

            // Salta i lotti in stato terminale: non bloccano l'eliminazione
            if (
                l.statoControllo == StatoControllo.Eliminato ||
                l.stato == StatoFiliera.Distribuito
            ) {
                continue;
            }

            // Controlla se _user è uno degli attori assegnati al lotto
            if (
                l.agricoltore  == _user ||
                l.supervisore  == _user ||
                l.cantiniere   == _user ||
                l.corriere     == _user ||
                l.distributore == _user
            ) {
                return true;
            }
        }
        return false;
    }

    /**
     *      Disattiva un utente rimuovendone il ruolo e l'accesso.
     *
     * @param _user Indirizzo dell'utente da disattivare
     */
    function eliminaUtente(address _user) public onlyAdmin {
        require(users[_user].isActive, "Utente non attivo");
        //Controllo che utente non sia coinvolto in processi attivi
        require(
            !_utenteHaLottiAttivi(_user),
            "Utente coinvolto in lotti attivi o in revisione"
        );

        users[_user].isActive = false;
        roles[_user] = 0x0; // Azzeramento del ruolo

        for (uint i = 0; i < userAddresses.length; i++) {
            if (userAddresses[i] == _user) {
                userAddresses[i] = userAddresses[userAddresses.length - 1];
                userAddresses.pop();
                break;
            }
        }
    }

    /**
     *      Restituisce tutti gli indirizzi degli utenti registrati (non eliminati).
     */
    function getAllUserAddresses() public view returns (address[] memory) {
        return userAddresses;
    }
}
