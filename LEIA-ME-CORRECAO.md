# Projeto restaurado — 17/10/2026

## Abrir

1. Feche o Godot e pause a sincronizacao nos tres PCs.
2. Guarde uma copia das pastas antigas fora da pasta sincronizada.
3. Extraia este ZIP em uma pasta vazia. Nao sobreponha a pasta antiga: arquivos conflitantes que nao existem neste ZIP continuariam la.
4. Importe `novo-projeto-de-jogo/project.godot` pelo Godot 4.7. O projeto foi verificado com 4.7.2.
5. Aguarde a importacao dos recursos e pressione F5. O menu deve permanecer aberto sem personagem. PLAY deve mostrar a transicao azul e abrir a fase com um jogador, uma camera e um HUD.
6. Adote esta mesma base nos outros PCs antes de retomar a sincronizacao. O `.stignore` precisa existir em cada PC; o proprio Syncthing nao o sincroniza.

A/D ou setas movem o jogador; espaco pula; clique esquerdo ataca um inimigo proximo. Cima modifica o lancamento e cima + direcao lanca na diagonal.

## Correcoes

- Cena principal e autoload apontam para caminhos explicitos, sem depender do cache de UIDs de outro PC.
- `scene_transition.tscn` restaurada como CanvasLayer contendo somente o overlay, com `scene_transition.gd` e `pulse.gdshader` conectados.
- Transicao verifica se o destino existe, bloqueia chamadas repetidas e aguarda a cena nova entrar antes de revela-la.
- Encerramento pelo botao QUIT libera o playback de musica antes de fechar.
- Removida a troca automatica do menu para `cena_principal.tscn`, arquivo inexistente.
- `arbusto.tscn` reconstruido como sprite independente, usando a primeira regiao de 16 x 16 da imagem existente. Removidas a copia da fase e a instancia de si mesmo. A arte original completa foi preservada.
- Corrigida a selecao de outro inimigo que continua no alcance quando o alvo anterior sai.
- Numero flutuante de dano agora mostra o valor recebido, em vez do texto fixo 100.
- Retirados do pacote ativo os caches, temporarios, copias de conflito e ZIPs antigos. O ZIP original enviado permanece como referencia historica fora desta pasta de trabalho.
- Incluidas regras de exclusao de caches e temporarios no Git e no Syncthing.

## Escopo preservado

Cenario, chao, posicionamento inicial do jogador, camera, shaders de arte, musica, interface e valores de movimento/knockback foram preservados. A transicao e o arbusto precisaram ser reconstruidos porque seus arquivos tinham sido substituidos por copias da fase.

Este e o prototipo single-player existente. Vida, cura, morte, cooldown, vitoria e multiplayer nao foram adicionados: exigem decisoes de gameplay. Os botoes ocultos e o HUD ilustrativo continuam como estavam. O teste de retorno ao menu aciona a transicao internamente; nao foi criado um botao novo na fase.

## Trabalho em equipe

As exclusoes nao resolvem edicoes simultaneas do mesmo arquivo-fonte. Combinem quem edita cada cena e aguardem a sincronizacao antes de outra pessoa abri-la. Nao recuperem os arquivos `sync-conflict` por cima desta base sem comparar o conteudo.

## Validacao

Godot 4.7.2 em modo headless: importacao, abertura do menu, PLAY repetido, tres ciclos entre menu e fase, contagem de jogadores/cameras/HUD, movimento, colisao com chao, pulo, limpeza da poeira, knockback, numero e limpeza do dano, troca de alvo com dois inimigos e lancamentos vertical/diagonal.

Os testes sao de carregamento e comportamento. Nao constituem revisao visual, de audio em dispositivo real ou de sincronizacao nos tres PCs.
