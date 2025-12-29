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
        address produttore;
        uint256 timestamp;
    }
    
    
    Lotto[] public lotti;
    uint256 public nextId = 1;
    address public admin;

    //associamo l'indirizzo ad un bytes32 (non ad una string)
    mapping(address => bytes32) public ruoli;

    //eventi
    event LottoCreato(uint256 id, string tipo, address produttore);
    event StatoAggiornato(uint256 id, Stato nuovoStato, address operatore);
    event RuoloAssegnato(address utente, string ruoloStringa);


    constructor() {
    admin = msg.sender;
    //hash di admin assegnato a chi fa il deploy
    ruoli[msg.sender] = ADMIN;
    emit RuoloAssegnato(msg.sender, "ADMIN");
    }

    //passiamo la stringa leggibile e viene salvata compressa
    function impostaRuolo(address _utente, string memory _ruoloStringa) public {
        require(ruoli[msg.sender] == ADMIN, "Solo l'admin puo gestire i ruoli");

        bytes32 hashRuolo = keccak256(bytes(_ruoloStringa));

        //controllo validità con le costanti definite sopra
        require(
            hashRuolo == ADMIN ||
            hashRuolo == AGRICOLTORE ||
            hashRuolo == SUPERVISORE ||
            hashRuolo == CANTINIERE ||
            hashRuolo == CORRIERE ||
            hashRuolo == DISTRIBUTORE,
            "Ruolo non valido"
        );

        ruoli[_utente] = hashRuolo;
        emit RuoloAssegnato(_utente, _ruoloStringa);
    }

    //salviamo in hash, la seguente funziona ritorna la stringa in maniera leggibile
    function getRuolo(address _utente) public view returns (string memory){
        bytes32 h = ruoli[_utente];

        if (h == ADMIN) return "ADMIN";
        if (h == AGRICOLTORE) return "AGRICOLTORE";
        if (h == SUPERVISORE) return "SUPERVISORE";
        if (h == CANTINIERE) return "CANTINIERE";
        if (h == CORRIERE) return "CORRIERE";
        if (h == DISTRIBUTORE) return "DISTRIBUTORE";
        return ""; // Nessun ruolo
    }

    function creaLotto(string memory _tipo) public {
        // Controllo efficiente usando bytes32
        require(ruoli[msg.sender] == ADMIN, "Solo l'ADMIN puo creare lotti");

        lotti.push(Lotto(nextId, _tipo, Stato.Creato, msg.sender, block.timestamp));
        emit LottoCreato(nextId, _tipo, msg.sender);
        nextId++;
    }


    function eliminaLotto(uint256 _index) public {
    require(ruoli[msg.sender] == ADMIN, "Solo l'Admin puo eliminare");

    require(_index < lotti.length, "Indice non valido");

    // Sposta l'ultimo elemento al posto di quello da eliminare e accorcia l'array
    // (Tecnica standard Solidity per eliminare da array dinamici)
    lotti[_index] = lotti[lotti.length - 1];
    lotti.pop();
    }

    function avanzaStato(uint256 _index) public {
        require(_index < lotti.length, "Lotto inesistente");
        Lotto storage lotto = lotti[_index];
        
        // Prendiamo il ruolo dell'utente (formato hash)
        bytes32 ruoloUtente = ruoli[msg.sender];

        if (lotto.stato == Stato.Creato) {
            require(ruoloUtente == AGRICOLTORE, "Serve ruolo AGRICOLTORE");
            lotto.stato = Stato.Vendemmiato;
        } 
        else if (lotto.stato == Stato.Vendemmiato) {
            require(ruoloUtente == SUPERVISORE, "Serve ruolo SUPERVISORE");
            lotto.stato = Stato.Fermentato;
        } 
        else if (lotto.stato == Stato.Fermentato) {
            require(ruoloUtente == SUPERVISORE, "Serve ruolo SUPERVISORE");
            lotto.stato = Stato.Affinato;
        }
        else if (lotto.stato == Stato.Affinato) {
            require(ruoloUtente == CANTINIERE, "Serve ruolo CANTINIERE");
            lotto.stato = Stato.Imbottigliato;
        }
        else if (lotto.stato == Stato.Imbottigliato) {
            require(ruoloUtente == CORRIERE, "Serve ruolo CORRIERE");
            lotto.stato = Stato.Distribuito;
        }
        else {
            revert("Ciclo completato");
        }

        emit StatoAggiornato(lotto.id, lotto.stato, msg.sender);
    }

    function getLotti() public view returns (Lotto[] memory) {
        return lotti;
    }
}