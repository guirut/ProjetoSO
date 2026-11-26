# Teste de Consumo de energia – Ambiente e Metodologia
 
## 1. Computadores utilizados
 
| | PC 1 | PC 2 |
|---|---|---|
| **Processador** | AMD Ryzen 5 5600x | Intel(r) Core(TM) Ultra 7 268V |
| **Sistema operacional** | Windows 11 | Windows 11 |
| **Memória RAM** | 16 GB | 32 GB |
| **Armazenamento** | 418 SSD + 1T HD | 478G SSD |
| **Placa de vídeo** | Nvidia RTX 5060 | Integrada Intel(R) Arc(TM) 140V GPU (16GB)|
| **Placa-mãe** | Asus b550m plus | - |
| **Fonte** | Corsair 750W bronze | - |
| **Navegador usado nos testes** | Google Chrome | Google Chrome |
 
 
## 2. O que foi medido
 
A hipótese testada é que, ao abrir muitas abas com conteúdo pesado, o consumo de energia do sistema, em destaque da GPU por processar os vídeos 4K e 1080P, teria grandes aumentos de consumo de energia (W).
 
Foram testados três tipos de conteúdo nas abas:
 
| Conteúdo | Descrição |
|---|---|
| 10 abas | Videos 4k 1080P |
| 25 abas | Videos 4k 1080P |
| 50 abas | Videos 4k 1080P |

 
## 3. Como foi medido
 
- **Ponto de partida:** medido 5 minutos depois de o sistema inicializar, encerrando quaisquer programas secundários que possam afetar a medição.
- **Repetições:** A média de 3 testes.
- **Procedimento:** Inicia o Chrome, inicia o PowerShell, abre a quantidade de abas usadas no experimento, insere o comando de medição no terminal e deixa ele rodar por 30 segundos.
- **Responsividade:** tempo para abrir um aplicativo (FireFox), medido com **cronômetro de relógio**. Por ser uma medição manual, está sujeita a alguns milissegundos a mais, por causa do tempo de reação de quem aperta o cronômetro.
-  **Limite atingido:** próximo das 50 abas, ambos os sistema apresentavam falhas bruscas além do navegador de forma automática abaixar a qualidade dos vídeos das abas acessadas a mais tempo

## 4. Script de medição (Windows)

**PC 1**
```powershell
nvidia-smi --query-gpu=power.draw,temperature.gpu,timestamp --format=csv -l 1 -f "caminho"
```
**PC 2**
Através de observação no programa HWMonitor.
### O que o script faz
 
Durante 30 segundos ele registra em um arquivo .csv as informações da GPU a cada segundo de:
- Quantidade de energia consumida (Watts);
- Temperatura da GPU;
- Horário de gravação.
  
### Conclusões sobre as métricas
A hipótese foi comprovada em parte, de fato existe um aumento considerável de consumo de energia conforme aumentamos o número de abas. Porém, o crescimento especulado era bem maior, vale ressaltar as observações em relação as limitações. O próprio SO começou a encerrar processos em segundo plano e o navegador passou a diminuir a qualidade dos vídeos das abas abertas a mais tempo para manter integridade durante o ápice do processamento (50 abas abertas).

###Observação:

Para medição do dispositivo do parceiro (PC 2) foi necessária a instalação de um programa a parte chamado HWMonitor. Dessa forma conseguimos fazer as medições.
 
