# Teste de Uso de Memória e Swap – Ambiente e Metodologia
 
## 1. Computadores utilizados
 
| | PC 1 | PC 2 |
|---|---|---|
| **Modelo / Processador** | MacBook Neo | AMD Ryzen 7 5700X |
| **Sistema operacional** | macOS 27.2.1 | Windows 11 |
| **Memória RAM** | 8 GB | 16 GB e 8 GB (dois cenários de teste) |
| **Armazenamento** | 512 GB | SSD Kingston NV3 1 TB NVMe Gen 4 + HD Seagate BarraCuda 2 TB SATA (interno) |
| **Placa de vídeo** | Integrada | AMD Radeon RX 6600 8 GB VRAM (ASRock) |
| **Placa-mãe** | – | Gigabyte B550M Aorus Elite |
| **Fonte** | – | Deepcool 600 W, 80 Plus Bronze |
| **Navegador usado nos testes** | Google Chrome | Google Chrome |
 
> No PC 2, o cenário de 8 GB foi obtido **removendo fisicamente um dos pentes de memória**. Assim, o sistema passou a ter de fato 8 GB instalados, uma condição mais fiel do que limitar a memória por software.
 
## 2. O que foi medido
 
A hipótese testada é que, ao abrir muitas abas com conteúdo pesado, a RAM se esgota, o sistema passa a usar swap (memória no disco) e a responsividade cai, porque o disco é muito mais lento que a RAM.
 
Foram testados três tipos de conteúdo nas abas:
 
| Conteúdo | Descrição |
|---|---|
| **Página inicial** | Página inicial do Google (conteúdo leve) |
| **Wikipédia** | Artigos da Wikipédia (texto e imagens) |
| **Vídeo 1080p** | Vídeos em 1080p reproduzindo (conteúdo pesado) |
 
E quatro quantidades de abas: **0** (ponto de partida), **10**, **25** e **50**.

>Referência vídeo: https://www.youtube.com/watch?v=y6N8u4OGgXk&t=1646s
> Referência Wikipedia: https://en.wikipedia.org/wiki/Operating_system
 
## 3. Como foi medido
 
### PC 1 – macOS
 
- **Memória e swap:** valores lidos no Monitor de Atividade (aba Memória): *Memória usada*, *Arquivos em cache* e *Troca (swap) usada*.
- **Ponto de partida:** medido 5 minutos depois de o sistema inicializar, sem abas abertas.
- **Repetições:** página inicial e vídeo 1080p são a média de 3 testes. Wikipédia: valores médios de 3 testes.
- **Responsividade:** tempo para abrir um aplicativo (FireFox), medido com **cronômetro de relógio**. Por ser uma medição manual, está sujeita a alguns milissegundos a mais, por causa do tempo de reação de quem aperta o cronômetro.
### PC 2 – Windows
 
- **Memória, swap e responsividade:** coletados automaticamente pelo script `medir.ps1` (seção 4).
- **Procedimento de cada sequência:**
  1. Reiniciar o computador e aguardar cerca de 5 minutos.
  2. Rodar o script com 0 abas (ponto de partida).
  3. Abrir 10 abas, aguardar a estabilização e rodar o script.
  4. Completar 25 abas e rodar o script; depois 50 abas e rodar o script.
  5. Reiniciar antes de trocar o tipo de conteúdo.
- **Repetições:** 1 medição por condição.
- **Cenários de RAM:** a sequência completa foi feita com 16 GB e depois com 8 GB.
- **Limite atingido:** com 8 GB e vídeos em 1080p, o sistema **não suportou mais de 38 abas**. Essa foi a última medição desse cenário.
## 4. Script de medição (Windows)
 
O script `medir.ps1` foi **gerado por IA (Claude Opus 5.5)** e executado no PowerShell 5.1:
 
```powershell
powershell -ExecutionPolicy Bypass -File .\medir.ps1 -Conteudo video1080p -Abas 25
```
 
### O que o script faz
 
1. **Confere os dados antes de medir:** mostra o conteúdo, o número de abas e a RAM detectada, e pede confirmação. Avisa se aquela condição já foi gravada, para evitar repetir uma medição por engano.
2. **Coleta a memória durante cerca de 60 segundos** (uma amostra por segundo), usando contadores do próprio Windows:
   | Métrica | Fonte no Windows | Significado |
   |---|---|---|
   | Swap em uso | `Win32_PageFileUsage` → `CurrentUsage` | Quanto do arquivo de paginação (o swap do Windows) está ocupado |
   | RAM livre | `Win32_OperatingSystem` → `FreePhysicalMemory` | Memória física sem uso |
   | Páginas por segundo | `Win32_PerfFormattedData_PerfOS_Memory` → `PagesPersec` | Páginas lidas do disco ou gravadas nele por segundo (atividade de paginação) |
3. **Mede a responsividade:** abre o **Mapa de Caracteres** (`charmap.exe`) 3 vezes e cronometra, com o relógio interno do sistema, o tempo até a janela aparecer. O app é fechado depois de cada abertura.
4. **Grava uma linha no CSV** (`resultados_<RAM>GB.csv`), sempre acrescentando ao final do arquivo, com as colunas:
   | Coluna | Conteúdo |
   |---|---|
   | `DataHora` | Momento da medição |
   | `Conteudo` | Tipo de conteúdo das abas |
   | `Abas` | Número de abas abertas |
   | `RAM_GB` | RAM visível ao Windows |
   | `SwapMedio_GB` | Média do swap em uso durante a coleta |
   | `SwapMax_MB` | Maior valor de swap durante a coleta |
   | `RAMLivreMedia_MB` | Média da RAM livre |
   | `PaginasPorSeg_Media` | Média de páginas por segundo |
   | `AbrirApp1_s` a `AbrirApp3_s` | Tempo de cada uma das 3 aberturas do app |
   | `AbrirAppMedia_s` | Média das 3 aberturas (métrica de responsividade) |
### Observações sobre as métricas
 
- **Swap no Windows e no macOS:** o arquivo de paginação do Windows e o swap do macOS cumprem a mesma função, mas cada sistema decide de forma diferente quando usá-los. Os valores servem para comparar tendências, não para uma comparação exata entre os sistemas.
- **Páginas por segundo:** o contador inclui leitura de arquivos comuns, não só o swap. Picos isolados com pouca memória ocupada não indicam falta de RAM. O valor só indica pressão de memória quando sobe junto com o swap e a RAM livre cai.
- **Primeira abertura do app:** costuma ser mais lenta, porque o programa ainda não está na memória. Por isso as 3 aberturas são registradas separadamente.

## 5 Limitações
 
- A responsividade foi medida de formas diferentes nos dois sistemas: cronômetro manual no macOS e cronometragem automática no Windows.
- O PC 2 com 8 GB não chegou a 50 abas de vídeo (parou em 38), então essa condição não tem comparação direta com 50 abas.
 
