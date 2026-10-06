# Publicação das imagens de Atendimento

## Correções

- Os cinco slots de Atendimento passam de 1200 × 800 para 1024 × 1536. O processador já usa as dimensões do slot: novos uploads verticais deixam de sofrer corte horizontal.
- A prévia do painel mostra o recorte sempre que a proporção diverge, inclusive quando apenas uma dimensão excede a recomendação.
- Atendimento reconcilia o manifesto com o backend ao entrar, mesmo quando a versão global já foi atualizada por outra tela.
- A imagem selecionada aparece sem aguardar o download de todos os cards para cache offline.
- A sincronização consulta a versão a cada 30 segundos enquanto há telas ouvindo e o app está em primeiro plano, além do WebSocket. Ao retomar o app, força a reconciliação.
- Mudanças de ambiente notificam as telas mesmo quando a versão daquele ambiente já estava salva. A chave visual inclui a URL.

## Aplicação e reteste

1. Atualizar o backend e o Web da branch feature/20261005-web-layout-managed-heroes.
2. Confirmar que o painel recomenda 1024 × 1536 para Atendimento.
3. Enviar novamente o arquivo original devolucao.webp. Reutilizar a imagem antiga do histórico conserva o arquivo já recortado; a alteração não regenera automaticamente uploads passados.
4. Atualizar o mobile local. Comparar API_BASE_URL e o ambiente retornado por /private/api/assets/version entre mobile e Web. Rodar local não significa necessariamente usar backend DEV: a URL padrão do app é a API remota.
5. Conferir a mesma empresa/perfil. Imagens de empresa e segmento/especialidade têm prioridade sobre o padrão global. A tag MOBILE identifica o destino visual; LIVE/DEV identifica o ambiente dos assets.
6. Publicar e conferir atualização por WebSocket ou pela consulta de recuperação. Logs [AtendimentoMobile] incluem ambiente, versão, slot e ID selecionado para distinguir seleção de cache.
7. Conferir os rostos e o objeto da cena nos cards, abrir outra tela e voltar, suspender/retomar e trocar empresa.

## Limites da verificação

Os prints comprovam o corte horizontal e o novo registro ativo no painel, mas não mostram a URL/ambiente do backend local nem a resposta do manifesto recebido pelo mobile. Não houve acesso ao banco nem deploy. Flutter/JDK não estão disponíveis nesta sessão; builds e testes de dispositivo precisam ser executados no ambiente local.
