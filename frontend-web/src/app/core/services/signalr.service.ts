import { Injectable } from '@angular/core';
import * as signalR from '@microsoft/signalr';
import { environment } from '../../../environments/environment';
import { ConquistaDto, LeaderboardItemDto } from '../models/ranking.model';

@Injectable({ providedIn: 'root' })
export class SignalrService {
  private connection?: signalR.HubConnection;
  private groupJoined = false;

  async startConnection(tenantId: string, token: string): Promise<void> {
    if (this.connection?.state === signalR.HubConnectionState.Connected) {
      if (!this.groupJoined) {
        await this.connection.invoke('EntrarGrupoTenant', tenantId);
        this.groupJoined = true;
      }
      return;
    }

    this.connection = new signalR.HubConnectionBuilder()
      .withUrl(`${environment.apiUrl.replace('/api', '')}/hubs/ranking`, {
        accessTokenFactory: () => token
      })
      .withAutomaticReconnect()
      .configureLogging(signalR.LogLevel.Warning)
      .build();

    await this.connection.start();
    await this.connection.invoke('EntrarGrupoTenant', tenantId);
    this.groupJoined = true;
  }

  onRankingAtualizado(callback: (item: LeaderboardItemDto) => void): void {
    this.connection?.off('ReceberAtualizacaoRanking');
    this.connection?.on('ReceberAtualizacaoRanking', callback);
  }

  onNovaConquista(callback: (conquista: ConquistaDto) => void): void {
    this.connection?.off('ReceberNovaConquista');
    this.connection?.on('ReceberNovaConquista', callback);
  }

  onNovaNotificacao(callback: () => void): void {
    this.connection?.off('ReceberNovaNotificacao');
    this.connection?.on('ReceberNovaNotificacao', callback);
  }

  async stopConnection(): Promise<void> {
    this.groupJoined = false;
    await this.connection?.stop();
  }
}
