// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WineProduction {

    // ===================== RUOLI =====================
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant AGRICOLTORE = keccak256("AGRICOLTORE");
    bytes32 public constant SUPERVISORE = keccak256("SUPERVISORE");
    bytes32 public constant CANTINIERE = keccak256("CANTINIERE");
    bytes32 public constant CORRIERE = keccak256("CORRIERE");
    bytes32 public constant DISTRIBUTORE = keccak256("DISTRIBUTORE");

    // ===================== STATI DI FILIERA =====================
    enum StatoFiliera {
        Creato,
        Vendemmiato,
        Fermentato,
        Affinato,
        Imbottigliato,
        Spedito,
        Distribuito,
        Completato
    }

    // ===================== STATO AMMINISTRATIVO =====================
    enum StatoControllo {
        Attivo,
        InRevisione,
        Eliminato
    }

    // ===================== STORICO STRUTTURATO =====================
    struct EventoFiliera {
        uint256 timestamp;
        string luogo;
        StatoFiliera stato;
    }

    // ===================== LOTTO =====================
    struct Lotto {
        uint256 id;
        string tipo;

        StatoFiliera stato;
        StatoControllo statoControllo;
        StatoFiliera statoPrecedente;

        string motivoRevisione;

        address agricoltore;
        address supervisore;
        address cantiniere;
        address corriere;
        address distributore;

        EventoFiliera[] storico;
    }

    struct User {
        string name;
        string role;
        bool isActive;
    }

    // ===================== STORAGE =====================
    mapping(address => bytes32) public roles;
    mapping(address => User) public users;
    address[] public userAddresses;

    mapping(uint256 => Lotto) public lotti;
    uint256[] public lottoIds;

    uint256 public nextId = 1;

    // ===================== EVENTI =====================
    event LottoCreato(uint256 indexed lottoId);
    event StatoAvanzato(uint256 indexed lottoId, StatoFiliera nuovoStato);
    event LottoInRevisione(uint256 indexed lottoId, string motivo, address segnalatore);
    event LottoRiabilitato(uint256 indexed lottoId, StatoFiliera statoRipristinato);
    event LottoEliminato(uint256 indexed lottoId);

    // ===================== COSTRUTTORE =====================
    constructor() {
        roles[msg.sender] = ADMIN;
    }

    // ===================== MODIFIER =====================
    modifier onlyAdmin() {
        require(roles[msg.sender] == ADMIN, "Solo Admin");
        _;
    }

    modifier lottoEsistente(uint256 _id) {
        require(lotti[_id].id != 0, "Lotto inesistente");
        _;
    }

    // ===================== CREA LOTTO =====================
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

        lotto.agricoltore = _agricoltore;
        lotto.supervisore = _supervisore;
        lotto.cantiniere = _cantiniere;
        lotto.corriere = _corriere;
        lotto.distributore = _distributore;

        lotto.storico.push(
            EventoFiliera(block.timestamp, "Creazione lotto", StatoFiliera.Creato)
        );

        lottoIds.push(id);

        emit LottoCreato(id);
    }

    function eliminaLotto(uint256 _id) external onlyAdmin {
        Lotto storage l = lotti[_id];

        require(l.statoControllo == StatoControllo.InRevisione,
            "Non in revisione");

        l.statoControllo = StatoControllo.Eliminato;

        emit LottoEliminato(_id);
    }

    // ===================== AVANZA STATO =====================
    function avanzaStato(uint256 _id, string memory _luogo)
        public
        lottoEsistente(_id)
    {
        Lotto storage lotto = lotti[_id];

        require(lotto.statoControllo == StatoControllo.Attivo, "Lotto in revisione");
        require(lotto.stato != StatoFiliera.Completato, "Processo completato");

        bytes32 userRole = roles[msg.sender];

        if (lotto.stato == StatoFiliera.Creato) {
            require(userRole == AGRICOLTORE && msg.sender == lotto.agricoltore, "Solo Agricoltore");
        } else if (
            lotto.stato == StatoFiliera.Vendemmiato ||
            lotto.stato == StatoFiliera.Fermentato
        ) {
            require(userRole == SUPERVISORE && msg.sender == lotto.supervisore, "Solo Supervisore");
        } else if (lotto.stato == StatoFiliera.Affinato) {
            require(userRole == CANTINIERE && msg.sender == lotto.cantiniere, "Solo Cantiniere");
        } else if (lotto.stato == StatoFiliera.Imbottigliato) {
            require(userRole == CORRIERE && msg.sender == lotto.corriere, "Solo Corriere");
        } else if (lotto.stato == StatoFiliera.Spedito) {
            require(userRole == DISTRIBUTORE && msg.sender == lotto.distributore, "Solo Distributore");
        }

        lotto.stato = StatoFiliera(uint(lotto.stato) + 1);

        lotto.storico.push(
            EventoFiliera(block.timestamp, _luogo, lotto.stato)
        );

        emit StatoAvanzato(_id, lotto.stato);
    }

    // ===================== SEGNALA PROBLEMA =====================
    function segnalaProblema(uint256 _id, string memory _motivazione)
        public
        lottoEsistente(_id)
    {
        Lotto storage lotto = lotti[_id];

        require(lotto.statoControllo == StatoControllo.Attivo, "Gia in revisione");
        require(lotto.stato != StatoFiliera.Completato, "Lotto completato");

        lotto.statoPrecedente = lotto.stato;
        lotto.statoControllo = StatoControllo.InRevisione;
        lotto.motivoRevisione = _motivazione;

        emit LottoInRevisione(_id, _motivazione, msg.sender);
    }

    // ===================== RIABILITA LOTTO =====================
    function riabilitaLotto(uint256 _id)
        public
        onlyAdmin
        lottoEsistente(_id)
    {
        Lotto storage lotto = lotti[_id];

        require(lotto.statoControllo == StatoControllo.InRevisione, "Non in revisione");

        lotto.stato = lotto.statoPrecedente;
        lotto.statoControllo = StatoControllo.Attivo;
        lotto.motivoRevisione = "";

        emit LottoRiabilitato(_id, lotto.stato);
    }

    // ===================== GETTERS =====================

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

    function getStorico(uint256 _id)
        public
        view
        lottoEsistente(_id)
        returns (EventoFiliera[] memory)
    {
        return lotti[_id].storico;
    }

    function getAllLottoIds() public view returns (uint256[] memory) {
        return lottoIds;
    }

    // ===================== USER MANAGEMENT =====================

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

    function eliminaUtente(address _user) public onlyAdmin {
        require(users[_user].isActive, "Utente non attivo");

        users[_user].isActive = false;
        roles[_user] = 0x0;

        for (uint i = 0; i < userAddresses.length; i++) {
            if (userAddresses[i] == _user) {
                userAddresses[i] = userAddresses[userAddresses.length - 1];
                userAddresses.pop();
                break;
            }
        }
    }

    function getAllUserAddresses() public view returns (address[] memory) {
        return userAddresses;
    }
}