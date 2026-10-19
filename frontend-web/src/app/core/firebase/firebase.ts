import { initializeApp, getApps, getApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getFunctions } from 'firebase/functions';
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
