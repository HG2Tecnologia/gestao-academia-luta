import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CatracaService, CatracaValidacaoDto, CatracaAlunoVinculoDto, CatracaAgentConfigDto } from '../../core/services/catraca.service';

interface LogEntry {
  hora: string;
  tipo: 'manual' | 'validacao';
  nome: string;
  sucesso: boolean;
  motivo?: string;
  turmaNome?: string;
}

@Component({
  selector: 'app-catraca',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './catraca.component.html',
})
export class CatracaComponent implements OnInit {
  private readonly catracaService = inject(CatracaService);

  // Abertura manual
  readonly abrindo = signal(false);
  readonly ultimaAbertura = signal<string | null>(null);
  readonly log = signal<LogEntry[]>([]);

  // Busca manual
  readonly buscando = signal(false);
  readonly identificador = signal('');
  readonly resultadoBusca = signal<CatracaValidacaoDto | null>(null);

  // Vínculos
  readonly carregandoVinculos = signal(false);
  readonly vinculos = signal<CatracaAlunoVinculoDto[]>([]);
  readonly buscaVinculo = signal('');
  readonly vinculandoId = signal<string | null>(null);

  // Agente
  readonly agentConfig = signal<CatracaAgentConfigDto | null>(null);
  readonly showConfig = signal(false);

  ngOnInit(): void {
    this.carregarVinculos();
    this.carregarConfig();
  }

  // ── Abertura manual ──────────────────────────────────────────────────────────

  abrirManualmente(): void {
    this.abrindo.set(true);
    this.catracaService.abrirManualmente().subscribe({
      next: (res) => {
        const hora = new Date().toLocaleTimeString('pt-BR');
        this.ultimaAbertura.set(hora);
        this.log.update((l) => [
          { hora, tipo: 'manual', nome: res.dados?.operadorNome ?? 'Operador', sucesso: true },
          ...l.slice(0, 19),
        ]);
        this.abrindo.set(false);
      },
      error: () => this.abrindo.set(false),
    });
  }

  // ── Busca manual ────────────────────────────────────────────────────────────

  buscarAluno(): void {
    if (!this.identificador().trim()) return;
    this.buscando.set(true);
    this.resultadoBusca.set(null);
    this.catracaService.validar(this.identificador()).subscribe({
      next: (res) => {
        const resultado = res.dados ?? null;
        this.resultadoBusca.set(resultado);
        const hora = new Date().toLocaleTimeString('pt-BR');
        this.log.update((l) => [
          {
            hora, tipo: 'validacao',
            nome: resultado?.nomeAluno ?? this.identificador(),
            sucesso: resultado?.permitido ?? false,
            motivo: resultado?.motivo ?? undefined,
            turmaNome: resultado?.turmaNome ?? undefined,
          },
          ...l.slice(0, 19),
        ]);
        this.buscando.set(false);
      },
      error: () => this.buscando.set(false),
    });
  }

  limparBusca(): void {
    this.identificador.set('');
    this.resultadoBusca.set(null);
  }

  // ── Vínculos ─────────────────────────────────────────────────────────────────

  carregarVinculos(): void {
    this.carregandoVinculos.set(true);
    this.catracaService.listarVinculos().subscribe({
      next: (res) => {
        this.vinculos.set(res.dados ?? []);
        this.carregandoVinculos.set(false);
      },
      error: () => this.carregandoVinculos.set(false),
    });
  }

  get vinculosFiltrados(): CatracaAlunoVinculoDto[] {
    const q = this.buscaVinculo().toLowerCase().trim();
    if (!q) return this.vinculos();
    return this.vinculos().filter(v =>
      v.nomeAluno.toLowerCase().includes(q) || (v.email ?? '').toLowerCase().includes(q)
    );
  }

  vincular(aluno: CatracaAlunoVinculoDto): void {
    this.vinculandoId.set(aluno.alunoId);
    this.catracaService.vincularAluno(aluno.alunoId).subscribe({
      next: (res) => {
        if (res.sucesso && res.dados) {
          this.vinculos.update(list =>
            list.map(v => v.alunoId === aluno.alunoId ? { ...v, ...res.dados! } : v)
          );
          alert(`✅ ${res.mensagem ?? 'Aluno vinculado!'}\n\nID no dispositivo: ${res.dados.deviceUserId}\n\nPeça ao aluno para escanear a digital na catraca agora.`);
        } else {
          alert(`Erro: ${res.mensagem}`);
        }
        this.vinculandoId.set(null);
      },
      error: () => this.vinculandoId.set(null),
    });
  }

  desvincular(aluno: CatracaAlunoVinculoDto): void {
    if (!confirm(`Desvincular ${aluno.nomeAluno} da catraca? A digital será removida do dispositivo.`)) return;
    this.vinculandoId.set(aluno.alunoId);
    this.catracaService.desvincularAluno(aluno.alunoId).subscribe({
      next: () => {
        this.vinculos.update(list =>
          list.map(v => v.alunoId === aluno.alunoId ? { ...v, deviceUserId: null, vinculado: false } : v)
        );
        this.vinculandoId.set(null);
      },
      error: () => this.vinculandoId.set(null),
    });
  }

  // ── Agente ───────────────────────────────────────────────────────────────────

  carregarConfig(): void {
    this.catracaService.getAgentConfig().subscribe({
      next: (cfg) => this.agentConfig.set(cfg),
      error: () => {},
    });
  }

  baixarConfig(): void {
    const cfg = this.agentConfig();
    if (!cfg) return;
    const json = JSON.stringify({
      Backend: { Url: cfg.backendUrl, ApiKey: cfg.apiKey, AcademiaId: cfg.academiaId },
      Toletus: { CatracaIp: cfg.toletusCatracaIp }
    }, null, 2);
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'appsettings.json';
    a.click();
    URL.revokeObjectURL(url);
  }

  copiarApiKey(): void {
    const key = this.agentConfig()?.apiKey ?? '';
    navigator.clipboard.writeText(key).then(() => alert('API Key copiada!'));
  }
}
