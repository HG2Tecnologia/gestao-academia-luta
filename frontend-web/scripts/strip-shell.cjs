#!/usr/bin/env node
'use strict';

/**
 * O build com `prerender` sobrescreve `dist/.../browser/index.html` com o
 * HTML já renderizado da home (bom pra quem pede `/` direto). O problema:
 * o rewrite catch-all do Firebase Hosting (`** -> /index.html`) usa esse
 * MESMO arquivo como fallback de SPA pra qualquer rota sem prerender
 * (`/login`, `/cadastro`, `/app/**`), e o conteúdo da home fica "preso"
 * porque o Angular faz bootstrap em cima de um DOM que já não é um shell
 * vazio. Este script gera um `app-shell.html` ao lado — mesmo
 * `<head>`/scripts, mas com `<app-root>` vazio — só pra esse fallback.
 * `firebase.json` aponta o rewrite pra esse arquivo, não pro `index.html`.
 */

const fs = require('node:fs');
const path = require('node:path');

const browserDir = path.join(__dirname, '..', 'dist', 'academia-fight', 'browser');
const indexPath = path.join(browserDir, 'index.html');
const shellPath = path.join(browserDir, 'app-shell.html');

const html = fs.readFileSync(indexPath, 'utf8');
const shell = html.replace(/<app-root[^>]*>[\s\S]*<\/app-root>/, '<app-root></app-root>');

if (shell === html) {
  console.error('strip-shell: não encontrou <app-root>...</app-root> em index.html — abortando.');
  process.exit(1);
}

fs.writeFileSync(shellPath, shell);
console.log('strip-shell: app-shell.html gerado em', shellPath);
