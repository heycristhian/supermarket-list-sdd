import 'dart:js_interop';

@JS('navigator.storage.persist')
external JSPromise<JSBoolean>? _persist();

/// Pede ao navegador para não apagar os dados do app sob pressão de disco.
/// Sem suporte ou sem permissão, segue em frente: o backup cobre esse caso.
void requestPersistentStorage() {
  try {
    _persist()?.toDart.ignore();
  } catch (_) {
    // API indisponível neste navegador.
  }
}
