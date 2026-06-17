namespace AcademiaFight.Application.DTOs.Noticia;

public class NoticiaDto
{
    public Guid Id { get; set; }
    public string Titulo { get; set; } = string.Empty;
    public string Resumo { get; set; } = string.Empty;
    public string? Conteudo { get; set; }
    public string? ImagemBase64 { get; set; }
    public bool Publicada { get; set; }
    public DateTime? PublicadaEm { get; set; }
    public string? AutorNome { get; set; }
    public DateTime CriadoEm { get; set; }
}

public class CriarNoticiaRequest
{
    public string Titulo { get; set; } = string.Empty;
    public string Resumo { get; set; } = string.Empty;
    public string? Conteudo { get; set; }
    public string? ImagemBase64 { get; set; }
    public bool PublicarAgora { get; set; } = false;
}

public class AtualizarNoticiaRequest
{
    public string Titulo { get; set; } = string.Empty;
    public string Resumo { get; set; } = string.Empty;
    public string? Conteudo { get; set; }
    public string? ImagemBase64 { get; set; }
}

public class ListarNoticiasResponse
{
    public IEnumerable<NoticiaDto> Items { get; set; } = [];
    public int Total { get; set; }
    public int Pagina { get; set; }
    public int TotalPaginas { get; set; }
}
