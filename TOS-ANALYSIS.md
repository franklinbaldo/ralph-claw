# Analise: ralph-claw vs. Termos de Servico da Anthropic

> **Aviso:** Esta analise nao constitui aconselhamento juridico. Consulte os termos vigentes nos links fornecidos e um profissional juridico se necessario.

> **Data da analise:** 2 de marco de 2026

---

## 1. O que e o ralph-claw?

Um orquestrador que roda o Claude Code (ou outro CLI de IA) em **loop automatizado infinito** dentro de um container Docker:

```bash
while true; do
  claude --dangerously-skip-permissions -p "$(cat AGENT.md)"
  git add -A && git commit -m "checkpoint"
  sleep 10
done
```

**Componentes relevantes para a analise:**
- `loop.sh` — Script bash que automatiza execucoes do Claude Code em loop
- `docker-compose.yml` — Usa imagem oficial `ghcr.io/anthropics/claude-code:latest`
- Flag `--dangerously-skip-permissions` — Remove todas as confirmacoes interativas
- `ANTHROPIC_API_KEY` — Metodo de autenticacao configurado no `.env`

---

## 2. Termos Aplicaveis da Anthropic

A Anthropic possui dois conjuntos distintos de termos, dependendo do metodo de autenticacao:

| Metodo | Termos Aplicaveis | Produtos |
|---|---|---|
| **API Key** (Console) | [Commercial Terms](https://www.anthropic.com/legal/commercial-terms) | API paga por token |
| **OAuth** (Login) | [Consumer Terms](https://www.anthropic.com/legal/consumer-terms) | Free, Pro ($20/mes), Max ($100-200/mes) |

**Ambos** estao sujeitos a [Acceptable Use Policy (AUP)](https://www.anthropic.com/legal/aup).

---

## 3. Analise por Cenario de Autenticacao

### Cenario A: Uso com API Key (Termos Comerciais)

Se o usuario usar uma **API Key** do Console da Anthropic (pay-as-you-go):

| Clausula | Viola? | Justificativa |
|---|---|---|
| Nao criar produtos concorrentes | **NAO** | ralph-claw nao compete com a Anthropic; orquestra seus servicos |
| Nao revender servicos | **NAO** | Usa chave propria do usuario, nao redistribui acesso a terceiros |
| Nao fazer engenharia reversa | **NAO** | Usa o CLI oficial via interface publica documentada |
| Nao treinar modelos com outputs | **NAO** | Nao ha evidencia de treinamento de modelos |
| Acceptable Use Policy | **NAO** | Gera codigo, nao conteudo proibido |

**Conclusao:** RISCO BAIXO. API Keys sao projetadas para uso programatico e automatizado. O usuario paga por token consumido, entao nao ha arbitragem economica. A automacao via scripts e o uso esperado da API.

---

### Cenario B: Uso com Assinatura Consumer (Free, Pro, Max) — CRITICO

Se o usuario usar uma **assinatura consumer** (login OAuth no Claude Code):

| Clausula TOS | Viola? | Justificativa |
|---|---|---|
| **Acesso Automatizado** (Sec. 3) | **SIM** | `loop.sh` e um script que automatiza o acesso |
| **Uso Ordinario Individual** | **SIM** | Loop infinito 24/7 nao e uso ordinario |
| **OAuth Restrito** | **ZONA CINZA** | Usa Claude Code oficial, mas wrapper pode ser "outro servico" |
| **Produtos concorrentes** | **POSSIVEL** | Poderia ser interpretado como competidor dos servicos da Anthropic |
| **Acceptable Use Policy** | **NAO** | Gera codigo, nao conteudo proibido |

**Conclusao:** RISCO ALTO. Viola pelo menos 2 clausulas claramente.

---

## 4. Detalhamento das Violacoes (Cenario Consumer)

### 4.1 VIOLACAO CLARA: Acesso Automatizado por Script

**Clausula dos Consumer Terms, Secao 3:**
> "You will not [...] access the Services through automated or non-human means, whether through a bot, script, or otherwise"

**Evidencia no codigo (`loop.sh:31-89`):**
- Loop `while true` infinito (linha 31)
- Sem intervencao humana entre iteracoes
- Flag `--dangerously-skip-permissions` remove todas as confirmacoes (linha 51-53)
- `MAX_LOOPS=0` significa rodar para sempre (linha 13)
- Sleep de apenas 5 segundos entre loops (linha 14)

O `loop.sh` e, por definicao, um **script que automatiza o acesso** ao Claude Code. Mesmo que o Claude Code em si seja o CLI oficial, o wrapper automatizado viola a clausula de acesso nao-humano.

### 4.2 VIOLACAO PROVAVEL: Excede Uso Ordinario Individual

**Clausula (Legal and Compliance Docs):**
> "Advertised usage limits for Pro and Max plans assume ordinary, individual usage of Claude Code and the Agent SDK"

**Evidencia:**
- Projetado para rodar continuamente (24/7)
- Nenhum humano precisa estar presente durante a execucao
- Consumo pode ser ordens de magnitude maior que uso manual individual
- O proprio README descreve o sistema como "persistente" e "autonomo"

### 4.3 ZONA CINZA: OAuth Token em Wrapper Automatizado

**Clausula (Legal and Compliance Docs, atualizada Fev 2026):**
> "Using OAuth tokens obtained through Claude Free, Pro, or Max accounts in any other product, tool, or service — including the Agent SDK — is not permitted"

**Analise:** ralph-claw executa o binario `claude` oficial, nao faz spoofing de tokens OAuth. Porem:
- A Anthropic pode interpretar o wrapper como "outro servico"
- Em Jan/Fev 2026, a Anthropic bloqueou ferramentas similares (OpenCode, etc.)
- O padrao de uso (loop infinito automatizado) e indistinguivel dos harnesses que foram banidos

### 4.4 RISCO ECONOMICO: Arbitragem de Tokens

**Contexto:** A Anthropic bloqueou ativamente ferramentas de terceiros em Jan 2026 por causa de "arbitragem de assinatura" — onde usuarios pagavam $20-200/mes em assinaturas para volumes que custariam $1.000+/mes via API.

ralph-claw facilita exatamente este padrao:
- Assinatura Max: $200/mes com uso "ilimitado"
- Mesmo volume via API: potencialmente $1.000+/mes
- Diferenca: 5-10x mais barato via assinatura + automacao

---

## 5. Precedentes de Enforcement (Jan-Fev 2026)

A Anthropic tomou acoes concretas contra padroes similares:

1. **OpenCode** — Removeu suporte a contas Claude apos "solicitacao legal da Anthropic" (Fev 2026)
2. **Windsurf** — Teve acesso cortado sem aviso previo (Jun 2025)
3. **Contas individuais** — Relatos de banimentos por padrao de uso automatizado

A Anthropic identifica automacao por "padroes de trafego incomuns" e falta de telemetria dos wrappers.

---

## 6. Resumo

| Metodo de Auth | Risco | Violacao | Recomendacao |
|---|---|---|---|
| **API Key (Comercial)** | BAIXO | Provavelmente nenhuma | Uso seguro |
| **OAuth Free** | **ALTO** | Acesso automatizado + uso nao-ordinario | **NAO usar** |
| **OAuth Pro ($20/mes)** | **ALTO** | Acesso automatizado + uso nao-ordinario | **NAO usar** |
| **OAuth Max ($100-200/mes)** | **ALTO** | Acesso automatizado + uso nao-ordinario | **NAO usar** |

---

## 7. Recomendacoes

1. **Usar SOMENTE com API Key** — Nunca com assinaturas consumer (Free/Pro/Max)
2. **Documentar esta restricao** — Aviso claro no README e na documentacao
3. **Monitorar mudancas nos TOS** — A Anthropic atualiza termos periodicamente
4. **Considerar rate limiting** — Mesmo com API Key, adicionar intervalos razoaveis entre loops
5. **Nao encorajar arbitragem** — Evitar linguagem que sugira economia vs. API

---

## 8. Fontes

- [Anthropic Consumer Terms of Service](https://www.anthropic.com/legal/consumer-terms)
- [Anthropic Commercial Terms](https://www.anthropic.com/legal/commercial-terms)
- [Anthropic Acceptable Use Policy](https://www.anthropic.com/legal/aup)
- [Claude Code Legal and Compliance](https://docs.anthropic.com/en/docs/claude-code/legal-compliance)
- [Anthropic clarifies ban on third-party tool access — The Register (Fev 2026)](https://www.theregister.com/2026/02/20/anthropic_clarifies_ban_third_party_claude_access/)
- [Anthropic blocks third-party use of Claude Code subscriptions — Hacker News](https://news.ycombinator.com/item?id=46549823)
