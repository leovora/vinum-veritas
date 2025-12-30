const fs = require('fs');
const path = require('path');

// Usa percorsi assoluti basati sulla posizione di questo script
const BACKEND_JSON = path.resolve(__dirname, '../backend/build/contracts/WineProduction.json');
const FRONTEND_JSON = path.resolve(__dirname, './src/abis/WineProduction.json');

function sync() {
    console.log('--- 🔄 Sincronizzazione ABI Integrale ---');

    try {
        // 1. Verifica esistenza file sorgente
        if (!fs.existsSync(BACKEND_JSON)) {
            console.error(`❌ ERRORE: Sorgente non trovata in: ${BACKEND_JSON}`);
            return;
        }

        // 2. Lettura integrale del file come testo grezzo per evitare alterazioni
        const rawContent = fs.readFileSync(BACKEND_JSON, 'utf8');
        const jsonData = JSON.parse(rawContent);

        // 3. VERIFICA CONTENUTO: Il file ha la funzione nuova?
        const hasFunction = jsonData.abi.some(item => item.name === 'getAllUserAddresses');
        
        if (!hasFunction) {
            console.error('⚠️ ATTENZIONE: Il file nel backend NON ha ancora la funzione "getAllUserAddresses".');
            console.log('👉 Hai salvato il file .sol e lanciato "truffle compile"?');
            return;
        }

        // 4. Scrittura forzata nella destinazione
        const destDir = path.dirname(FRONTEND_JSON);
        if (!fs.existsSync(destDir)) fs.mkdirSync(destDir, { recursive: true });

        fs.writeFileSync(FRONTEND_JSON, rawContent, { encoding: 'utf8', flag: 'w' });

        // 5. Conferma finale
        const networkId = Object.keys(jsonData.networks || {})[0] || "Nessuna rete";
        const address = jsonData.networks[networkId]?.address || "Nessun indirizzo";

        console.log(`✅ COPIA COMPLETATA: Il file è stato aggiornato correttamente.`);
        console.log(`📍 Funzione "getAllUserAddresses": TROVATA`);
        console.log(`🌐 Network ID: ${networkId}`);
        console.log(`🏢 Indirizzo Contratto: ${address}`);

    } catch (error) {
        console.error('❌ ERRORE CRITICO:', error.message);
    }
}

sync();