import { environment } from '../../../environments/environment';

export function loadAppConfig(): () => Promise<void> {
  return () =>
    fetch('/assets/config.json')
      .then(r => r.json())
      .then((cfg: { apiUrl?: string }) => {
        if (cfg.apiUrl) environment.apiUrl = cfg.apiUrl;
      })
      .catch(() => {
        // config.json ausente — mantém os valores do environment compilado
      });
}
