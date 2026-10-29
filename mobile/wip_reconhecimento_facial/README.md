# Reconhecimento facial (em desenvolvimento)

Feature completa (código + modelo), mas retirada do app por enquanto —
`google_mlkit_face_detection`/`google_mlkit_commons` exige iOS 15.5+, e não
vale cortar quem está em versões mais antigas do iOS só pra carregar uma
biblioteca de uma feature que ainda ninguém pode usar (ela também já estava
escondida via `lib/core/feature_flags.dart`).

## Pra reativar quando a feature estiver pronta pra lançar

1. `git mv wip_reconhecimento_facial/face_recognition_service.dart lib/core/`
2. `git mv wip_reconhecimento_facial/chamada_foto_screen.dart lib/screens/professor/`
3. `git mv wip_reconhecimento_facial/assets_ml assets/ml`
4. `flutter pub add google_mlkit_face_detection tflite_flutter`
5. Em `pubspec.yaml`, volta a listar `assets/ml/facenet.tflite` nos assets.
6. Em `lib/screens/aluno/aluno_perfil_screen.dart`: volta o import de
   `face_recognition_service.dart` e a chamada de
   `FaceRecognitionService.embeddingFromBase64Photo(...)` dentro de
   `_alterarConsentimentoRosto` (removida nessa saída — ver histórico do
   git nesse commit).
7. Em `lib/screens/professor/prof_turma_detalhe_screen.dart`: volta o
   import de `chamada_foto_screen.dart` e o botão que abre
   `ChamadaFotoScreen` (idem).
8. Liga `kFeatureReconhecimentoFacialAtiva` em `lib/core/feature_flags.dart`.
9. **Decide o iOS mínimo junto com o time** nesse momento — é uma escolha
   de produto (cortar iOS <15.5), não algo pra acontecer de lado.
