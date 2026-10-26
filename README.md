# Cartola Champions — Flutter + Supabase

## Instalação

1. Crie um projeto no Supabase, abra **SQL Editor** e execute `supabase/schema.sql`.
2. Em **Authentication > Providers**, habilite Email (confirmação por e-mail pode ser exigida).
3. No terminal, **dentro desta pasta**:

```bash
flutter create . --project-name cartola_champions_flutter --platforms=android,web
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co --dart-define=SUPABASE_ANON_KEY=SUA_CHAVE_PUBLICA
```

A URL e a chave pública/anon estão em Supabase > Project Settings > API. **Nunca coloque a chave service_role no aplicativo.**

## Funcionalidades

- Cadastro/login por e-mail via Supabase Auth.
- Time salvo por usuário na tabela `fantasy_teams`.
- Ligas compartilhadas, criação e entrada por código.
- Classificação da liga calculada a partir das escalações congeladas e pontuações cadastradas no servidor.
- Rodadas e partidas exibidas da tabela `fantasy_fixtures`.

## O que ainda precisa para produção

O catálogo de jogadores e preços é **demonstrativo**. A pontuação real **não é automática**: é necessário contratar/configurar uma API de futebol com licença para estatísticas de jogadores da UEFA Champions League, importar jogos, jogadores e scouts por backend (Edge Function/cron) e gerar `fantasy_player_scores` de acordo com regras oficiais definidas por você. A tabela `fantasy_round_lineups` foi criada para congelar escalações por rodada; falta conectar a ação de fechamento/escalação do app a essa tabela e impedir alterações após o prazo. Sem isso, o ranking fica zerado. Não atribua pontos com dados inventados.

**Atenção:** `fantasy_teams` mantém o elenco atual. A pontuação histórica só deve usar `fantasy_round_lineups`, nunca o elenco atual. Para um jogo público, valide orçamento, posições e prazo de escalação também no backend; regras apenas no Flutter podem ser burladas.
