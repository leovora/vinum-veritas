const fs = require('fs');
const path = require('path');

// Correzione percorsi: ora usciamo da frontend per trovare backend
const srcPath = path.join(__dirname, '..', 'backend', 'build', 'contracts', 'WineProduction.json');
const destPath = path.join(__dirname, 'src', 'abis', 'WineProduction.json');

function copyAbi() {
    console.log('--- SYNC ABIs ---');
    try {
        if (!fs.existsSync(srcPath)) {
            console.error('❌ Sorgente non trovata in: ' + srcPath);
            return;
        }

        const destDir = path.dirname(destPath);
        if (!fs.existsSync(destDir)) fs.mkdirSync(destDir, { recursive: true });

        fs.copyFileSync(srcPath, destPath);
        console.log('✅ ABI sincronizzato con successo!');
    } catch (err) {
        console.error('❌ Errore:', err);
    }
}

copyAbi();