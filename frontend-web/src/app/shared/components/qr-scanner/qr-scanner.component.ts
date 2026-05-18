import { Component, Input, Output, EventEmitter, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ZXingScannerModule } from '@zxing/ngx-scanner';
import { BarcodeFormat } from '@zxing/library';

@Component({
  selector: 'app-qr-scanner',
  standalone: true,
  imports: [CommonModule, ZXingScannerModule],
  template: `
    @if (ativo) {
      @if (!contextoSeguro) {
        <div class="qr-https-aviso">
          <svg width="32" height="32" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
            <rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>
          </svg>
          <p>O scanner de QR Code requer uma conexão segura (HTTPS).</p>
          <span>Acesse a aplicação via HTTPS para usar a câmera.</span>
        </div>
      } @else {
        <div class="qr-wrapper">
          <zxing-scanner
            [formats]="formatos"
            (scanSuccess)="onScan($event)"
            (permissionResponse)="onPermissao($event)"
          ></zxing-scanner>
          <div class="qr-overlay">
            <div class="qr-mira"></div>
          </div>
          @if (semPermissao) {
            <p class="qr-erro">Permissão de câmera negada. Verifique as configurações do navegador.</p>
          }
        </div>
      }
    }
  `,
  styles: [`
    .qr-wrapper { position: relative; width: 100%; max-width: 360px; margin: 0 auto; border-radius: 8px; overflow: hidden; }
    .qr-overlay { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; pointer-events: none; }
    .qr-mira { width: 180px; height: 180px; border: 3px solid rgba(255,255,255,0.9); border-radius: 8px; box-shadow: 0 0 0 9999px rgba(0,0,0,0.45); }
    .qr-erro { color: #ef4444; text-align: center; padding: 1rem; font-size: 0.875rem; }
    .qr-https-aviso { display: flex; flex-direction: column; align-items: center; gap: 8px; padding: 24px; border-radius: 8px; background: rgba(239,68,68,0.08); border: 1px solid rgba(239,68,68,0.25); text-align: center; max-width: 360px; margin: 0 auto; color: #ef4444; }
    .qr-https-aviso p { margin: 0; font-size: 0.9rem; font-weight: 600; }
    .qr-https-aviso span { font-size: 0.8rem; color: #f87171; }
  `],
})
export class QrScannerComponent implements OnDestroy {
  @Input() ativo = false;
  @Output() codigoDetectado = new EventEmitter<string>();

  readonly formatos = [BarcodeFormat.QR_CODE];
  readonly contextoSeguro = window.isSecureContext;
  semPermissao = false;

  onScan(resultado: string): void {
    this.codigoDetectado.emit(resultado);
  }

  onPermissao(temPermissao: boolean): void {
    this.semPermissao = !temPermissao;
  }

  ngOnDestroy(): void {
    this.ativo = false;
  }
}
