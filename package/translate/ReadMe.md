> Plasma 6 translation workflow for Apophuy Calendar.

Translations are compiled into `contents/locale` and bundled with the Plasma 6 package.

## Install Translations

From a source checkout, run `sh package/translate/build`, then reinstall with `sh ./install`.

## New Translations

1. Fill out [`template.pot`](template.pot) with your translations then open a [new issue](https://github.com/Apophuy/plasma-applet-eventcalendar/issues/new), name the file `spanish.txt`, attach the txt file to the issue (drag and drop).

Or if you know how to make a pull request

1. Copy the `template.pot` file and name it your locale's code (Eg: `en`/`de`/`fr`) with the extension `.po`. Then fill out all the `msgstr ""`.

## Scripts

* `sh ./merge` will parse the `i18n()` calls in the `*.qml` files and write it to the `template.pot` file. Then it will merge any changes into the `*.po` language files.
* `sh ./build` will convert the `*.po` files to it's binary `*.mo` version and move it to `contents/locale/...` which will bundle the translations in the `*.plasmoid` without needing the user to manually install them.
* `sh ./plasmoidlocaletest <locale>` builds translations and starts the source package with `plasmawindowed`.

## Links

* https://zren.github.io/kde/docs/widget/#translations-i18n
* https://techbase.kde.org/Development/Tutorials/Localization/i18n_Build_Systems
* https://api.kde.org/frameworks/ki18n/html/prg_guide.html

## Examples

* https://l10n.kde.org/stats/gui/trunk-kf5/team/fr/plasma-desktop/
* https://github.com/psifidotos/nowdock-plasmoid/tree/master/po
* https://github.com/kotelnik/plasma-applet-redshift-control/tree/master/translations

## Status
|  Locale  |  Lines  | % Done|
|----------|---------|-------|
| Template |     289 |       |
| da       | 176/289 |   60% |
| de       | 205/289 |   70% |
| el       | 163/289 |   56% |
| es       | 208/289 |   71% |
| fi       | 205/289 |   70% |
| fr       | 177/289 |   61% |
| he       | 206/289 |   71% |
| it       | 205/289 |   70% |
| ja       | 174/289 |   60% |
| ko       | 205/289 |   70% |
| nl       | 209/289 |   72% |
| pl       | 154/289 |   53% |
| pt_BR    | 205/289 |   70% |
| pt_PT    | 204/289 |   70% |
| ru       | 289/289 |  100% |
| sl       | 183/289 |   63% |
| sv       | 171/289 |   59% |
| tr       | 175/289 |   60% |
| uk       | 154/289 |   53% |
| zh_CN    | 159/289 |   55% |
