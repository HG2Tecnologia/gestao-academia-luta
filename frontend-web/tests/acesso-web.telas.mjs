// Abre o web em um navegador de verdade e confere o acesso em cada cenário.
//
// Pré-requisitos (ver docs/black-belt-roteiro-de-testes.md):
//   1. functions:    npm run emu      (deixar aberto)
//   2. functions:    npm run seed:emu
//   3. frontend-web: npm run start:emu (deixar aberto)
//   4. frontend-web: npm i --no-save playwright-core
//   5. frontend-web: npm run test:telas
//
// Usa o Edge instalado (NAVEGADOR=chrome para usar o Chrome). As capturas vão
// para a pasta temporária do sistema, ou para a pasta indicada em CAPTURAS.
// Altera somente a academia de teste do emulador.
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright-core';

const BASE = process.env.BASE_URL || 'http://localhost:4200';
const CAPTURAS = process.env.CAPTURAS || path.join(os.tmpdir(), 'sensei-capturas-web');
const functionsDir = fileURLToPath(new URL('../../functions', import.meta.url));
const ADMIN = ['admin.teste@academia.com', 'admin123'];
const PROFESSOR = ['prof.teste@academia.com', 'prof123'];

const cenario = (...args) =>
  execFileSync(process.execPath, ['scripts/cenario-assinatura.js', ...args], {
    cwd: functionsDir,
    stdio: 'pipe',
  });

// [cenário, entra no sistema?, texto esperado no selo ou no título da trava]
const MATRIZ = [
  ['gratis', false, 'Seu período de teste terminou'],
  ['teste', true, 'Teste: 30 dias'],
  ['teste-acabando', true, 'Teste: 3 dias'],
  ['pro', false, 'O sistema web faz parte do Black Belt'],
  ['black', true, 'Black Belt'],
  ['pro-cancelado', false, 'O sistema web faz parte do Black Belt'],
  ['black-cancelado', true, 'Black Belt'],
  ['pro-carencia', false, 'O sistema web faz parte do Black Belt'],
  ['black-carencia', true, 'Black Belt'],
  ['expirado', false, 'Seu período de teste terminou'],
  ['reembolsado', false, 'Seu período de teste terminou'],
  ['suspenso', false, 'Assinatura suspensa'],
  ['cortesia-web', true, 'Acesso cortesia'],
  ['cortesia', false, 'O sistema web faz parte do Black Belt'],
];

fs.mkdirSync(CAPTURAS, { recursive: true });
const navegador = await chromium.launch({ channel: process.env.NAVEGADOR || 'msedge' });
let conferidos = 0;
const falhas = [];

async function entrar([email, senha]) {
  const contexto = await navegador.newContext({ viewport: { width: 1280, height: 800 } });
  const pagina = await contexto.newPage();
  await pagina.goto(`${BASE}/login`);
  await pagina.locator('input[formcontrolname="identificador"]').fill(email);
  await pagina.locator('input[formcontrolname="senha"]').fill(senha);
  await pagina.locator('button.btn-submit').click();
  await pagina.waitForURL(/\/(app\/dashboard|assinatura)/, { timeout: 30_000 });
  return { contexto, pagina };
}

async function conferir(nome, passo) {
  try {
    await passo();
    conferidos++;
    console.log(`ok     ${nome}`);
  } catch (erro) {
    falhas.push(nome);
    console.log(`FALHOU ${nome}: ${erro.message.split('\n')[0]}`);
  }
}

async function esperar(pagina, entra, texto) {
  await pagina.waitForURL(entra ? /\/app\/dashboard/ : /\/assinatura/, { timeout: 15_000 });
  const alvo = entra ? pagina.locator('.plan-badge-btn') : pagina.locator('h1');
  await alvo.filter({ hasText: texto }).waitFor({ timeout: 15_000 });
}

try {
  cenario('bloqueio', 'ligado');
  for (const [nome, entra, texto] of MATRIZ) {
    await conferir(`trava ligada, ${nome}`, async () => {
      cenario(nome);
      const { contexto, pagina } = await entrar(ADMIN);
      try {
        await esperar(pagina, entra, texto);
        await pagina.screenshot({ path: path.join(CAPTURAS, `${nome}.png`) });
      } finally {
        await contexto.close();
      }
    });
  }

  await conferir('trava ligada: endereço interno digitado também é barrado', async () => {
    cenario('pro');
    const { contexto, pagina } = await entrar(ADMIN);
    await pagina.goto(`${BASE}/app/alunos`);
    await pagina.waitForURL(/\/assinatura/, { timeout: 15_000 });
    await contexto.close();
  });

  await conferir('"verificar novamente" avisa e depois libera quem assinou', async () => {
    cenario('pro');
    const { contexto, pagina } = await entrar(ADMIN);
    const botao = pagina.getByRole('button', { name: /verificar novamente/ });
    await botao.click();
    await pagina.getByRole('status').waitFor({ timeout: 15_000 });
    cenario('black');
    await botao.click();
    await esperar(pagina, true, 'Black Belt');
    await contexto.close();
  });

  await conferir('professor sem direito é orientado a falar com o administrador', async () => {
    cenario('gratis');
    const { contexto, pagina } = await entrar(PROFESSOR);
    await pagina.getByText('Peça a quem administra a academia').waitFor({ timeout: 15_000 });
    assert.equal(await pagina.locator('ol.passos').count(), 0);
    await pagina.screenshot({ path: path.join(CAPTURAS, 'professor-bloqueado.png') });
    await contexto.close();
  });

  await conferir('botão Sair volta para o login', async () => {
    cenario('gratis');
    const { contexto, pagina } = await entrar(ADMIN);
    await pagina.getByRole('button', { name: 'Sair' }).click();
    await pagina.waitForURL(/\/login/, { timeout: 15_000 });
    await contexto.close();
  });

  await conferir('assinatura de contrato pública não passa pela trava', async () => {
    cenario('gratis');
    const contexto = await navegador.newContext();
    const pagina = await contexto.newPage();
    await pagina.goto(`${BASE}/assinar/token-de-teste`);
    await pagina.waitForTimeout(3000);
    assert.match(pagina.url(), /\/assinar\/token-de-teste/);
    await contexto.close();
  });

  cenario('bloqueio', 'desligado');
  for (const [nome, texto] of [
    ['gratis', 'Plano Gratuito'],
    ['pro', 'Sensei PRO'],
    ['black', 'Black Belt'],
  ]) {
    await conferir(`trava desligada, ${nome}: entra`, async () => {
      cenario(nome);
      const { contexto, pagina } = await entrar(ADMIN);
      await esperar(pagina, true, texto);
      await pagina.screenshot({ path: path.join(CAPTURAS, `desligada-${nome}.png`) });
      await contexto.close();
    });
  }
} finally {
  cenario('bloqueio', 'desligado');
  await navegador.close();
}

console.log(`\n${conferidos} verificações passaram, ${falhas.length} falharam.`);
console.log(`Capturas em: ${CAPTURAS}`);
process.exitCode = falhas.length ? 1 : 0;
