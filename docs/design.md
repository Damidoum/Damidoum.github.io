# Modifier la présentation

Le design est indépendant des textes :

- `design/site.css` : variables de couleur, polices et espacements en tête de
  fichier, puis styles des composants et adaptations aux petits écrans.
- `design/site.js` : ouverture du menu sur mobile et filtre des photos par lieu.
- `design/layouts/base.html` : cadre commun, navigation, métadonnées et pied de page.
- `design/layouts/home.html` : accueil, qui lit `settings/profile.yml`.
- `design/layouts/single.html` : articles et publications.
- Les autres layouts composent les pages de listes et la galerie.
- `design/includes/site/` : vignettes, lignes de publications et mention de brouillon.

Les pages fixes sont des fichiers Markdown dans `content/pages/`. Leur en-tête
choisit un layout et une adresse. Les listes se mettent à jour automatiquement
à partir des collections ; le texte de Research et du CV reste dans leurs pages.
Le nom technique du site et ses métadonnées RSS sont dans `_config.yml` ; les
informations personnelles affichées sont regroupées dans `settings/profile.yml`.

`_config.yml` relie ces dossiers grâce aux options standard de Jekyll. Il conserve
la compatibilité GitHub Pages sans plugin personnalisé. `Gemfile.lock` enregistre
les versions actuelles des dépendances. Il n’y a plus de commande npm ni de
compilation du thème Academic Pages.

Après un changement : `./site check`, puis `./site preview` pour examiner le rendu.
Les contrôles n’évaluent pas visuellement la mise en page.

Les tests des commandes d’écriture se lancent avec
`ruby tools/tests/site_cli_test.rb` (Minitest nécessaire), ceux du vérificateur avec
`ruby tools/tests/check_site_test.rb`. Ils travaillent dans des dossiers temporaires.
Le rendu Markdown des formules est vérifié avec
`bundle exec ruby tools/tests/math_render_test.rb`.
Les albums photo et les images présentes dans plusieurs rubriques sont vérifiés
avec `bundle exec ruby tools/tests/photo_gallery_test.rb`.
