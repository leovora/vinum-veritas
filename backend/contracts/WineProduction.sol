// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WineProduction {
    // Definizione Ruoli (Hash)
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant AGRICOLTORE = keccak256("AGRICOLTORE");
    bytes32 public constant SUPERVISORE = keccak256("SUPERVISORE");
    bytes32 public constant CANTINIERE = keccak256("CANTINIERE");
    bytes32 public constant CORRIERE = keccak256("CORRIERE");
    bytes32 public constant DISTRIBUTORE = keccak256("DISTRIBUTORE");

    // L'Enum deve essere definito PRIMA dello Struct che lo usa
    enum Stato { 
        Creato,         // 0
        Vendemmiato,    // 1
        Fermentato,     // 2
        Affinato,       // 3
        Imbottigliato,  // 4
        Distribuito,    // 5
        Completato      // 6
    }
    
    struct Lotto {
        uint256 id;
        string tipo;
        Stato stato;
        uint256 timestamp;
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
    
    mapping(address => bytes32) public roles;
    mapping(address => User) public users;
    address[] public userAddresses;
    Lotto[] public lotti;
    uint256 public nextId = 1;

    constructor() {
        // Chi fa il deploy diventa ADMIN
        roles[msg.sender] = ADMIN;
    }

    // Crea Lotto con tutta la filiera assegnata
    function creaLotto(
        string memory _tipo, 
        address _agricoltore,
        address _supervisore,
        address _cantiniere,
        address _corriere,
        address _distributore
    ) public {
        require(roles[msg.sender] == ADMIN, "Solo Admin");
        
        lotti.push(Lotto({
            id: nextId,
            tipo: _tipo,
            stato: Stato.Creato,
            timestamp: block.timestamp, // <--- FIX: Assegna il tempo attuale
            agricoltore: _agricoltore,
            supervisore: _supervisore,
            cantiniere: _cantiniere,
            corriere: _corriere,
            distributore: _distributore
        }));
        
        nextId++;
    }

    function avanzaStato(uint256 _index) public {
        require(_index < lotti.length, "Lotto inesistente");
        Lotto storage lotto = lotti[_index];
        Stato attuale = lotto.stato;
        bytes32 userRole = roles[msg.sender];

        if (attuale == Stato.Creato) {
            require(userRole == AGRICOLTORE && msg.sender == lotto.agricoltore, "Solo l'Agricoltore assegnato");
        } 
        else if (attuale == Stato.Vendemmiato) {
            require(userRole == SUPERVISORE && msg.sender == lotto.supervisore, "Solo il Supervisore assegnato (Fermentazione)");
        }
        else if (attuale == Stato.Fermentato) {
            require(userRole == SUPERVISORE && msg.sender == lotto.supervisore, "Solo il Supervisore assegnato (Affinamento)");
        }
        else if (attuale == Stato.Affinato) {
            require(userRole == CANTINIERE && msg.sender == lotto.cantiniere, "Solo il Cantiniere assegnato");
        }
        else if (attuale == Stato.Imbottigliato) {
            require(userRole == CORRIERE && msg.sender == lotto.corriere, "Solo il Corriere assegnato");
        }
        else if (attuale == Stato.Distribuito) {
            require(userRole == DISTRIBUTORE && msg.sender == lotto.distributore, "Solo il Distributore assegnato");
        }
        else {
            revert("Ciclo gia completato o stato non gestito");
        }

        lotto.stato = Stato(uint(lotto.stato) + 1);
    }

    function addUser(address _user, string memory _name, string memory _roleName) public {
        require(roles[msg.sender] == ADMIN, "Solo Admin");
        
        // Assegna il ruolo basato sulla stringa ricevuta
        bytes32 roleHash = keccak256(abi.encodePacked(_roleName));
        roles[_user] = roleHash;
        
        users[_user] = User(_name, _roleName, true);
        
        bool exists = false;
        for(uint i=0; i < userAddresses.length; i++) {
            if(userAddresses[i] == _user) { exists = true; break; }
        }
        if(!exists) userAddresses.push(_user);
    }

    function eliminaLotto(uint256 _index) public {
        require(roles[msg.sender] == ADMIN, "Solo Admin");
        require(_index < lotti.length, "Indice non valido");
        lotti[_index] = lotti[lotti.length - 1];
        lotti.pop();
    }

    function getLotti() public view returns (Lotto[] memory) {
        return lotti;
    }

    function getAllUserAddresses() public view returns (address[] memory) {
        return userAddresses;
    }

    function eliminaUtente(address _user) public {
    require(roles[msg.sender] == ADMIN, "Solo Admin");
    require(users[_user].isActive, "Utente non esistente o gia' rimosso");
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
}