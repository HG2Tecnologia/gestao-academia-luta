namespace AcademiaFight.Application.Common;

public class PagedResult<T>
{
    public IEnumerable<T> Itens { get; set; } = Enumerable.Empty<T>();
    public int TotalItens { get; set; }
    public int Pagina { get; set; }
    public int TamanhoPagina { get; set; }
    public int TotalPaginas => (int)Math.Ceiling((double)TotalItens / TamanhoPagina);
    public bool TemProxima => Pagina < TotalPaginas;
    public bool TemAnterior => Pagina > 1;
}
