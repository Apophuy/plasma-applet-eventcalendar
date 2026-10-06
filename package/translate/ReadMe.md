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
| Template |     260 |       |
| da       | 176/260 |   67% |
| de       | 206/260 |   79% |
| el       | 163/260 |   62% |
| es       | 209/260 |   80% |
| fi       | 206/260 |   79% |
| fr       | 177/260 |   68% |
| he       | 207/260 |   79% |
| it       | 206/260 |   79% |
| ja       | 174/260 |   66% |
| ko       | 206/260 |   79% |
| nl       | 210/260 |   80% |
| pl       | 154/260 |   59% |
| pt_BR    | 206/260 |   79% |
| pt_PT    | 205/260 |   78% |
| ru       | 260/260 |  100% |
| sl       | 184/260 |   70% |
| sv       | 172/260 |   66% |
| tr       | 175/260 |   67% |
| uk       | 154/260 |   59% |
| zh_CN    | 159/260 |   61% |
