<template>
  <div class="producer-page-wrapper">
    
    <header class="vinum-header">
      <div class="nav-wrapper">
        <button @click="isMenuOpen = !isMenuOpen" class="hamburger-btn" aria-label="Menu">
          <div :class="['bar', { 'open': isMenuOpen }]"></div>
          <div :class="['bar', { 'open': isMenuOpen }]"></div>
          <div :class="['bar', { 'open': isMenuOpen }]"></div>
        </button>
        
        <transition name="slide">
          <nav v-if="isMenuOpen" class="dropdown-menu">
            <ul>
              <li @click="isMenuOpen = false"> Processi</li>
              <li @click="isMenuOpen = false"> Ricerca</li>
              <li @click="isMenuOpen = false"> Storico</li>
              <li @click="isMenuOpen = false"> Assegna Ruoli</li>
              <li class="divider"></li>
              <li @click="isMenuOpen = false" class="logout">🚪 Logout</li>
            </ul>
          </nav>
        </transition>
      </div>
      <div class="header-inner">
        <h1>CENTRO DI PRODUZIONE</h1>
        <p class="subtitle">Gestione Lotti Vinicoli & Tracciabilità Smart Contract</p>
      </div>
    </header>

    <main class="dashboard-main">
      <section class="card creation-section">
        <div class="card-title">
          <h2>Configurazione Nuova Produzione</h2>
        </div>
        
        <div class="creation-grid">
          <div class="creation-card rosso">
            <h3>Linea Rosso</h3>
            <div class="creation-controls">
              <div class="input-group">
                <label>N. Lotti</label>
                <input v-model="batchRosso" type="number" min="1" max="10">
              </div>
              <button @click="creaLotti('Vino Rosso', batchRosso)" class="btn btn-rosso">
                Crea Lotti Rosso
              </button>
            </div>
          </div>

          <div class="creation-card bianco">
            <h3>Linea Bianco</h3>
            <div class="creation-controls">
              <div class="input-group">
                <label>N. Lotti</label>
                <input v-model="batchBianco" type="number" min="1" max="10">
              </div>
              <button @click="creaLotti('Vino Bianco', batchBianco)" class="btn btn-bianco">
                Crea Lotti Bianco
              </button>
            </div>
          </div>
        </div>
      </section>

      <section class="card processes-section">
        <div class="card-title">
          <h2>Processi Attivi in Blockchain</h2>
        </div>

        <div class="process-table-container">
          <table class="process-table">
            <thead>
              <tr>
                <th>ID Lotto</th>
                <th>Tipologia / Progresso</th>
                <th>Stato Attuale</th>
                <th>Azioni Sequenziali</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="lotti.length === 0">
                <td colspan="4" class="empty-msg">Nessun lotto creato. Usa il pannello sopra per iniziare.</td>
              </tr>
              <tr v-for="lotto in lotti" :key="lotto.id">
                <td class="id-cell">#{{ lotto.id }}</td>
                <td>
                  <div class="type-progress-col">
                    <span :class="['badge', lotto.tipo.includes('Rosso') ? 'b-rosso' : 'b-bianco']">
                      {{ lotto.tipo }}
                    </span>
                    <div class="progress-container">
                      <div class="progress-bar" :style="{ width: getProgressWidth(lotto.stato) }"></div>
                    </div>
                  </div>
                </td>
                <td>
                  <span :class="['status-pill', lotto.stato]">
                    {{ getStatusLabel(lotto.stato) }}
                  </span>
                </td>
                <td class="actions-cell">
                  <button 
                    @click="avanzaStato(lotto, 'vendemmiato')" 
                    :disabled="lotto.stato !== 'creato'"
                    class="btn-step"
                  >
                    🍇 Vendemmia
                  </button>
                  <button 
                    @click="avanzaStato(lotto, 'fermentato')" 
                    :disabled="lotto.stato !== 'vendemmiato'"
                    class="btn-step">
                    🧪 Fermentazione
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';

const props = defineProps({
  userAddress: String,
  contractInstance: Object 
});

const isMenuOpen = ref(false);
const batchRosso = ref(1);
const batchBianco = ref(1);
const lotti = ref([]);
const loading = ref(false);

// Helper 1: Etichette Testuali
const getStatusLabel = (stato) => {
  const labels = {
    'creato': ' In Attesa',
    'vendemmiato': ' Vendemmiato',
    'fermentato': ' Fermentato'
  };
  return labels[stato] || 'Sconosciuto';
};

// Helper 2: Percentuale Barra di Progresso
const getProgressWidth = (stato) => {
  const widths = {
    'creato': '33%',
    'vendemmiato': '66%',
    'fermentato': '100%'
  };
  return widths[stato] || '0%';
};

// 1. CARICARE I LOTTI REALI DALLA BLOCKCHAIN
const loadLotti = async () => {
  if (!props.contractInstance) {
    console.warn("Contratto non ancora disponibile");
    return;
  }
  
  try {
    const data = await props.contractInstance.methods.getLotti().call();
    console.log("Dati grezzi ricevuti:", data);

    // Mappatura forzata per la reattività di Vue
    const mappedData = data.map((l, index) => ({
      blockchainIndex: index,
      id: l.id.toString(),
      tipo: l.tipo,
      // parseInt è fondamentale perché lo stato arriva come stringa o BigInt
      stato: ['creato', 'vendemmiato', 'fermentato'][parseInt(l.stato)]
    }));

    // Sostituiamo l'intero valore per triggerare la reattività
    lotti.value = mappedData;
    console.log("Lotti mappati pronti per la tabella:", lotti.value);
  } catch (error) {
    console.error("Errore nel recupero dati blockchain:", error);
  }
};

// 2. CREARE UN LOTTO REALE
const creaLotti = async (tipo, quantita) => {
  if (!props.contractInstance || !props.userAddress) return;
  
  loading.value = true;
  try {
    // Nota: Il contratto crea 1 lotto per transazione. 
    // Se batchRosso > 1, qui facciamo un ciclo di transazioni.
    for(let i = 0; i < quantita; i++) {
      await props.contractInstance.methods.creaLotto(tipo).send({ 
        from: props.userAddress 
      });
    }
    
    alert("Transazione/i confermata/e!");
    await loadLotti(); // Ricarica dopo la creazione
  } catch (error) {
    console.error("Errore creazione:", error);
    alert("Transazione rifiutata o fallita.");
  } finally {
    loading.value = false;
  }
};

// 3. AVANZARE LO STATO
const avanzaStato = async (lotto, nuovoStatoInutile) => {
  if (!props.contractInstance) return;
  
  loading.value = true;
  try {
    // Usiamo il blockchainIndex salvato nell'oggetto
    await props.contractInstance.methods.avanzaStato(lotto.blockchainIndex).send({ 
      from: props.userAddress 
    });
    
    await loadLotti(); // Refresh vitale
    alert("Stato aggiornato in Blockchain!");
  } catch (error) {
    console.error("Errore aggiornamento:", error);
    alert("Errore nella transazione.");
  } finally {
    loading.value = false;
  }
};

// Watcher per caricare i dati appena il contratto è pronto
watch(() => props.contractInstance, (newVal) => {
  if (newVal) loadLotti();
}, { immediate: true });

onMounted(() => {
  if (props.contractInstance) loadLotti();
});
</script>

<style scoped>
/* Reset fondamentale per permettere lo scroll */
:global(html), :global(body) {
  margin: 0;
  padding: 0;
  overflow-y: auto !important; /* Forza lo scroll verticale */
  height: auto !important;
}

.producer-page-wrapper {
  width: 100%;
  background-color: #f8f9fa;
  display: block; /* Evita comportamenti flex che bloccano l'altezza */
}

/* HEADER VINACCIA FULL WIDTH */
.vinum-header {
  background-color: #4b0c1e;
  color: white;
  padding: 80px 0; /* Aumentato padding per dare respiro */
  text-align: center;
  box-shadow: 0 4px 15px rgba(0,0,0,0.2);
  
  width: 100vw;
  position: relative;
  left: 50%;
  right: 50%;
  margin-top: -15vh;

  margin-left: -50vw;
  margin-right: -50vw;
}

.header-inner h1 {
  margin: 0;
  font-family: 'Times New Roman', serif;
  font-weight: bold;
  text-transform: uppercase;
  font-size: 3rem;
  letter-spacing: 5px;
  font-weight: 900;
  text-transform: uppercase;
}

/* MAIN CONTENT */
.dashboard-main {
  max-width: 1200px;
  margin: -40px auto 0;
  padding: 0 20px 100px; /* Padding bottom abbondante per lo scroll */
  position: relative;
}

.card {
  width: 900px;
  background: white;
  border-radius: 15px;
  padding: 30px;
  margin-bottom: 35px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.08);
}

.card-title {
  display: flex;
  align-items: center;
  justify-content: center; /* AGGIUNTO: Centra icona e testo orizzontalmente */
  gap: 15px;
  margin-bottom: 25px;
  border-bottom: 2px solid #f0f0f0;
  padding-bottom: 15px;
}

.card-title h2 {
  margin: 0;
  text-align: center; /* Assicura la centratura del testo */
  font-size: 1.8rem;
  color: black;
}
.nav-wrapper {
  position: absolute;
  top: 30px;
  left: 5vw;
  z-index: 100;
}

.hamburger-btn {
  background: none;
  border: none;
  cursor: pointer;
  padding: 10px;
  display: flex;
  flex-direction: column;
  gap: 5px;
  position: relative;
  margin-top : 50px;
}

.bar {
  width: 30px;
  height: 3px;
  background-color: white;
  transition: 0.3s;
}

.bar.open:nth-child(1) { transform: translateY(8px) rotate(45deg); }
.bar.open:nth-child(2) { opacity: 0; }
.bar.open:nth-child(3) { transform: translateY(-8px) rotate(-45deg); }

.dropdown-menu {
  position: absolute;
  top: 50px;
  left: 0;
  background: white;
  min-width: 350px;
  border-radius: 8px;
  box-shadow: 0 10px 25px rgba(0,0,0,0.2);
  padding: 10px 0;
  text-align: left;
}

.dropdown-menu ul { list-style: none; margin: 0; padding: 0; }
.dropdown-menu li {
  padding: 15px 25px;
  color: #333;
  cursor: pointer;
  transition: 0.2s;
  font-weight: 500;
}
.dropdown-menu li:hover { background: #f0f0f0; color: #4b0c1e; }
.divider { height: 1px; background: #eee; margin: 5px 0 !important; padding: 0 !important; }
.logout { color: #d63031 !important; }

.creation-grid { display: flex; gap: 25px; }
.creation-card { flex: 1; padding: 25px; border-radius: 12px; }
.rosso { background: #fff5f6; border: 1px solid #fbd5d8; }
.bianco { background: #fffdf5; border: 1px solid #fcf4d0; }

.creation-controls { display: flex; align-items: flex-end; gap: 15px; margin-top: 15px; }
.input-group input { margin-left:10px; padding: 10px; width: 30px; border-radius: 8px; border: 1px solid #ddd; text-align: center;color: #121212; background-color: white;}

.btn { flex: 1; padding: 12px; border: none; border-radius: 8px; color: white; font-weight: bold; cursor: pointer; }
.btn-rosso { background-color: #8b1a1a; }
.btn-bianco { background-color: #c4a717; color: #1a1a1a; }

/* TABELLA */
.process-table-container { overflow-x: auto; }
.process-table { width: 100%; border-collapse: collapse; }
.process-table th { text-align: left; padding: 15px; background: #fafafa; color: #888; font-size: 0.75rem; }
.process-table td { padding: 18px 15px; border-bottom: 1px solid #f0f0f0; }

.badge { padding: 5px 12px; border-radius: 20px; font-size: 0.8rem; font-weight: 700; color: white; }
.b-rosso { background: #8b1a1a; }
.b-bianco { background: #c4a717; }

.btn-step { background: white; border: 2px solid #4b0c1e; color: #4b0c1e; padding: 6px 14px; border-radius: 6px; cursor: pointer; margin-right: 8px; font-weight: 600; }
.btn-step:hover { background: #4b0c1e; color: white; }

/* SCROLLBAR PERSONALIZZATA */
.custom-scrollbar::-webkit-scrollbar { width: 8px; }
.custom-scrollbar::-webkit-scrollbar-track { background: #1a1a1a; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #333; border-radius: 10px; }


/* TABELLA E PROGRESSO */
.process-table { width: 100%; border-collapse: collapse; }
.process-table th { text-align: left; padding: 15px; background: #fafafa; color: #888; font-size: 0.75rem; text-transform: uppercase; }
.process-table td { padding: 18px 15px; border-bottom: 1px solid #f0f0f0; }

.type-progress-col { display: flex; flex-direction: column; gap: 8px; }

.progress-container {
  width: 100px;
  height: 6px;
  background: #eee;
  border-radius: 10px;
  overflow: hidden;
}

.progress-bar {
  height: 100%;
  background: #4b0c1e;
  transition: width 0.4s ease;
}

.status-pill {
  padding: 4px 10px;
  border-radius: 4px;
  font-size: 0.8rem;
  font-weight: bold;
}
.creato { background: #f0f0f0; color: #888; }
.vendemmiato { background: #e8f5e9; color: #2e7d32; }
.fermentato { background: #e3f2fd; color: #1565c0; }

.id-cell { font-family: monospace; font-weight: bold; color: #4b0c1e; }
.badge { padding: 4px 10px; border-radius: 20px; font-size: 0.7rem; font-weight: bold; color: white; width: fit-content; }
.b-rosso { background: #8b1a1a; }
.b-bianco { background: #c4a717; }

/* BOTTONI SEQUENZIALI */
.btn-step {
  background: white;
  border: 2px solid #4b0c1e;
  color: #4b0c1e;
  padding: 6px 14px;
  border-radius: 6px;
  cursor: pointer;
  margin-right: 8px;
  font-weight: 600;
}

.btn-step:disabled {
  border-color: #ccc;
  color: #ccc;
  cursor: not-allowed;
}

.btn-step:hover:not(:disabled) {
  background: #4b0c1e;
  color: white;
}
</style>
