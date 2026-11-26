# Tutorial – Como rodar o script `medir.ps1`

Script de medição de memória, swap e responsividade no Windows. Cada execução mede uma condição (tipo de conteúdo + quantidade de abas) e grava uma linha em um arquivo CSV.

> Script gerado por IA (Claude Opus 5.5).

## 1. Pré-requisitos

- Windows 10 ou 11, com o PowerShell 5.1 (já vem instalado).
- O arquivo `medir.ps1` salvo em uma pasta fácil de achar, por exemplo `C:\TesteSO`.

## 2. Abrir o PowerShell na pasta do script

1. Abra a pasta `C:\TesteSO` no Explorador de Arquivos.
2. Clique com o botão direito num espaço vazio e escolha **"Abrir no Terminal"**.

## 3. Rodar uma medição

```powershell
powershell -ExecutionPolicy Bypass -File .\medir.ps1 -Conteudo inicial -Abas 0
```

O `-ExecutionPolicy Bypass` libera o script só nessa execução, sem mudar nenhuma configuração do Windows.

### Parâmetros

| Parâmetro | Valores aceitos | Obrigatório |
|---|---|---|
| `-Conteudo` | `inicial`, `wikipedia`, `video1080p` | Sim |
| `-Abas` | `0`, `10`, `25`, `50` | Sim |
| `-App` | `charmap` (padrão) ou `firefox` | Não |

A quantidade de RAM é detectada automaticamente.

## 4. O que acontece durante a execução

1. O script mostra a condição (conteúdo, abas, RAM e app) e pergunta **"Esta certo? (s/n)"**. Responda `s` para medir ou `n` para cancelar sem gravar nada.
2. Se essa condição já tiver sido gravada, aparece um aviso em vermelho.
3. Durante cerca de **1 minuto**, ele coleta o swap em uso, a RAM livre e as páginas por segundo. **Não mexa no computador nesse tempo.**
4. Ele abre e fecha o app de teste **3 vezes**, cronometrando quanto tempo a janela leva para aparecer.
5. No fim, mostra os resultados na tela e grava uma linha no CSV.

## 5. Onde ficam os resultados

Na mesma pasta do script, no arquivo `resultados_<RAM>GB.csv` (por exemplo, `resultados_8GB.csv`). Cada execução **acrescenta** uma linha ao final; nada é apagado, mesmo depois de reiniciar o computador.

O arquivo abre direto no Excel. **Feche o Excel antes de rodar o script de novo**: com o arquivo aberto, o script não consegue gravar e avisa na tela.

## 6. Sequência de testes sugerida

Para cada tipo de conteúdo:

1. Reinicie o computador e espere cerca de 5 minutos.
2. Rode com `-Abas 0`.
3. Abra 10 abas, clique em cada uma para carregar (e iniciar os vídeos), espere 2 minutos e rode com `-Abas 10`.
4. Complete 25 abas, espere e rode com `-Abas 25`.
5. Complete 50 abas, espere e rode com `-Abas 50`.

Exemplo da sequência de vídeo:

```powershell
powershell -ExecutionPolicy Bypass -File .\medir.ps1 -Conteudo video1080p -Abas 0
powershell -ExecutionPolicy Bypass -File .\medir.ps1 -Conteudo video1080p -Abas 10
powershell -ExecutionPolicy Bypass -File .\medir.ps1 -Conteudo video1080p -Abas 25
powershell -ExecutionPolicy Bypass -File .\medir.ps1 -Conteudo video1080p -Abas 50
```

## 7. Problemas comuns

| Problema | Solução |
|---|---|
| "Não é possível carregar o arquivo… scripts desabilitados" | Use o comando completo com `-ExecutionPolicy Bypass`. |
| "Não consegui gravar no CSV" | Feche o arquivo no Excel e rode de novo. |
| Valor de `-Abas` ou `-Conteudo` recusado | Use apenas os valores da tabela de parâmetros. |
| "Firefox não encontrado" (com `-App firefox`) | Instale o Firefox ou rode sem `-App` (usa o Mapa de Caracteres). |
| Vídeos não carregam nas abas | O navegador só carrega abas em segundo plano depois de você clicar nelas: passe por cada aba antes de medir. |
