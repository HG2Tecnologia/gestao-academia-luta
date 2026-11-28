#!/usr/bin/env node
'use strict';

/**
 * Trava de deploy do CRM (hook `predeploy` do target `crm` em `firebase.json`).
 * O rewrite do Hosting aponta pra `/app-shell.html`, que só o
 * `npm run build:prod` gera. Sem ele, todo `/app/**` devolve 404 no F5 ou em
 * link direto — então o deploy é abortado antes de publicar.
 */

const fs = require('node:fs');
const path = require('node:path');

const shellPath = path.join(__dirname, '..', 'dist', 'academia-fight', 'browser', 'app-shell.html');

if (!fs.existsSync(shellPath)) {
  console.error(
    `check-shell: ${shellPath} não existe — deploy abortado.\n` +
      'Rode `npm run deploy:crm` dentro de frontend-web (faz o build correto e publica).',
  );
  // 2 e não 1: no Windows o `cross-env` do Firebase CLI confunde saída 1 com
  // "comando não encontrado" e esconde a mensagem acima num stack trace.
  process.exit(2);
}

console.log('check-shell: app-shell.html encontrado.');
