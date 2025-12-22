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

    event LottoCreato(uint256 id, string tipo, address produttore);
    event StatoAggiornato(uint256 id, Stato nuovoStato);

    // Funzione per creare un nuovo lotto
    function creaLotto(string memory _tipo) public {
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