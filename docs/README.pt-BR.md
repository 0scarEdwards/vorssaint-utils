# Vorssaint

> O conjunto de utilitários gratuito e open source que substitui vários apps pagos do Mac.

*Read in [English](../README.md).*

<p align="center">🇺🇸 🇧🇷 🇪🇸 🇩🇪 🇫🇷 🇮🇹 🇯🇵 🇨🇳</p>
<p align="center"><sub>A interface fala 8 idiomas, troque quando quiser nos Ajustes.</sub></p>

Se o Vorssaint te ajuda, uma ⭐ rápida significa muito e ainda ajuda mais gente a encontrar o projeto. Ele é, e sempre será, 100% gratuito e sem assinatura; o apoio da comunidade é o que mantém tudo vivo, então se quiser ajudar você também pode [me pagar um café](https://buymeacoffee.com/vorssaint) ☕.

Um app pequeno na barra de menus que faz o trabalho para o qual você instalaria
(e pagaria) vários utilitários separados: manter o Mac acordado, ver o que está
deixando ele lento, ajustar o volume por app, alternar janelas, carregar arquivos
entre apps, remover sobras e resolver algumas chatices do dia a dia.

**Grátis. Open source. Local.** Sem conta, sem assinatura, sem telemetria.
Nada sai do seu Mac, exceto uma verificação de atualização que você pode
desligar. É feito com frameworks nativos do macOS, então fica pequeno e rápido.

**Instale com o [Homebrew](https://brew.sh):**

```sh
brew install --cask vorssaint/tap/vorssaint
```

Já tem o Vorssaint instalado? Adote a sua cópia no Homebrew sem reinstalar: `brew install --cask --adopt vorssaint/tap/vorssaint`. Você também pode [baixar o .dmg](https://github.com/vorssaint/vorssaint-utils/releases).

<p align="center">
  <img src="demo.gif" alt="O Vorssaint rodando pela barra de menus, com métricas ao vivo e o painel compacto por seções" width="780">
</p>

## O que ele faz

Os recursos podem ser ajustados pelos Ajustes ou direto pelo painel.

### 🌡️ Veja o que está deixando o Mac lento
Temperaturas de CPU, GPU e bateria, uso de CPU/GPU ao vivo, pressão de memória,
tempo ativo, saúde e ciclos da bateria, velocidade e totais de rede, consumo de
energia e gráficos históricos. Fixe CPU, GPU, RAM, Rede, Energia ou Bateria
direto na barra de menus.

### 🎚️ Ajuste o volume por app
Abaixe um app sem mexer no resto do Mac. O mixer por app que o macOS nunca
trouxe, com um ponto ao vivo no que está tocando. (macOS 14.4 ou mais recente.)

### 🪟 Vá para qualquer janela na hora
Substitui o ⌘Tab por uma grade com miniaturas reais das janelas, incluindo várias
janelas do mesmo app, e um toque rápido que volta para a última janela usada.

### ⚡ Mantenha o Mac acordado sob demanda
Para um download, um build ou uma apresentação: com tempo definido ou até você
desligar, mesmo com a tampa fechada. A proteção de bateria desliga quando a carga fica baixa.

### 📥 Carregue arquivos com a Shelf
Uma bandeja flutuante, chamada perto do cursor, que guarda arquivos, imagens,
textos e links para você arrastar entre apps, janelas e desktops. Solte vários
arquivos de uma vez para manter um lote, ou jogue itens soltos em uma pilha existente.

### 🧭 Mantenha o painel compacto
Alterne entre a lista completa e o painel por seções com um clique. As seções
ficam no topo, o painel cresce só o necessário para a seção ativa, e o Modo de
limpeza fica em Utilidades.

### 🧼 Limpe o teclado com segurança
O Modo de limpeza bloqueia o teclado para uma limpeza rápida, depois desbloqueia
pelo overlay, por uma sequência de tecla repetida ou automaticamente após um tempo curto.

### 🖱️ Corrija a direção da rolagem do mouse
Inverte a roda do mouse sem mexer na rolagem natural do trackpad.

### ✂️ Mova arquivos no Finder com ⌘X / ⌘V
Recorte arquivos e pastas e cole em outra pasta: o "mover" que falta no Finder.
Campos de texto seguem com os atalhos normais.

### ❌ Feche a última janela e o app encerra
Quando a última janela de um app fecha, ele é encerrado e libera a memória, com
uma lista de exceções para os apps que você prefere manter abertos.

### 🗑️ Remova um app e tudo que ele deixou para trás
Solte um app nos Ajustes para encontrar caches, preferências, logs e outros
resíduos, revise a lista e mande tudo para a Lixeira.

### 🧪 Fan Control beta
Uma entrada beta de Fan Control está disponível para teste. Os controles manuais
ficam desativados até que os modelos de Mac sejam validados com segurança.

## Por que é feito assim

- **Grátis e open source**, sob GPL-3.0-or-later. Sem níveis pagos.
- **Local por padrão.** Sem conta, sem login, sem telemetria. A única chamada de
  rede verifica se há nova versão no GitHub, e dá para desligar.
- **Nativo e leve.** SwiftUI + AppKit puro, sem dependências externas, um app
  pequeno no lugar de vários.
- **Opcional por princípio.** Os recursos podem ser ajustados ou desativados,
  pedem permissão só quando precisam e funcionam de forma degradada sem ela.

## Instalação

### Homebrew (recomendado)
```sh
brew install --cask vorssaint/tap/vorssaint
```
Já tem o Vorssaint instalado e não quer reinstalar? Adote a sua cópia no
Homebrew:
```sh
brew install --cask --adopt vorssaint/tap/vorssaint
```
Depois disso, as atualizações chegam por `brew upgrade --cask vorssaint`.

### Download
Baixe o DMG mais recente em [**Releases**](https://github.com/vorssaint/vorssaint-utils/releases),
abra e arraste o **Vorssaint** para **Aplicativos**.

O Vorssaint é assinado com um Developer ID e notarizado pela Apple, então abre
normalmente, sem aviso de segurança. A assinatura estável também mantém as
permissões concedidas entre as atualizações.

### Builds oficiais e forks
Builds oficiais do Vorssaint são distribuídos apenas pelo mantenedor do projeto.
Forks não oficiais devem usar outro nome, ícone, bundle identifier e identidade
de assinatura. A GPL cobre apenas o código-fonte e não concede permissão para
usar o nome Vorssaint, logo, ícone, identidade de bundle, trade dress ou
branding oficial. Veja [TRADEMARKS.md](../TRADEMARKS.md).

### Compilar do código
```sh
git clone https://github.com/vorssaint/vorssaint-utils.git
cd vorssaint-utils
./build.sh            # compila, gera o ícone e monta o bundle assinado
./build.sh --install  # idem, depois instala em /Aplicativos e abre
```

### Requisitos
- macOS 14 (Sonoma) ou mais recente
- Apple Silicon
- Xcode Command Line Tools (para compilar)

## Permissões

Tudo é opcional: os recursos funcionam de forma degradada e o onboarding guia
cada concessão.

| Permissão | Usada por | Sem ela |
|---|---|---|
| **Acessibilidade** | Inversor de rolagem, teclado do alternador, recortar e colar, encerrar ao fechar | Esses recursos ficam desligados |
| **Gravação de Tela** | Títulos e miniaturas no alternador | Alternador mostra só ícones |
| **Notificações** | Avisos de fim de sessão e proteção de bateria | Operação silenciosa |
| **Acesso Total ao Disco** (opcional) | Varredura mais completa do desinstalador | Varre só os locais acessíveis |
| **Administrador** (uma vez, opcional) | Tampa fechada sem senha | Pede senha a cada uso |

Recortar e colar e o desinstalador também pedem o consentimento de Automação na
primeira vez que falam com o Finder. A área temporária não precisa de nenhuma
permissão.

A primeira abertura traz um onboarding curto e guiado (idioma, permissões e uma
página opcional por recurso). Reveja quando quiser em **Ajustes › Sobre**.

## Desinstalação

```sh
./Tools/uninstall.sh   # de um clone, ou baixe do repositório
```
Encerra o app, remove o item de início, redefine as permissões de Acessibilidade
e Gravação de Tela, apaga o app, as preferências e o estado salvo, e remove a
regra `sudoers` opcional de tampa fechada, sem deixar nada para trás. Ou arraste
o app para a Lixeira e rode `tccutil reset All com.vorssaint.utils` para limpar
as permissões.

## Licença

O código-fonte é licenciado sob [GPL-3.0-or-later](../LICENSE), copyright
© 2026 Vorssaint. A licença cobre apenas o código-fonte. O branding do
Vorssaint é tratado separadamente em [TRADEMARKS.md](../TRADEMARKS.md).
