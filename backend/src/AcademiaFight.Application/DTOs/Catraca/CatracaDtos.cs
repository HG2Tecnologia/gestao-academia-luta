namespace AcademiaFight.Application.DTOs.Catraca;

public record CatracaValidacaoDto(
    bool Permitido,
    string? NomeAluno,
    string? Motivo,
    bool PresencaRegistrada = false,
    string? TurmaNome = null
);

public record CatracaAberturaManuaDto(
    bool Aberta,
    DateTime AbertaEm,
    string OperadorNome
);
