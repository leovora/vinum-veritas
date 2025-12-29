// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WineProduction {
<<<<<<< HEAD

    enum Stato { Creato, Vendemmiato, Fermentato }
=======
    // Definizione Ruoli (Hash per risparmiare gas)
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant AGRICOLTORE = keccak256("AGRICOLTORE");
    bytes32 public constant SUPERVISORE = keccak256("SUPERVISORE");
    bytes32 public constant CANTINIERE = keccak256("CANTINIERE");
    bytes32 public constant CORRIERE = keccak256("CORRIERE");
    bytes32 public constant DISTRIBUTORE = keccak256("DISTRIBUTORE");
>>>>>>> main

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
    address public admin;

    //Gestione ruoli, mappiamo un indirizzo ad una parola (che corrisponde ad uno dei 3 ruoli)
    mapping(address => string) public ruoli;


<<<<<<< HEAD
    event LottoCreato(uint256 id, string tipo, address produttore);
    event StatoAggiornato(uint256 id, Stato nuovoStato);
    event RuoloAssegnato(address utente, string ruolo);

    constructor(){
        admin = msg.sender;
        ruoli[msg.sender] = "ADMIN";
        emit RuoloAssegnato(msg.sender, "ADMIN");
    }

    //controlliamo che siano assegnati dei ruoli validi
    function isRuoloValido(string memory _ruolo) internal pure returns(bool){
        bytes32 hashRuolo = keccak256(bytes(_ruolo));

        //solo le tre parole sono accettate
        if(hashRuolo == keccak256(bytes("ADMIN"))) return true;
        if(hashRuolo == keccak256(bytes("PRODUTTORE"))) return true;
        if(hashRuolo == keccak256(bytes("SUPERVISORE"))) return true;
        if(hashRuolo == keccak256(bytes("NESSUNO"))) return true;

        return false;
    }

    //solo admin assegna i ruoli
        function impostaRuolo(address _utente, string memory _etichettaRuolo) public {
        require(msg.sender == admin, "Solo l'admin puo gestire i ruoli");
        
        // Ora "NESSUNO" passerà questo controllo!
        require(isRuoloValido(_etichettaRuolo), "Ruolo non valido! Usa: ADMIN, PRODUTTORE, SUPERVISORE o NESSUNO");

        ruoli[_utente] = _etichettaRuolo;
        emit RuoloAssegnato(_utente, _etichettaRuolo);
    }

    function getRuolo(address _utente) public view returns (string memory){
        return ruoli[_utente];
    }
=======
    constructor() {
    // Chi fa il deploy diventa automaticamente ADMIN
    roles[msg.sender] = keccak256(abi.encodePacked("ADMIN"));
}
>>>>>>> main

    // Solo l'Admin può creare lotti
    function creaLotto(string memory _tipo) public {
<<<<<<< HEAD
        
        //solo chi ha il ruolo di produttore può farlo
        require(
            keccak256(bytes(ruoli[msg.sender])) == keccak256(bytes("PRODUTTORE")), 
            "Non hai il ruolo di PRODUTTORE"
        );

        lotti.push(Lotto(nextId, _tipo, Stato.Creato, msg.sender, block.timestamp));
        emit LottoCreato(nextId, _tipo, msg.sender);
=======
        require(roles[msg.sender] == ADMIN, "Solo l'Admin puo creare lotti");
        lotti.push(Lotto(nextId, _tipo, Stato.Creato, msg.sender));
>>>>>>> main
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