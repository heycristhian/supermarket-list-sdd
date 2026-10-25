/// Erros de regra de negócio, com mensagens pt-BR prontas para exibir.
sealed class DomainException implements Exception {
  const DomainException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EmptyNameException extends DomainException {
  const EmptyNameException() : super('Informe um nome.');
}

class NameTooLongException extends DomainException {
  const NameTooLongException(this.maxLength)
    : super('Use no máximo $maxLength caracteres.');

  final int maxLength;
}

class DuplicateNameException extends DomainException {
  const DuplicateNameException.list()
    : super('Já existe uma lista com esse nome.');

  const DuplicateNameException.item() : super('Esse item já está na lista.');
}

class InvalidBackupException extends DomainException {
  const InvalidBackupException(super.message);
}
