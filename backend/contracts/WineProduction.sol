// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WineProduction {
    // Definizione Ruoli (Hash per risparmiare gas)
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant AGRICOLTORE = keccak256("AGRICOLTORE");
    bytes32 public constant SUPERVISORE = keccak256("SUPERVISORE");
    bytes32 public constant CANTINIERE = keccak256("CANTINIERE");
    bytes32 public constant CORRIERE = keccak256("CORRIERE");
    bytes32 public constant DISTRIBUTORE = keccak256("DISTRIBUTORE");

    enum Stato { Creato, Vendemmiato, Fermentato, Affinato, Imbottigliato, Distribuito }
    
    struct Lotto {
        uint256 id;
        string tipo;
        Stato stato;
        address creatore;
    }
    
    mapping(address => bytes32) public roles;
    Lotto[] public lotti;
    uint256 public nextId = 1;

    constructor() {
    // Chi fa il deploy diventa automaticamente ADMIN
    roles[msg.sender] = keccak256(abi.encodePacked("ADMIN"));
}

    // Solo l'Admin può creare lotti
    function creaLotto(string memory _tipo) public {
        require(roles[msg.sender] == ADMIN, "Solo l'Admin puo creare lotti");
        lotti.push(Lotto(nextId, _tipo, Stato.Creato, msg.sender));
        nextId++;
    }
    function eliminaLotto(uint256 _index) public {
    require(roles[msg.sender] == keccak256("ADMIN"), "Solo l'Admin puo eliminare");
    require(_index < lotti.length, "Indice non valido");

    // Sposta l'ultimo elemento al posto di quello da eliminare e accorcia l'array
    // (Tecnica standard Solidity per eliminare da array dinamici)
    lotti[_index] = lotti[lotti.length - 1];
    lotti.pop();
}

    function avanzaStato(uint256 _index) public {
        require(_index < lotti.length, "Lotto inesistente");
        Lotto storage lotto = lotti[_index];
        Stato attuale = lotto.stato;
        bytes32 userRole = roles[msg.sender];

        if (attuale == Stato.Creato) {
            require(userRole == AGRICOLTORE, "Solo l'Agricoltore conferma la Vendemmia");
        } 
        else if (attuale == Stato.Vendemmiato) {
            require(userRole == SUPERVISORE, "Solo il Supervisore conferma la Fermentazione");
        }
        else if (attuale == Stato.Fermentato) {
            require(userRole == SUPERVISORE, "Solo il Supervisore conferma l'Affinamento");
        }
        else if (attuale == Stato.Affinato) {
            require(userRole == CANTINIERE, "Solo il Cantiniere conferma l'Imbottigliamento");
        }
        else if (attuale == Stato.Imbottigliato) {
            require(userRole == CORRIERE, "Solo il Corriere gestisce la Distribuzione");
        }
        else if (attuale == Stato.Distribuito) {
            revert("Ciclo completato");
        }

        lotto.stato = Stato(uint(lotto.stato) + 1);
    }

    function assignRole(address _user, bytes32 _role) public {
        require(roles[msg.sender] == ADMIN, "Solo Admin puo assegnare ruoli");
        roles[_user] = _role;
    }

    function getLotti() public view returns (Lotto[] memory) {
        return lotti;
    }
}