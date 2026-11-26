import { initializeApp, getApps, getApp } from 'firebase/app';
import { connectAuthEmulator, getAuth } from 'firebase/auth';
import { connectFirestoreEmulator, getFirestore } from 'firebase/firestore';
import { connectFunctionsEmulator, getFunctions } from 'firebase/functions';
import { environment } from '../../../environments/environment';

/**
 * Mesmo projeto Firebase do app mobile (`sensei-manager-d64c0`) — é o
 * requisito central da migração do CRM: ver os MESMOS dados em tempo real,
 * sem sincronização nenhuma por fora. Nunca crie um segundo projeto
 * Firebase para o CRM.
 */
const app = getApps().length ? getApp() : initializeApp(environment.firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
export const functions = getFunctions(app);

// Portas iguais às de `firebase.json`. Precisa rodar antes de qualquer leitura
// ou escrita, por isso fica aqui, junto da criação das instâncias.
if (environment.useEmulators) {
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  connectFirestoreEmulator(db, '127.0.0.1', 8080);
  connectFunctionsEmulator(functions, '127.0.0.1', 5001);
}
