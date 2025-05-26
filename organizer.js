const fs = require('fs');
const path = require('path');
const axios = require('axios');

const DOCUMENTS_DIR = './documents';
const ORGANIZED_DIR = './organized';

async function organizeFiles() {
    const files = fs.readdirSync(DOCUMENTS_DIR);

    for (const file of files) {
        const ext = path.extname(file).slice(1).toLowerCase();
        const extDir = path.join(ORGANIZED_DIR, ext);

        if (!fs.existsSync(extDir)) {
            fs.mkdirSync(extDir, { recursive: true });
        }

        const oldPath = path.join(DOCUMENTS_DIR, file);
        const newPath = path.join(extDir, file);

        try {
            await fs.promises.copyFile(oldPath, newPath);
            await fs.promises.unlink(oldPath);
            console.log(`Moved: ${file} -> ${ext}/`);

            // 🔔 Notify docetl OCR pipeline
            await axios.post('http://docetl:5000/process', {
                path: newPath,
                originalName: file
            });
            console.log(`✅ Notified docetl for: ${file}`);
        } catch (err) {
            console.error(`❌ Move/Notify Error for ${file}: ${err.message}`);
        }
    }
}

setInterval(organizeFiles, 10000); // Run every 10 seconds
