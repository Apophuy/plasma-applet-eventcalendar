> Plasma 6 translation workflow for Event Calendar.

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
| Template |     252 |       |
| da       | 176/252 |   69% |
| de       | 206/252 |   81% |
| el       | 163/252 |   64% |
| es       | 209/252 |   82% |
| fi       | 206/252 |   81% |
| fr       | 177/252 |   70% |
| he       | 207/252 |   82% |
| it       | 206/252 |   81% |
| ja       | 174/252 |   69% |
| ko       | 206/252 |   81% |
| nl       | 210/252 |   83% |
| pl       | 153/252 |   60% |
| pt_BR    | 206/252 |   81% |
| pt_PT    | 205/252 |   81% |
| ru       | 252/252 |  100% |
| sl       | 184/252 |   73% |
| sv       | 170/252 |   67% |
| tr       | 175/252 |   69% |
| uk       | 153/252 |   60% |
| zh_CN    | 158/252 |   62% |
