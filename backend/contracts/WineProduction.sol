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

    // ===================== STATI =====================
    enum Stato {
        Creato,         // 0
        Vendemmiato,    // 1
        Fermentato,     // 2
        Affinato,       // 3
        Imbottigliato,  // 4
        Spedito,        // 5
        Distribuito,    // 6
        Completato,     // 7
        Revisione       // 8
    }

    // ===================== STRUCT =====================
    struct Lotto {
        uint256 id;
        string tipo;
        Stato stato;
        uint256[] timestamps;
        string[] luoghi;
        address agricoltore;
        address supervisore;
        address cantiniere;
        address corriere;
        address distributore;
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
    Lotto[] public lotti;
    uint256 public nextId = 1;

    // ===================== EVENTI =====================
    event FaseSegnalata(uint256 indexed lottoId, string motivazione, address utente);
    event LottoRiabilitato(uint256 indexed lottoId, Stato nuovoStato);

    constructor() {
        roles[msg.sender] = ADMIN;
    }

    // ===================== CREA LOTTO =====================
    function creaLotto(
        string memory _tipo,
        address _agricoltore,
        address _supervisore,
        address _cantiniere,
        address _corriere,
        address _distributore
    ) public {
        require(roles[msg.sender] == ADMIN, "Solo Admin");

        Lotto storage lotto = lotti.push();
        lotto.id = nextId++;
        lotto.tipo = _tipo;
        lotto.stato = Stato.Creato;
        lotto.timestamps.push(block.timestamp);
        lotto.luoghi.push("Creazione lotto");
        lotto.agricoltore = _agricoltore;
        lotto.supervisore = _supervisore;
        lotto.cantiniere = _cantiniere;
        lotto.corriere = _corriere;
        lotto.distributore = _distributore;
    }

    // ===================== AVANZA STATO =====================
    function avanzaStato(uint256 _index, string memory _luogo) public {
        require(_index < lotti.length, "Lotto inesistente");
        Lotto storage lotto = lotti[_index];
        
        require(lotto.stato != Stato.Revisione, "Lotto bloccato: in revisione");
        
        Stato attuale = lotto.stato;
        bytes32 userRole = roles[msg.sender];

        if (attuale == Stato.Creato) {
            require(userRole == AGRICOLTORE && msg.sender == lotto.agricoltore, "Solo Agricoltore");
        } else if (attuale == Stato.Vendemmiato || attuale == Stato.Fermentato) {
            require(userRole == SUPERVISORE && msg.sender == lotto.supervisore, "Solo Supervisore");
        } else if (attuale == Stato.Affinato) {
            require(userRole == CANTINIERE && msg.sender == lotto.cantiniere, "Solo Cantiniere");
        } else if (attuale == Stato.Imbottigliato) {
            require(userRole == CORRIERE && msg.sender == lotto.corriere, "Solo Corriere");
        } else if (attuale == Stato.Spedito) {
            require(userRole == DISTRIBUTORE && msg.sender == lotto.distributore, "Solo Distributore");
        } else {
            revert("Processo completato");
        }

        lotto.stato = Stato(uint(lotto.stato) + 1);
        lotto.timestamps.push(block.timestamp);
        lotto.luoghi.push(_luogo);
    }

    // ===================== GESTIONE PROBLEMI =====================
    function segnalaProblema(uint256 _index, string memory _motivazione) public {
        require(_index < lotti.length, "Lotto inesistente");
        Lotto storage lotto = lotti[_index];
        
        require(lotto.stato != Stato.Revisione && lotto.stato != Stato.Completato, "Stato non modificabile");
        
        lotto.stato = Stato.Revisione;
        lotto.timestamps.push(block.timestamp);
        lotto.luoghi.push(string(abi.encodePacked("PROBLEMA: ", _motivazione)));
        
        emit FaseSegnalata(_index, _motivazione, msg.sender);
    }

    function riabilitaLotto(uint256 _index, Stato _nuovoStato) public {
        require(roles[msg.sender] == ADMIN, "Solo Admin");
        require(_index < lotti.length, "Lotto inesistente");
        require(lotti[_index].stato == Stato.Revisione, "Non in revisione");

        lotti[_index].stato = _nuovoStato;
        lotti[_index].timestamps.push(block.timestamp);
        lotti[_index].luoghi.push("Riabilitato da Admin");

        emit LottoRiabilitato(_index, _nuovoStato);
    }

    // ===================== ADMIN & UTILITY =====================
    function eliminaLotto(uint256 _index) public {
        require(roles[msg.sender] == ADMIN, "Solo Admin");
        require(_index < lotti.length, "Indice non valido");

        lotti[_index] = lotti[lotti.length - 1];
        lotti.pop();
    }

    function getLotto(uint256 _index) public view returns (uint256 id, string memory tipo, Stato stato, address agricoltore, address supervisore, address cantiniere, address corriere, address distributore, uint256[] memory timestamps, string[] memory luoghi) {
        require(_index < lotti.length, "Indice non valido");
        Lotto storage l = lotti[_index];
        return (l.id, l.tipo, l.stato, l.agricoltore, l.supervisore, l.cantiniere, l.corriere, l.distributore, l.timestamps, l.luoghi);
    }

    function getLotti() public view returns (Lotto[] memory) {
        return lotti;
    }

    function addUser(address _user, string memory _name, string memory _roleName) public {
        require(roles[msg.sender] == ADMIN, "Solo Admin");
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

    function getAllUserAddresses() public view returns (address[] memory) {
        return userAddresses;
    }

    function eliminaUtente(address _user) public {
        require(roles[msg.sender] == ADMIN, "Solo Admin");
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

    function getLottoTimestamps(uint256 _index) public view returns (uint256[] memory) {
        require(_index < lotti.length, "Indice non valido");
        return lotti[_index].timestamps;
    }

    function getLottoLuoghi(uint256 _index) public view returns (string[] memory) {
        require(_index < lotti.length, "Indice non valido");
        return lotti[_index].luoghi;
    }
}