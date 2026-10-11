export const environment = {
  production: false,
  apiUrl: 'http://localhost:5226',
  tenantFallback: 'dev',
  // TODO(migração Firestore): preencher com `firebase apps:sdkconfig web`
  // depois de registrar o app web no projeto `sensei-manager-d64c0`
  // (bloqueado por `firebase login --reauth` pendente no momento em que
  // este arquivo foi criado). Mesmo projeto do app mobile — nunca criar um
  // Firebase project novo para o CRM.
  firebaseConfig: {
    apiKey: '',
    authDomain: '',
    projectId: 'sensei-manager-d64c0',
    storageBucket: '',
    messagingSenderId: '',
    appId: '',
  },
};
