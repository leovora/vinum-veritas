// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WineProduction {

    enum Stato { Creato, Vendemmiato, Fermentato }

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

    //Gestione ruoli, mappiamo un indirizzo ad una parola (che corrisponde ad uno dei 3 ruoli)
    mapping(address => string) public ruoli;


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

        return false;
    }

    //solo admin assegna i ruoli
    function impostaRuolo(address _utente, string memory _etichettaRuolo) public{
        require(msg.sender == admin, "Solo l'admin puo gestire i ruoli");

        //controllo di sicurezza
        require(isRuoloValido(_etichettaRuolo), "Ruolo non valido! Usa solo: ADMIN, PRODUTTORE, SUPERVISORE");
        
        ruoli[_utente] = _etichettaRuolo;
        emit RuoloAssegnato(_utente, _etichettaRuolo);
    }

    function getRuolo(address _utente) public view returns (string memory){
        return ruoli[_utente];
    }

    // Funzione per creare un nuovo lotto
    function creaLotto(string memory _tipo) public {
        
        //solo chi ha il ruolo di produttore può farlo
        require(
            keccak256(bytes(ruoli[msg.sender])) == keccak256(bytes("PRODUTTORE")), 
            "Non hai il ruolo di PRODUTTORE"
        );

        lotti.push(Lotto(nextId, _tipo, Stato.Creato, msg.sender, block.timestamp));
        emit LottoCreato(nextId, _tipo, msg.sender);
        nextId++;
    }

    // Funzione per avanzare lo stato (Sequenziale)
    function avanzaStato(uint256 _index) public {
        require(_index < lotti.length, "Lotto inesistente");
        Lotto storage lotto = lotti[_index];
        require(msg.sender == lotto.produttore, "Solo il produttore puo aggiornare");

        if (lotto.stato == Stato.Creato) {
            lotto.stato = Stato.Vendemmiato;
        } else if (lotto.stato == Stato.Vendemmiato) {
            lotto.stato = Stato.Fermentato;
        } else {
            revert("Ciclo di produzione completato");
        }

        emit StatoAggiornato(lotto.id, lotto.stato);
    }

    // Funzione per leggere tutti i lotti
    function getLotti() public view returns (Lotto[] memory) {
        return lotti;
    }
}