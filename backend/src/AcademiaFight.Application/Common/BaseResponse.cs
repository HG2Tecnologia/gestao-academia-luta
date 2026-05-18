namespace AcademiaFight.Application.Common;

public class BaseResponse<T>
{
    public bool Sucesso { get; set; }
    public string? Mensagem { get; set; }
    public T? Dados { get; set; }
    public IEnumerable<string> Erros { get; set; } = Enumerable.Empty<string>();

    public static BaseResponse<T> Ok(T dados, string? mensagem = null) => new()
    {
        Sucesso = true,
        Dados = dados,
        Mensagem = mensagem
    };

    public static BaseResponse<T> Falha(string mensagem, IEnumerable<string>? erros = null) => new()
    {
        Sucesso = false,
        Mensagem = mensagem,
        Erros = erros ?? Enumerable.Empty<string>()
    };
}

public class BaseResponse
{
    public bool Sucesso { get; set; }
    public string? Mensagem { get; set; }
    public IEnumerable<string> Erros { get; set; } = Enumerable.Empty<string>();

    public static BaseResponse Ok(string? mensagem = null) =>
        new() { Sucesso = true, Mensagem = mensagem };

    public static BaseResponse Falha(string mensagem, IEnumerable<string>? erros = null) => new()
    {
        Sucesso = false,
        Mensagem = mensagem,
        Erros = erros ?? Enumerable.Empty<string>()
    };
}
