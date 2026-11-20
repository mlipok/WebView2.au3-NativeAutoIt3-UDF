# Offline spreadsheet editor

Run [056_ReactSpreadsheet.au3](../../../056_ReactSpreadsheet.au3) with AutoIt and the matching WebView2 loader. This example uses the installed WebView2 Runtime and its own temporary profile. The page and all scripts are served from the local virtual host mapping. Opening, editing and saving a workbook require no internet connection or local web server.

## Set up the offline dependencies

Create the folder **examples/assets/native/056-spreadsheet/vendor/** next to index.html. Download and extract these three official packages, then copy the indicated scripts into vendor/. Keep their filenames unchanged.

| Package | License | Path inside the archive | Destination under vendor/ |
| --- | --- | --- | --- |
| [React 18.3.1](https://registry.npmjs.org/react/-/react-18.3.1.tgz) | [MIT](https://github.com/react/react/blob/v18.3.1/LICENSE) | package/umd/react.production.min.js | react.production.min.js |
| [ReactDOM 18.3.1](https://registry.npmjs.org/react-dom/-/react-dom-18.3.1.tgz) | [MIT](https://github.com/react/react/tree/v18.3.1/packages/react-dom) | package/umd/react-dom.production.min.js | react-dom.production.min.js |
| [SheetJS CE 0.20.3](https://cdn.sheetjs.com/xlsx-0.20.3/xlsx-0.20.3.tgz) | [Apache 2.0](https://docs.sheetjs.com/docs/miscellany/license/) | package/dist/xlsx.full.min.js | xlsx.full.min.js |

Keep each package's LICENSE file with the locally installed scripts. Use distinct names such as react-LICENSE.txt, react-dom-LICENSE.txt and xlsx-LICENSE.txt. The ReactDOM browser build also contains a [Modernizr](https://github.com/Modernizr/Modernizr) fragment under the [MIT license](https://modernizr.com/license/).

[SheetJS Community Edition](https://git.sheetjs.com/sheetjs/sheetjs) can be used privately and commercially, including in closed-source applications. If you redistribute it, include the license and attribution, retain applicable copyright and NOTICE material, and mark modifications. See the [Apache 2.0 license text](https://www.apache.org/licenses/LICENSE-2.0).

After this one-time setup, run 056_ReactSpreadsheet.au3 with AutoIt. The example reads the scripts locally and works offline. Keep the whole vendor/ folder out of version control. The example source, index.html, app.js, app.css and this guide belong in version control.

## Use the editor

1. Click **Open workbook…** and pick an unencrypted .xls or .xlsx file.
2. Select a worksheet from **Sheet**. For larger sheets, use the row and column paging controls.
3. Select a cell. Set **Type** to Text, Number or Boolean and edit the value. Click **Apply edit** or press Enter from the value field to commit it. **Clear cell** removes the selected cell's value. For text identifiers with leading zeros, keep **Text** selected.
4. Click **Save copy…** and choose a new file in the AutoIt-owned Windows dialog. The default filename adds -copy before the extension. The output format matches the input extension. Existing files are rejected, including the original. Reopen the saved copy to inspect the changes.

Formula cells are read-only and their values are not recalculated in the editor. An .xls copy uses BIFF8 and replaces formulas with stored values. The editor asks for confirmation when formulas are detected in an .xls workbook. SheetJS CE reserializes the workbook and may omit advanced formatting, charts, macros and other Excel features. The editor shows cell values in a simple grid.
