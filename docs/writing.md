# Écrire et ajouter du contenu

## Un billet, du brouillon à la publication

```sh
./site new "Conditional expectation"
./site preview
```

Ouvre `content/_drafts/conditional-expectation.md`. Les quelques lignes entre les
séparateurs `---` décrivent le billet ; le reste est ton texte en Markdown.
Le titre et la description doivent être en anglais, comme le site.

```yaml
---
title: "Conditional expectation"
date: '2026-09-05'
slug: conditional-expectation
published: false
description: "A geometric view of conditional expectation."
topic: Probability
cover: /images/posts/conditional-expectation/cover.jpg
---
```

- `title` : titre affiché.
- `description` : courte présentation sur la vignette et dans les métadonnées.
- `slug` : nom court utilisé dans l’adresse. Garde-le stable après publication.
- `published: false` : brouillon. La commande `publish` le passe à `true`.
- `topic` et `cover` : facultatifs ; le site fournit des valeurs par défaut.

Dépose une image dans le dossier indiqué par `new`, puis décommente la ligne
`cover:`. Une image paysage convient aux cartes ; `cover_fit: contain` permet de
montrer une figure scientifique entièrement, sans la recadrer.

Sans image, la vignette est typographique. Tu peux ajouter :

```yaml
formula: "E[X | Y]"
cover_label: Conditional expectation
```

`formula` est du texte Unicode, pas du LaTeX. Le corps de l’article accepte les
formules LaTeX avec `$...$` et les équations centrées avec `$$...$$` sur des lignes
séparées. MathJax est chargé depuis jsDelivr sur les articles scientifiques.

Pour préparer la publication :

```sh
./site publish conditional-expectation
./site check
```

Le fichier devient `content/_posts/AAAA-MM-JJ-conditional-expectation.md` et son
adresse `/blog/AAAA/MM/JJ/conditional-expectation/`. Il apparaît automatiquement
dans Notebook, parmi les derniers textes sur l’accueil, et dans le flux RSS.

`./site publish conditional-expectation --date 2026-10-12` choisit une autre date.
Une date future reste cachée dans la version publique jusqu’à une compilation
après cette date. Il n’y a pas de publication programmée automatique.
L’aperçu ordinaire n’affiche pas non plus les dates futures.

Pour revenir au brouillon avant mise en ligne, remets `published: false` dans le
fichier. Pour le rendre de nouveau publiable, remets `true` ; `publish` refuse de
redater un fichier déjà classé dans `_posts/`.

## Projets et publications

```sh
./site new "My project" --type project
./site new "My paper" --type publication
```

Les fichiers se trouvent directement dans `content/_projects/` ou
`content/_publications/`, avec `published: false`. Ils restent absents de la
version publique jusqu’à `./site publish my-project` ou `./site publish my-paper`.
Leur adresse explicite (`permalink`) reste stable, même si le fichier est renommé.

Un projet apparaît dans Projects et Notebook. Une publication apparaît dans
Research, Publications et la liste du CV. Le RSS contient les billets du blog.
Les métadonnées des publications sont `authors`, `venue`, `category`, `paperurl`,
et éventuellement `bibtexurl` ou `projecturl`. `category` accepte `preprints`,
`conferences` et `manuscripts`.

`publish` accepte aussi le chemin complet depuis le dossier du site. C’est utile
si un billet et un projet ont le même slug :

```sh
./site publish content/_projects/my-project.md
```

Les textes existants gardent leurs adresses historiques ; ne supprime pas leurs
champs `permalink` ou `redirect_from`.

## Images et vidéos dans un article

Les fichiers se rangent dans le dossier d’images créé avec le contenu. Dans le
texte, utilise un chemin commençant par `/images/` :

```markdown
![A description of the figure]({{ '/images/posts/conditional-expectation/figure.png' | relative_url }})
```

Pour une vidéo, ce bloc donne un lecteur avec commandes et une légende :

```html
<figure>
  <video controls playsinline preload="metadata" poster="{{ '/images/posts/conditional-expectation/poster.jpg' | relative_url }}">
    <source src="{{ '/images/posts/conditional-expectation/demo.mp4' | relative_url }}" type="video/mp4">
    <a href="{{ '/images/posts/conditional-expectation/demo.mp4' | relative_url }}">Download the video</a>
  </video>
  <figcaption>Explain what the simulation shows.</figcaption>
</figure>
```

`poster` est facultatif. Les trois vidéos des projets MVA restent en place ; leurs
articles donnent des exemples complets de figures, équations et lecteurs vidéo.

## Photos de montagne

```sh
./site photo "/chemin/photo.jpg" --title "Aiguille du Midi" --location "Mont Blanc massif" --alt "Snow-covered ridge above the valley" --date 2026-08-20
```

La commande copie le fichier dans `images/mountains/` et ajoute sa légende à
`settings/photos.yml`. L’original est conservé. La galerie remplace son illustration
dès la première photo. JPG, PNG, WebP et AVIF sont acceptés ; les images ne sont
pas redimensionnées ni compressées par la commande.

Modifie ensuite `settings/photos.yml` pour corriger une légende ou changer l’ordre
(liste du haut vers le bas). Pour retirer une photo de la galerie, enlève son bloc.
`width` et `height`, quand ils sont renseignés, doivent correspondre aux dimensions
réelles ; ils sont facultatifs.

Choisis des photos exportées pour le Web, idéalement de 1600 à 2400 pixels de
large. L’illustration actuelle est de
[Niklas Liniger sur Unsplash](https://unsplash.com/photos/glacier-mountains-during-day-BZpt3Qn09WQ),
sous [licence Unsplash](https://unsplash.com/license), et porte son crédit visible.

## Vérifier et mettre en ligne

1. Relis le contenu avec `./site preview`, puis arrête cet aperçu avec `Ctrl+C`.
2. Prépare les textes avec `./site publish leur-slug`.
3. Lance `./site check`. Il vérifie les fichiers et liens locaux ; il ne valide
   pas les résultats mathématiques ni la disponibilité des liens externes.
4. Enregistre les changements dans Git et intègre-les dans la branche utilisée
   par GitHub Pages pour déclencher le déploiement habituel.

Cette proposition reste sur `codex/personal-site-redesign`. Les commandes
`./site` ne créent pas de commit, ne poussent pas la branche et ne changent pas
la configuration de GitHub Pages.

Si le port 4000 est occupé, arrête l’ancien aperçu ou utilise
`./site preview --port 4001`. Relance l’aperçu après une modification de `_config.yml`.
