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

`formula` est du texte Unicode, pas du LaTeX. Dans le corps de l’article, utilise
`$$...$$` pour les formules en ligne : `The mean is $$\mathbb{E}[X]$$.`
Pour centrer une équation, place les deux `$$` seuls sur leurs lignes, avec une
ligne vide avant et après le bloc :

```latex
$$
\mathbb{E}[X] = \int x\,dP(x).
$$
```

Cette syntaxe permet à Jekyll de préserver le LaTeX avant de traiter le Markdown.
Dans les formules en ligne, écris `\lvert x\rvert` pour une valeur absolue,
`\lVert x\rVert` pour une norme et `\mid` pour une barre de conditionnement :
les caractères `|` bruts peuvent être pris pour un tableau Markdown.
Pour une légende avec des maths, utilise
`<figcaption markdown="span">At $$t=0$$.</figcaption>`.
MathJax est chargé depuis jsDelivr sur les articles scientifiques.

Pour préparer la publication :

```sh
./site publish conditional-expectation
./site check
```

Le fichier devient `content/_posts/AAAA-MM-JJ-conditional-expectation.md` et son
adresse `/blog/AAAA/MM/JJ/conditional-expectation/`. Il apparaît automatiquement
dans Blog, parmi les derniers textes sur l’accueil, et dans le flux RSS.

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

Un projet apparaît dans Blog, avec les autres articles. Une publication apparaît dans
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

## Photos : trois rubriques thématiques

La page **Photos** présente **Cities**, **Mountains** et **Sunsets**. Une photo
peut appartenir à plusieurs rubriques sans dupliquer son fichier. Son lieu et
sa date de prise de vue sont indiqués dans sa légende ; le filtre **Place**
permet de n’afficher qu’un lieu dans la rubrique consultée.

Les vignettes carrées forment des rangées alignées. Leur recadrage est uniquement
visuel : un clic ouvre la photo entière. Les anciennes adresses des albums de
voyage redirigent vers la rubrique correspondante. L’ancien album mixte
France & England et l’adresse `/mountains/` redirigent vers `/photos/`.

### Trier les photos dans PHOTO

`PHOTO/` est le dossier des nouvelles photos à examiner et des images non
retenues. Il peut contenir des RAW ou des JPEG pleine résolution ; il reste
exclu de Git et de la construction du site. Il ne sert pas d’archive permanente.
Les versions sélectionnées et exportées pour le Web vont dans `images/photos/`.
Après avoir vérifié une photo ajoutée dans l’aperçu, range sa source en dehors
de `PHOTO/` pour n’y laisser que les images inutilisées ou encore à trier.
Pour cette sélection, le dossier de destination des sources utilisées est
`local/photo-originals-used-2026-09-06/`. Les copies Web retirées de la galerie
ont leur dossier distinct, `local/removed-photo-assets-2026-09-06/`.
Ces dossiers restent locaux, exclus de Git et du site ; ce rangement conserve
les fichiers sans les supprimer.
La commande `./site check` signale si des fichiers de `PHOTO/` se retrouvent
par erreur dans le site généré.

Pour les exports, privilégie le JPEG en sRGB, de 1600 à 2400 pixels sur le grand
côté. JPG, PNG, WebP et AVIF sont acceptés. La commande `photo` copie le fichier
sans le redimensionner ni le compresser ; elle conserve ton fichier source et
ne range pas `PHOTO/` automatiquement.

### Ajouter une photo à une ou plusieurs rubriques

```sh
./site photo "/chemin/seine.jpg" --title "The Seine" --alt "Evening light on the Seine" --location "Paris, France" --date 2026-06-13 --album cities --album sunsets
./site photo "/chemin/sommet.jpg" --title "Mountain summit" --alt "A rocky summit above a grassy slope" --location "Queyras, France" --date 2026-08-14 --album mountains
```

`photo` copie chaque image une seule fois dans `images/photos/` et ajoute son
bloc à `settings/photos.yml`. La première commande enregistre
`albums: [cities, sunsets]` ; la seconde, `albums: [mountains]`. Toutes les
rubriques indiquées doivent déjà exister dans `content/_albums/`.

Tu peux remplacer `--album cities --album sunsets` par
`--albums cities,sunsets`. Renseigne le lieu avec `--location` et la date de
prise de vue avec `--date` : les rubriques thématiques n’ont pas de lieu ou de
date communs à transmettre. Sans `--date`, la commande utilise le jour de
l’ajout. Garde la même orthographe pour un même lieu afin que ses photos soient
regroupées sous une seule option du filtre **Place**.

### Créer une rubrique

Pour ajouter un nouveau thème :

```sh
./site album "Architecture" --slug architecture
```

La commande crée `content/_albums/architecture.md` et l’adresse
`/photos/architecture/`. Aucun lieu ni aucune date ne sont obligatoires.
Le `slug` sert à rattacher les photos avec `--album architecture` ; garde-le
stable après mise en ligne. Les options historiques `--location`, `--date`,
`--end-date` et `--category` restent acceptées, mais ne sont pas nécessaires
pour les rubriques thématiques.

### Modifier la présentation et la couverture

Ouvre le fichier de la rubrique. Il ressemble à ceci :

```yaml
---
layout: photo_album
nav: photos
title: Cities
show_dates: false
cover: /images/photos/2026-06-13-the-seine.jpg
cover_alt: Evening light on the Seine
---

Streets and buildings.
```

La commande laisse `cover` vide pour te permettre de choisir. Copie dans ce
champ la valeur `image` de la photo choisie dans `settings/photos.yml`, puis
renseigne `cover_alt`. Les titres, légendes et descriptions visibles restent en
anglais. Le texte Markdown après le second `---` sert de présentation facultative.
`show_dates: false` masque la période de la rubrique ; les dates des photos
restent affichées. Une rubrique est publiable dès sa création ; elle n’utilise
pas `./site publish`.

### Corriger les légendes, l’ordre ou les rubriques d’une photo

Modifie son bloc dans `settings/photos.yml` :

```yaml
- title: The Seine
  albums: [cities, sunsets]
  image: /images/photos/2026-06-13-the-seine.jpg
  alt: Evening light on the Seine
  location: Paris, France
  date: '2026-06-13'
```

L’ordre des blocs, du haut vers le bas, donne l’ordre des photos dans chaque
rubrique. Les blocs actuels sont classés du plus récent au plus ancien ; tu peux
les déplacer pour modifier cet ordre. Change la liste `albums` pour ajouter ou
retirer une association. `albums: [cities]` convient aussi pour une seule
rubrique. Une photo commune à plusieurs rubriques reste décrite par un seul
bloc, avec un seul chemin `image`.

Enlève le bloc pour retirer la photo de toute la galerie. Si elle servait de
couverture, choisis aussi une autre valeur `cover` dans les rubriques concernées.

`thumbnail` est un chemin facultatif vers une version plus petite de la même
photo ; `image` reste l’image principale. `width` et `height`, lorsqu’ils sont
renseignés, doivent correspondre aux dimensions de l’image principale. Ces
champs ne sont pas obligatoires.

Si le recadrage carré coupe le sujet, ajoute `thumbnail_position: 50% 20%` au
bloc de la photo : le premier pourcentage règle la position horizontale, le
second la position verticale (50% au centre, 0% en haut, 100% en bas). Cela
modifie uniquement la vignette, jamais l’image complète.

Les anciennes entrées avec `album: cities` restent prises en charge ; utilise
la liste `albums` pour les nouveaux blocs. Les chemins des images peuvent
conserver les noms des anciens voyages, comme `/images/photos/new-york-2024/`,
ou l’ancien dossier `/images/mountains/`. Ces noms ne déterminent pas leur
classement : les associations dans `settings/photos.yml` rattachent une photo
aux rubriques, sans déplacer ni recopier les fichiers.

Prévisualise le résultat avec `./site preview` avant de lancer `./site check`
et d’enregistrer les changements dans Git.

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
