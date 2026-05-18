namespace AcademiaFight.Application.DTOs.Ranking;

public class PerfilGamificadoDto
{
    public Guid AlunoId { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string Nivel { get; set; } = string.Empty;
    public int XpTotal { get; set; }
    public int XpMensal { get; set; }
    public int XpParaProximoNivel { get; set; }
    public int PosicaoGlobal { get; set; }
    public int PosicaoTurma { get; set; }
    public int SequenciaAtual { get; set; }
    public IEnumerable<ConquistaDto> ConquistasDesbloqueadas { get; set; } = [];
    public IEnumerable<HistoricoXpItemDto> HistoricoXp { get; set; } = [];
}
