// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WineProduction {
    // 0: Creato, 1: Vendemmiato, 2: Fermentato, 3: Affinato, 4: Imbottigliato, 5: Distribuito
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

    event LottoCreato(uint256 id, string tipo, address produttore);
    event StatoAggiornato(uint256 id, Stato nuovoStato);

    function creaLotto(string memory _tipo) public {
        lotti.push(Lotto(nextId, _tipo, Stato.Creato, msg.sender, block.timestamp));
        emit LottoCreato(nextId, _tipo, msg.sender);
        nextId++;
    }

    // Funzione ottimizzata per avanzare attraverso TUTTI gli stati
    function avanzaStato(uint256 _index) public {
        require(_index < lotti.length, "Lotto inesistente");
        Lotto storage lotto = lotti[_index];
        require(msg.sender == lotto.produttore, "Solo il produttore puo aggiornare");
        
        // Controlliamo che non sia gia nell'ultimo stato (Distribuito = 5)
        require(uint(lotto.stato) < uint(Stato.Distribuito), "Ciclo di produzione gia completato");

        // Avanzamento matematico: incrementiamo l'indice dell'enum di 1
        lotto.stato = Stato(uint(lotto.stato) + 1);

        emit StatoAggiornato(lotto.id, lotto.stato);
    }

    function getLotti() public view returns (Lotto[] memory) {
        return lotti;
    }
}