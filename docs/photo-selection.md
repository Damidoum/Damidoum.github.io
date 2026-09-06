# Inventaire des photos

Galerie mise à jour le 6 septembre 2026 : **58 photos uniques dans trois
rubriques thématiques**. Dix photos appartiennent à deux rubriques ; leurs
fichiers ne sont pas dupliqués. Ce document n’est pas publié.

| Rubrique | Photos | Couverture |
| --- | ---: | --- |
| Cities | 29 | IMG_4775 |
| Mountains | 25 | IMG_9947 |
| Sunsets | 14 | IMG_7432 |

Chaque photo conserve son lieu et sa date de prise de vue. Le filtre **Place**
permet de retrouver les images d’un lieu dans une rubrique. Le classement
initial va du plus récent au plus ancien ; l’ordre reste modifiable en déplaçant
les blocs dans `settings/photos.yml`.

Les associations sont des listes, par exemple `albums: [cities, sunsets]`, même
lorsqu’une photo n’a qu’une rubrique (`albums: [mountains]`). Les chemins des
exports peuvent encore contenir les noms des anciens voyages : ils servent au
stockage et ne déterminent pas le classement.

## Sources et archives locales

Les **63 sources importées** sont conservées sans modification dans
`local/photo-originals-used-2026-09-06/`, hors de Git et du site. `PHOTO/`, le
dossier d’attente des nouvelles images, est vide après rangement.

À la demande de Damien, **Overlapping slopes** (`IMG_9298`), **Sunlight between
buildings** (`IMG_4762`), **Alpine lake** (`IMG_9146`), **Lower Manhattan at night**
(`IMG_4565`) et **Yellow taxi** (`IMG_4694`) ont été retirées de la galerie.
Leurs dix fichiers Web — une image et une vignette pour chacune — sont conservés dans
`local/removed-photo-assets-2026-09-06/`. Leurs sources restent dans l’archive
des originaux.

Les nouvelles vues de New York (`IMG_4404`, `IMG_4420`, `IMG_4489` et `IMG_4564`)
sont dans Cities. `IMG_4489`, Manhattan dans la lumière du soir, figure aussi
dans Sunsets. Les dates de prise de vue viennent des métadonnées des fichiers.

**Jagged peaks** (`IMG_9423`) est conservée sous le titre **Aiguilles d’Arves**,
avec le lieu **Aiguilles d’Arves, France**.

Les anciens fichiers d’albums sont conservés dans
`local/photo-themes-2026-09-06/previous-albums/`. Leurs adresses publiques
redirigent vers Cities, Mountains ou Sunsets selon leur contenu ; l’ancien
album mixte France & England redirige vers la page Photos.

## Modifier la galerie

- **Titre ou couverture d’une rubrique** : son fichier dans `content/_albums/`,
  avec `cover` et `cover_alt` pour la couverture.
- **Lieu, date, légende ou ordre d’une photo** : son bloc dans `settings/photos.yml`.
- **Classement dans une ou plusieurs rubriques** : sa liste `albums`, sans copier
  l’image.
- **Ajouter une photo** : exporter une copie pour le Web, puis utiliser
  `./site photo ... --location ... --date ... --album cities --album sunsets`
  comme décrit dans [le guide](writing.md).
- **Ranger PHOTO** : une fois l’export vérifié dans l’aperçu, ranger sa source
  hors de `PHOTO/` pour n’y laisser que les images à examiner.

Les exports actuels sont des JPEG progressifs de 2400 pixels maximum sur le
grand côté, avec des aperçus de 1000 pixels maximum. Ils gardent les proportions
et le profil couleur des originaux. Les métadonnées EXIF, dont les coordonnées
GPS, ne sont pas copiées. Les couvertures et les vignettes carrées sont recadrées
uniquement à l’affichage ; un clic ouvre l’image entière.
