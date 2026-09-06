# Le site de Damien Rouchouse

**Pour écrire, commence ici.** Les textes du site sont en anglais ; ce guide et les
commandes sont en français. Jekyll construit toujours les pages, mais le dépôt ne
contient plus les composants et exemples inutilisés d’Academic Pages.

## Écrire un billet

Dans le dossier du site :

```sh
./site new "Conditional expectation"
./site preview
```

La première commande crée `content/_drafts/conditional-expectation.md` et son
dossier d’images. Ouvre ce fichier, renseigne la courte description et écris en
Markdown. L’aperçu est accessible sur [localhost:4000](http://127.0.0.1:4000).
Les modifications apparaissent après enregistrement ; les brouillons portent une
mention « Draft ».

Quand le texte est prêt :

```sh
./site publish conditional-expectation
./site check
```

`publish` déplace le billet dans `content/_posts/` avec la date du jour.
**Cela prépare les fichiers localement.** La mise en ligne passe ensuite par Git
et la branche configurée pour GitHub Pages ; aucune commande `./site` n’envoie de
modification sur GitHub.

## Où modifier quoi ?

| Besoin | Emplacement |
| --- | --- |
| Brouillons du blog | `content/_drafts/` |
| Billets publiables | `content/_posts/` |
| Articles sur les projets | `content/_projects/` |
| Publications scientifiques | `content/_publications/` |
| Texte de recherche, CV, pages fixes | `content/pages/` |
| Présentation, portrait, email et liens | [settings/profile.yml](settings/profile.yml) |
| Menu | [settings/navigation.yml](settings/navigation.yml) |
| Rubriques photo : titre et couverture | `content/_albums/` |
| Photos : rubriques, lieux, dates, légendes et ordre | [settings/photos.yml](settings/photos.yml) |
| Photos exportées pour le site | `images/photos/` |
| Photos en attente ou non retenues, hors de Git et du site | `PHOTO/` |
| Images et vidéos des articles | `images/` |
| PDF du CV et bibliographie | `files/` |
| Couleurs, police et espacements | [design/site.css](design/site.css) |
| Composition des pages | `design/layouts/` et `design/includes/` |

## Les autres commandes

```sh
./site new "A research project" --type project
./site new "A paper title" --type publication
./site --help
```

Les nouveaux projets et publications démarrent aussi en brouillon. Utilise
`./site publish leur-slug` pour les rendre publiables.

## Ajouter une photo

La galerie comporte trois rubriques : **Cities**, **Mountains** et **Sunsets**.
Chaque photo garde son lieu et sa date de prise de vue. Le filtre **Place**
permet de retrouver les images d’un lieu dans une rubrique.

```sh
./site photo "/chemin/ma-photo.jpg" --title "The Seine" --alt "Evening light on the Seine" --location "Paris, France" --date 2026-06-12 --album cities --album sunsets
./site preview
```

La commande copie l’image une seule fois dans `images/photos/` et l’ajoute à
`settings/photos.yml` avec `albums: [cities, sunsets]`. Elle apparaît dans les
deux rubriques ; pour une seule rubrique, utilise simplement `--album mountains`,
par exemple. Les rubriques doivent déjà exister.

Modifie les légendes, lieux, dates et associations dans `settings/photos.yml`.
L’ordre des blocs donne l’ordre d’affichage ; les photos actuelles sont classées
du plus récent au plus ancien. Les titres et couvertures des rubriques se
modifient dans `content/_albums/`, avec les champs `cover` et `cover_alt`.

Utilise `PHOTO/` pour les nouvelles photos à trier et celles qui ne sont pas
utilisées sur le site. Ce dossier reste local, hors de Git et du site ; ce n’est
pas une archive permanente. Les exports sélectionnés vont dans `images/photos/`.
Après vérification de l’export dans l’aperçu, range sa source déjà utilisée en
dehors de `PHOTO/`. Le dossier prévu pour cette sélection est
`local/photo-originals-used-2026-09-06/`, également hors de Git et du site.
Les exports retirés du site sont conservés dans
`local/removed-photo-assets-2026-09-06/`. La commande `photo` copie les fichiers
sans les redimensionner et ne fait pas ce rangement automatiquement.

Le [guide de rédaction](docs/writing.md) explique les vignettes, les formules,
les vidéos, les dates et la galerie. Le [guide du design](docs/design.md)
explique les quelques fichiers techniques.

## Installation et vérification

Ruby et Bundler sont nécessaires. À la première installation :

```sh
bundle install
```

`./site preview` lance l’aperçu avec les brouillons ; `Ctrl+C` l’arrête.
L’aperçu utilise `local/preview/`, séparé du site public généré.
`./site build` génère la version publique dans `_site/`, sans les brouillons.
`./site check` construit cette version et contrôle les liens locaux, les adresses
historiques et l’absence de fichiers de travail dans le site généré.

Les modèles utilisés par `new` sont dans `tools/templates/` : tu peux modifier
leur structure une fois pour tes prochains billets. Les fichiers dans `_site/`
sont générés et ne doivent pas être édités.

L’historique Git conserve l’ancien template. Sa licence d’origine reste dans
[LICENSE](LICENSE).
