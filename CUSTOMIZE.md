# Personnaliser le site

Cette branche remplace l'interface Academic Pages par une mise en page personnelle.
Jekyll reste le générateur : les textes restent en Markdown et l'hébergement GitHub
Pages peut conserver son fonctionnement actuel. Aucun framework JavaScript, aucune
étape npm et aucun nouveau plugin Jekyll ne sont nécessaires.

## Voir le site localement

```sh
bundle install
bundle exec jekyll serve --host 127.0.0.1 --port 4000
```

Ouvrir <http://127.0.0.1:4000>. Les fichiers sont surveillés automatiquement.
Après une modification de `_config.yml`, relancer le serveur.

Pour vérifier la version destinée à GitHub Pages :

```sh
bundle exec jekyll build --safe
```

La branche est une proposition locale. Aucun changement du site public n'est
nécessaire pour la consulter. Son déploiement suivra la configuration GitHub Pages
du dépôt, après intégration de la branche.

## Les quelques fichiers utiles

| Changer… | Fichier |
| --- | --- |
| Présentation courte, portrait, actualité | `_data/profile.yml` |
| Nom, email, liens académiques | `_config.yml` |
| Navigation | `_data/navigation.yml` |
| Couleurs, typographie, espacements | Variables au début de `assets/css/site.css` |
| Composition de l'accueil | `_layouts/home.html` |
| Cadre commun, navigation et pied de page | `_layouts/site.html` |
| Recherche et parcours | `_pages/research.html`, `_pages/cv.md` |
| CV téléchargeable | `files/cv.pdf` |
| Photographies et légendes | `_data/photos.yml` |

Les anciens fichiers de thème restent dans le dépôt pour référence. Les pages
actives n'utilisent plus ses styles, sa barre latérale, jQuery ou ses composants.
Les exemples de publications, enseignements et conférences du template sont
exclus de la publication. Les URL des contenus personnels existants sont conservées.

## Publier un billet de maths

1. Copier `_drafts/a-first-mathematical-note.md` dans `_posts/`.
2. Nommer le fichier, par exemple `2026-10-12-mon-sujet.md`.
3. Remplacer les métadonnées et le texte d'exemple.

```yaml
---
title: "The title of the note"
description: "A short sentence shown on the card and in search results."
topic: Probability
cover: /images/posts/my-note/cover.jpg
# Sans image, ces champs produisent une vignette typographique :
formula: "P(A | B)"
cover_label: Conditional probability
---
```

Le billet apparaît automatiquement dans le carnet, parmi les deux derniers textes sur
l'accueil, et dans le flux RSS. Son URL est `/blog/AAAA/MM/JJ/mon-sujet/`.
La date du nom de fichier fait foi ; les billets futurs restent cachés jusqu'à
une compilation après cette date. Il n'y a pas de publication programmée automatique.

Les deux projets existants sont aussi présentés dans le carnet sous « Project
notes », à leur URL d'origine. Le RSS contient les billets de `_posts/` uniquement.
Le carnet affiche uniquement les textes disponibles, sans vignette d’attente.

Utiliser `$...$` pour les formules dans le texte et `$$...$$` sur des lignes séparées
pour les équations centrées. MathJax est chargé uniquement sur les articles,
projets et publications ; il nécessite une connexion au CDN jsDelivr. Les
polices, styles, scripts du site et images d'illustration sont servis localement.

Une image `cover` doit idéalement avoir un format paysage (environ 1600 × 1000).
Le champ `formula` est du texte Unicode, pas du LaTeX : il évite de charger MathJax
sur toutes les vignettes. Le LaTeX du corps de l'article est rendu normalement.

Pour travailler sans publier, garder le fichier dans `_drafts/` et utiliser
`bundle exec jekyll serve --drafts`. Vérifier les références et les résultats
mathématiques avant publication.

## Ajouter des photos de montagne

Mettre les fichiers dans `images/mountains/`, puis remplacer `[]` dans
`_data/photos.yml` par la liste suivante, adaptée à tes photographies :

```yaml
- image: /images/mountains/my-photo.jpg
  title: "A morning on the ridge"
  location: "Massif, country"
  date: 2026-10-12
  alt: "Describe what is visible in the photograph."
  width: 1600
  height: 1067
```

Répéter ce bloc pour chaque photo, dans l'ordre souhaité. Donner les dimensions
réelles évite les déplacements de mise en page pendant le chargement. Les photos
s'ouvrent en grand au clic. Une largeur de 1600–2400 pixels et des JPEG compressés
conviennent généralement. Ajouter des textes alternatifs descriptifs.

Dès la première photo ajoutée, l'illustration de la galerie disparaît.
Les photographies sont regroupées sur la page Mountains.

L'image actuelle est une **illustration**, pas une photographie de Damien :
[Niklas Liniger, Unsplash](https://unsplash.com/photos/glacier-mountains-during-day-BZpt3Qn09WQ),
sous [licence Unsplash](https://unsplash.com/license). Elle est conservée localement
dans `assets/images/alpine-placeholder.jpg` avec son crédit visible.

## Ajouter une publication ou un projet

- Publications : ajouter un fichier dans `_publications/`, avec `title`, `date`,
  `authors`, `venue`, `paperurl` et, si disponible, `bibtexurl` et `projecturl`.
  `category` accepte notamment `preprints`, `conferences` et `manuscripts`.
- Projets : ajouter un fichier Markdown dans `_projects/`, avec `title`, `date`,
  `description` et éventuellement `cover`, `formula`, `cover_label` et `permalink`.
- Pour préserver un lien existant, conserver le champ `permalink` du fichier.

## Contenu à actualiser avant mise en ligne

Le début du doctorat en octobre 2026 reprend l'information donnée pour cette
proposition. L'affiliation, l'encadrement doctoral et le sujet exact restent à
ajouter lorsqu'ils sont connus. Le PDF du CV existant a été conservé tel quel.
La présente refonte ne constitue pas une vérification scientifique des textes
de recherche déjà présents.
