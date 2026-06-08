using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace AcademiaFight.Application.Services;

public interface IModalidadeSeedService
{
    Task SeedParaAcademiaAsync(Guid academiaId, CancellationToken ct = default);
}

public class ModalidadeSeedService(IAppDbContext db) : IModalidadeSeedService
{
    public async Task SeedParaAcademiaAsync(Guid academiaId, CancellationToken ct = default)
    {
        var jaTemModalidades = await db.Modalidades.AnyAsync(m => m.AcademiaId == academiaId, ct);
        if (jaTemModalidades) return;

        foreach (var template in Templates)
        {
            var modalidade = new Modalidade
            {
                AcademiaId = academiaId,
                Nome = template.Nome,
                Descricao = template.Descricao,
                Ativo = true,
            };
            await db.Modalidades.AddAsync(modalidade, ct);

            for (var i = 0; i < template.Faixas.Length; i++)
            {
                var f = template.Faixas[i];
                await db.Faixas.AddAsync(new Faixa
                {
                    AcademiaId = academiaId,
                    ModalidadeId = modalidade.Id,
                    Nome = f.Nome,
                    Cor = f.Cor,
                    CorBarra = f.CorBarra,
                    TemGraus = f.TemGraus,
                    MaxGraus = f.MaxGraus,
                    Ordem = i + 1,
                    RequisitosMesesMinimos = f.MesesMinimos,
                    RequisitosPresencasMinimas = f.PresencasMinimas,
                    Descricao = f.Descricao,
                }, ct);
            }
        }

        await db.SaveChangesAsync(ct);
    }

    // ─── Templates ────────────────────────────────────────────────────────────

    private static readonly ModalidadeTemplate[] Templates =
    [
        new("Jiu-Jitsu Brasileiro — Adulto",
            "Sistema de faixas IBJJF para praticantes com 16 anos ou mais.",
            [
                new("Branca",          "#FFFFFF", "#1A1A1A", TemGraus: true,  MaxGraus: 4, MesesMinimos: 0),
                new("Azul",            "#1565C0", "#1A1A1A", TemGraus: true,  MaxGraus: 4, MesesMinimos: 24, PresencasMinimas: 50),
                new("Roxa",            "#6A1B9A", "#1A1A1A", TemGraus: true,  MaxGraus: 4, MesesMinimos: 48, PresencasMinimas: 100),
                new("Marrom",          "#4E342E", "#1A1A1A", TemGraus: true,  MaxGraus: 4, MesesMinimos: 72, PresencasMinimas: 150),
                new("Preta",           "#212121", "#C62828", TemGraus: true,  MaxGraus: 6, MesesMinimos: 120),
                new("Coral e Preta",   "#E64A19", "#212121", TemGraus: false, MesesMinimos: 360,
                    Descricao: "7° e 8° grau — Professor/Mestre"),
                new("Coral e Branca",  "#E64A19", "#FFFFFF", TemGraus: false, MesesMinimos: 420,
                    Descricao: "9° grau — Mestre"),
                new("Vermelha",        "#C62828", "#C62828", TemGraus: false, MesesMinimos: 480,
                    Descricao: "10° grau — Grão-Mestre"),
            ]),

        new("Jiu-Jitsu Brasileiro — Infanto-Juvenil",
            "Sistema de faixas IBJJF para praticantes com até 15 anos de idade.",
            [
                new("Branca",           "#FFFFFF", "#1A1A1A", TemGraus: true, MaxGraus: 4),
                new("Cinza e Branca",   "#9E9E9E", "#FFFFFF", TemGraus: true, MaxGraus: 4, MesesMinimos: 3),
                new("Cinza",            "#9E9E9E", "#9E9E9E", TemGraus: true, MaxGraus: 4, MesesMinimos: 6),
                new("Cinza e Preta",    "#9E9E9E", "#1A1A1A", TemGraus: true, MaxGraus: 4, MesesMinimos: 9),
                new("Amarela e Branca", "#F9A825", "#FFFFFF", TemGraus: true, MaxGraus: 4, MesesMinimos: 12),
                new("Amarela",          "#F9A825", "#F9A825", TemGraus: true, MaxGraus: 4, MesesMinimos: 15),
                new("Amarela e Preta",  "#F9A825", "#1A1A1A", TemGraus: true, MaxGraus: 4, MesesMinimos: 18),
                new("Laranja e Branca", "#E65100", "#FFFFFF", TemGraus: true, MaxGraus: 4, MesesMinimos: 24),
                new("Laranja",          "#E65100", "#E65100", TemGraus: true, MaxGraus: 4, MesesMinimos: 27),
                new("Laranja e Preta",  "#E65100", "#1A1A1A", TemGraus: true, MaxGraus: 4, MesesMinimos: 30),
                new("Verde e Branca",   "#2E7D32", "#FFFFFF", TemGraus: true, MaxGraus: 4, MesesMinimos: 36),
                new("Verde",            "#2E7D32", "#2E7D32", TemGraus: true, MaxGraus: 4, MesesMinimos: 39),
                new("Verde e Preta",    "#2E7D32", "#1A1A1A", TemGraus: true, MaxGraus: 4, MesesMinimos: 42),
            ]),

        new("Luta Livre",
            "Sistema de graduação por faixas para Luta Livre Esportiva.",
            [
                new("Branca",  "#FFFFFF", "#1A1A1A", TemGraus: true, MaxGraus: 4),
                new("Amarela", "#F9A825", "#1A1A1A", TemGraus: true, MaxGraus: 4, MesesMinimos: 6,
                    Descricao: "A partir dos 6 anos"),
                new("Laranja", "#E65100", "#1A1A1A", TemGraus: true, MaxGraus: 4, MesesMinimos: 18,
                    Descricao: "A partir dos 11 anos"),
                new("Azul",    "#1565C0", "#1A1A1A", TemGraus: true, MaxGraus: 4, MesesMinimos: 30,
                    Descricao: "A partir dos 16 anos"),
                new("Roxa",    "#6A1B9A", "#1A1A1A", TemGraus: true, MaxGraus: 4, MesesMinimos: 48),
                new("Marrom",  "#4E342E", "#1A1A1A", TemGraus: true, MaxGraus: 4, MesesMinimos: 72),
                new("Preta",   "#212121", "#C62828", TemGraus: true, MaxGraus: 4, MesesMinimos: 96),
            ]),

        new("Muay Thai — Adulto",
            "Sistema de prajioud (armbands) para adultos — Iniciante ao Grão-Mestre.",
            [
                new("Branca",                 "#FFFFFF", "#1A1A1A", Descricao: "Iniciante"),
                new("Branca e Vermelha",      "#FFFFFF", "#C62828", MesesMinimos: 3,  Descricao: "Iniciante"),
                new("Vermelha",               "#C62828", "#C62828", MesesMinimos: 6,  Descricao: "Iniciante"),
                new("Vermelha e Azul Claro",  "#C62828", "#00ACC1", MesesMinimos: 12, Descricao: "Intermediário"),
                new("Azul Claro",             "#00ACC1", "#00ACC1", MesesMinimos: 18, Descricao: "Intermediário"),
                new("Azul",                   "#1565C0", "#1565C0", MesesMinimos: 24, Descricao: "Intermediário"),
                new("Azul Escuro",            "#0D47A1", "#0D47A1", MesesMinimos: 36, Descricao: "Instrutor Auxiliar"),
                new("Preta e Azul",           "#212121", "#1565C0", MesesMinimos: 48, Descricao: "Instrutor"),
                new("Preta",                  "#212121", "#212121", MesesMinimos: 60, Descricao: "Professor"),
                new("Preta e Branca",         "#212121", "#FFFFFF", MesesMinimos: 96, Descricao: "Mestre"),
                new("Preta e Vermelha",       "#212121", "#C62828", MesesMinimos: 144, Descricao: "Grão-Mestre"),
            ]),

        new("Muay Thai — Infanto-Juvenil",
            "Sistema de prajioud (armbands) para crianças e adolescentes.",
            [
                new("Branca",              "#FFFFFF", "#1A1A1A"),
                new("Cinza e Branca",      "#9E9E9E", "#FFFFFF", MesesMinimos: 3),
                new("Cinza",               "#9E9E9E", "#9E9E9E", MesesMinimos: 6),
                new("Cinza e Amarela",     "#9E9E9E", "#F9A825", MesesMinimos: 9),
                new("Amarela e Branca",    "#F9A825", "#FFFFFF", MesesMinimos: 12),
                new("Amarela",             "#F9A825", "#F9A825", MesesMinimos: 15),
                new("Amarela e Laranja",   "#F9A825", "#E65100", MesesMinimos: 18),
                new("Laranja e Branca",    "#E65100", "#FFFFFF", MesesMinimos: 21),
                new("Laranja",             "#E65100", "#E65100", MesesMinimos: 24),
                new("Laranja e Verde",     "#E65100", "#2E7D32", MesesMinimos: 27),
                new("Verde e Branca",      "#2E7D32", "#FFFFFF", MesesMinimos: 30),
                new("Verde",               "#2E7D32", "#2E7D32", MesesMinimos: 33),
                new("Verde e Vermelha",    "#2E7D32", "#C62828", MesesMinimos: 36),
            ]),

        new("Karate",
            "Sistema de kyu e dan — graduação mais comum no estilo Shotokan/WKF.",
            [
                new("Branca — 9º Kyu",    "#FFFFFF", "#1A1A1A"),
                new("Amarela — 8º Kyu",   "#F9A825", "#1A1A1A", MesesMinimos: 3),
                new("Laranja — 7º Kyu",   "#E65100", "#1A1A1A", MesesMinimos: 6),
                new("Verde — 6º Kyu",     "#2E7D32", "#1A1A1A", MesesMinimos: 9),
                new("Azul — 5º Kyu",      "#1565C0", "#1A1A1A", MesesMinimos: 12),
                new("Roxa — 4º Kyu",      "#6A1B9A", "#1A1A1A", MesesMinimos: 18),
                new("Marrom — 3º Kyu",    "#4E342E", "#1A1A1A", MesesMinimos: 24),
                new("Marrom — 2º Kyu",    "#4E342E", "#1A1A1A", MesesMinimos: 30),
                new("Marrom — 1º Kyu",    "#4E342E", "#1A1A1A", MesesMinimos: 36),
                new("Preta",              "#212121", "#C62828", TemGraus: true, MaxGraus: 10, MesesMinimos: 48,
                    Descricao: "1° ao 10° Dan"),
            ]),

        new("Judô",
            "Sistema de kyu e dan conforme Confederação Brasileira de Judô (CBJ).",
            [
                new("Branca",  "#FFFFFF", "#1A1A1A",  Descricao: "6° Kyu"),
                new("Cinza",   "#9E9E9E", "#1A1A1A",  MesesMinimos: 3,  Descricao: "5° Kyu — Crianças"),
                new("Amarela", "#F9A825", "#1A1A1A",  MesesMinimos: 6,  Descricao: "5°/4° Kyu"),
                new("Laranja", "#E65100", "#1A1A1A",  MesesMinimos: 12, Descricao: "3° Kyu"),
                new("Verde",   "#2E7D32", "#1A1A1A",  MesesMinimos: 18, Descricao: "2° Kyu"),
                new("Azul",    "#1565C0", "#1A1A1A",  MesesMinimos: 24, Descricao: "1° Kyu"),
                new("Marrom",  "#4E342E", "#1A1A1A",  MesesMinimos: 36, Descricao: "1° a 3° Kyu sênior"),
                new("Preta",   "#212121", "#C62828",  TemGraus: true, MaxGraus: 5, MesesMinimos: 48,
                    Descricao: "1° ao 5° Dan"),
                new("Vermelha e Branca", "#C62828", "#FFFFFF", MesesMinimos: 120,
                    Descricao: "6° ao 8° Dan"),
                new("Vermelha",          "#C62828", "#C62828", MesesMinimos: 180,
                    Descricao: "9° e 10° Dan"),
            ]),

        new("Taekwondo",
            "Sistema de geup e dan conforme World Taekwondo (WT).",
            [
                new("Branca",   "#FFFFFF", "#1A1A1A",  Descricao: "10° Geup"),
                new("Amarela",  "#F9A825", "#1A1A1A",  MesesMinimos: 3,  Descricao: "9°/8° Geup"),
                new("Verde",    "#2E7D32", "#1A1A1A",  MesesMinimos: 9,  Descricao: "7°/6° Geup"),
                new("Azul",     "#1565C0", "#1A1A1A",  MesesMinimos: 18, Descricao: "5°/4° Geup"),
                new("Vermelha", "#C62828", "#1A1A1A",  MesesMinimos: 30, Descricao: "3°/2°/1° Geup"),
                new("Preta",    "#212121", "#C62828",  TemGraus: true, MaxGraus: 9, MesesMinimos: 42,
                    Descricao: "1° ao 9° Dan"),
            ]),

        new("Boxe",
            "Graduação adaptada para academias — sem sistema de faixas oficial na modalidade.",
            [
                new("Iniciante",         "#FFFFFF", "#1A1A1A", Descricao: "Fundamentos e postura"),
                new("Básico",            "#F9A825", "#1A1A1A", MesesMinimos: 6,  Descricao: "Combinações e defesa"),
                new("Intermediário",     "#2E7D32", "#1A1A1A", MesesMinimos: 12, Descricao: "Sparring e estratégia"),
                new("Avançado",          "#1565C0", "#1A1A1A", MesesMinimos: 24, Descricao: "Técnica refinada"),
                new("Competidor",        "#C62828", "#1A1A1A", MesesMinimos: 36, Descricao: "Preparo para competição"),
                new("Elite/Profissional","#212121", "#C62828", MesesMinimos: 60, Descricao: "Alto rendimento"),
            ]),

        new("Capoeira",
            "Sistema de cordas/cordões conforme CBCE (Confederação Brasileira de Capoeira).",
            [
                new("Cru",              "#DEB887", "#DEB887", Descricao: "Iniciante"),
                new("Amarela",          "#F9A825", "#F9A825", MesesMinimos: 6),
                new("Laranja",          "#E65100", "#E65100", MesesMinimos: 12),
                new("Azul",             "#1565C0", "#1565C0", MesesMinimos: 18),
                new("Verde",            "#2E7D32", "#2E7D32", MesesMinimos: 24),
                new("Roxa",             "#6A1B9A", "#6A1B9A", MesesMinimos: 36),
                new("Marrom",           "#4E342E", "#4E342E", MesesMinimos: 48),
                new("Vermelha",         "#C62828", "#C62828", MesesMinimos: 60, Descricao: "Graduado"),
                new("Vermelha e Preta", "#C62828", "#212121", MesesMinimos: 84, Descricao: "Professor"),
                new("Vermelha e Branca","#C62828", "#FFFFFF", MesesMinimos: 120, Descricao: "Mestre"),
                new("Branca",           "#FFFFFF", "#FFFFFF", MesesMinimos: 180, Descricao: "Grão-Mestre"),
            ]),

        new("MMA",
            "Artes Marciais Mistas — sistema de graduação adaptado para academias.",
            [
                new("Branca",   "#FFFFFF", "#1A1A1A", Descricao: "Iniciante"),
                new("Amarela",  "#F9A825", "#1A1A1A", MesesMinimos: 6,   Descricao: "Básico"),
                new("Laranja",  "#E65100", "#1A1A1A", MesesMinimos: 12,  Descricao: "Intermediário"),
                new("Verde",    "#2E7D32", "#1A1A1A", MesesMinimos: 24,  Descricao: "Avançado"),
                new("Azul",     "#1565C0", "#1A1A1A", MesesMinimos: 36,  Descricao: "Lutador"),
                new("Preta",    "#212121", "#C62828", MesesMinimos: 60,  Descricao: "Elite"),
            ]),

        new("Wrestling",
            "Luta Olímpica / Wrestling — sistema de graduação adaptado para academias.",
            [
                new("Branca",   "#FFFFFF", "#1A1A1A", Descricao: "Iniciante"),
                new("Amarela",  "#F9A825", "#1A1A1A", MesesMinimos: 6),
                new("Verde",    "#2E7D32", "#1A1A1A", MesesMinimos: 18),
                new("Azul",     "#1565C0", "#1A1A1A", MesesMinimos: 30),
                new("Vermelha", "#C62828", "#1A1A1A", MesesMinimos: 48),
                new("Preta",    "#212121", "#C62828", MesesMinimos: 72),
            ]),
    ];

    // ─── Tipos auxiliares internos ────────────────────────────────────────────

    private record FaixaTemplate(
        string Nome,
        string Cor,
        string CorBarra = "#1A1A1A",
        bool TemGraus = false,
        int MaxGraus = 0,
        int MesesMinimos = 0,
        int PresencasMinimas = 0,
        string? Descricao = null);

    private record ModalidadeTemplate(
        string Nome,
        string? Descricao,
        FaixaTemplate[] Faixas);
}
