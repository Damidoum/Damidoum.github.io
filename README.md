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
| Photos de montagne et légendes | [settings/photos.yml](settings/photos.yml) |
| Images et vidéos des articles | `images/` |
| PDF du CV et bibliographie | `files/` |
| Couleurs, police et espacements | [design/site.css](design/site.css) |
| Composition des pages | `design/layouts/` et `design/includes/` |

## Les autres commandes

```sh
./site new "A research project" --type project
./site new "A paper title" --type publication
./site photo "/chemin/ma-photo.jpg" --title "Mont Blanc" --location "Alps"
./site --help
```

Les nouveaux projets et publications démarrent aussi en brouillon. Utilise
`./site publish leur-slug` pour les rendre publiables.

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
