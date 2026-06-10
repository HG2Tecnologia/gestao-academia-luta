import { environment } from '../../../environments/environment';

export function loadAppConfig(): () => Promise<void> {
  return () => {
    const configFile = environment.production ? '/assets/config.prod.json' : '/assets/config.json';
    return fetch(configFile)
      .then(r => r.json())
      .then((cfg: { apiUrl?: string }) => {
        if (cfg.apiUrl) environment.apiUrl = cfg.apiUrl;
      })
      .catch(() => {});
  };
}
