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

public record CatracaAlunoVinculoDto(
    Guid AlunoId,
    string NomeAluno,
    string? Email,
    int? DeviceUserId,
    bool Vinculado
);

public record CatracaVincularRequest(Guid AlunoId, int? DeviceUserId = null);

public record CatracaAgentConfigDto(
    string BackendUrl,
    string ApiKey,
    string AcademiaId,
    string ToletusCatracaIp
);
